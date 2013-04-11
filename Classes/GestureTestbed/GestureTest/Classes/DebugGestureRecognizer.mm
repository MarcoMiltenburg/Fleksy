//
//  DebugGestureRecognizer.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 10/29/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "DebugGestureRecognizer.h"
#import "CircleUIView.h"
#import "UITouchManager.h"
#import "MathFunctions.h"
#import "SynthesizeSingleton.h"
#import "TouchAnalyzer.h"

#define TAG_POINT 1

static TouchAnalyzer* touchAnalyzer = [TouchAnalyzer sharedTouchAnalyzer];

@implementation DebugGestureRecognizer

SYNTHESIZE_SINGLETON_FOR_CLASS(DebugGestureRecognizer)

- (void) nop:(id) obj {
  
}

- (id)initWithTarget:(id)_target action:(SEL)action {
  if (self = [super initWithTarget:self action:@selector(nop)]) {
    points = [[NSMutableDictionary alloc] init];
    [UITouchManager initializeTouchManager];
    self.clearBeforeNextTouch = NO;
    self.delaysTouchesEnded = NO;
    
    storedOKSwipes = [[NSMutableArray alloc] init];
    storedErrorSwipes = [[NSMutableArray alloc] init];
    [self clear:target];
    
    self->target = _target;
    
    oddTouches = [[NSMutableArray alloc] init];
    evenTouches = [[NSMutableArray alloc] init];
  }
  return self;
}

- (void) storeLastSwipe:(NSMutableArray*) array {
  if (!lastTouch) {
    NSLog(@"!lastTouch");
    return;
  }
  [array addObject:lastTouch];
  //lastTouch = nil;
  [self clear:target];
}

- (void) storeLastSwipeOK {
  //NSLog(@"lastSwipeOK");
  [self storeLastSwipe:storedOKSwipes];
}


- (void) storeLastSwipeError {
  //NSLog(@"lastSwipeError");
  [self storeLastSwipe:storedErrorSwipes];
}


- (void) print {
  NSLog(@"okSwipes: %d, errorSwipes: %d", storedOKSwipes.count, storedErrorSwipes.count);
  NSMutableString* string = [[NSMutableString alloc] init];
  for (UITouch* touch in storedOKSwipes) {
    [string appendString:[FLTouch stringForTouch:touch kind:UITouchKindSwipe]];
  }
  for (UITouch* touch in storedErrorSwipes) {
    [string appendString:[FLTouch stringForTouch:touch kind:UITouchKindPhantomSwipeI]];
  }
  NSLog(@"result:\n%@\n", string);
}

- (void) addViewForTouchPoint:(CGPoint) location phase:(UITouchPhase) phase view:(UIView*) view odd:(BOOL) odd {
 
  assert(view);
  
  CircleUIView* point = [[CircleUIView alloc] init];
  switch (phase) {
    case UITouchPhaseBegan:
      //[points setObject:point forKey:key];
      point.radius = 3;
      point.backgroundColor = [UIColor greenColor];
      point.alpha = 0.5;
      break;
      
    case UITouchPhaseMoved:
      point.radius = 1; //startPoint.radius;
      point.backgroundColor = odd ? [UIColor blueColor] : [UIColor whiteColor];
      point.alpha = 0.5;
      break;
      
    case UITouchPhaseEnded:
      point.radius = 3;
      point.backgroundColor = [UIColor redColor];
      point.alpha = 0.5;
      //[points removeObjectForKey:key];
      break;
      
    case UITouchPhaseCancelled:
      point.radius = 3;
      point.backgroundColor = [UIColor grayColor];
      point.alpha = 0.5;
      //[points removeObjectForKey:key];
      break;
      
    case UITouchPhaseStationary:
      point.radius = 1;
      point.backgroundColor = [UIColor yellowColor];
      point.alpha = 0.5;
      break;
      
    default:
      [NSException raise:@"addViewForTouchPoint" format:@"phase? %d", phase];
      break;
  }
  
  CGPoint shift = CGPointZero;
  point.center = addPoints(location, shift);
  point.tag = TAG_POINT;
  point.userInteractionEnabled = NO;
  //NSLog(@"point: %@", NSStringFromCGPoint(point.center));
  [view addSubview:point];
}

- (void) addPointForTouch:(UITouch*) touch {
  
  if (touch.phase == UITouchPhaseBegan) {
    if (self.clearBeforeNextTouch) {
      [self clear:target];
      self.clearBeforeNextTouch = NO;
    }
    if (oddTouches.count < evenTouches.count) {
      [oddTouches addObject:touch];
    } else {
      [evenTouches addObject:touch];
    }
  }

  //NSValue* key = [NSValue valueWithPointer:(void*)touch];
  //CircleUIView* startPoint = [points objectForKey:key];
  [self addViewForTouchPoint:[touch locationInView:target] phase:touch.phase view:target odd:[oddTouches containsObject:touch]];
}

- (void) clear:(UIView*) drawingView {
  for (UIView* subview in drawingView.subviews) {
    if (subview.tag == TAG_POINT) {
      [subview removeFromSuperview];
    }
  }
  [points removeAllObjects];
  lastTouch = nil;
}

- (void) clear {
  [self clear:target];
}

- (void) showTouch:(FLTouch*) touch inView:(UIView*) view {
  //NSLog(@"showTouch in view: %@", view);
  [self clear:view];
  for (PathPoint* point in touch.path) {
    [self addViewForTouchPoint:point.location phase:point.phase view:view odd:NO];
  }
  
  FLTouch* delta = [TouchAnalyzer deltas:touch addFirstRaw:NO];
  delta = [TouchAnalyzer deltas:delta addFirstRaw:YES];
  CGPoint shift = CGPointMake(200, 200);
  [self addViewForTouchPoint:shift phase:UITouchPhaseBegan view:view odd:NO];
  CGPoint totalVector = CGPointZero;
  for (PathPoint* point in delta.path) {
    totalVector = addPoints(point.location, totalVector);
    [self addViewForTouchPoint:addPoints(totalVector, shift) phase:point.phase view:view odd:NO];
  }
}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"DebugGestureRecognizer: touchesBegan %d", [touches count]);
  //double start = CFAbsoluteTimeGetCurrent();
  for (UITouch* touch in touches) {
    //NSLog(@"%p: began, %@, t: %.6f", touch, NSStringFromCGPoint([touch locationInView:touch.window]), touch.timestamp);
    [self addPointForTouch:touch];
  }
  
  //NSLog(@"began in %.6f", CFAbsoluteTimeGetCurrent() - start);
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"DebugGestureRecognizer: touchesMoved %d", [touches count]);
  //double start = CFAbsoluteTimeGetCurrent();
  
  for (UITouch* touch in touches) {
    //NSLog(@"%p: moved, %@, t: %.6f", touch, NSStringFromCGPoint([touch locationInView:touch.window]), touch.timestamp);
    [self addPointForTouch:touch];
    //NSLog(@"moved %p: %.6f", touch, touch.timestamp);
    //usleep(20 * 1000);
  }
  //NSLog(@"moved in %.6f", CFAbsoluteTimeGetCurrent() - start);
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"DebugGestureRecognizer: touchesEnded %d", [touches count]);
  //double start = CFAbsoluteTimeGetCurrent();
  for (UITouch* touch in touches) {
    //NSLog(@"%p: ended, %@, t: %.6f", touch, NSStringFromCGPoint([touch locationInView:touch.window]), touch.timestamp);
    [self addPointForTouch:touch];
    //FLTouch* myTouch = [[FLTouch alloc] initWithPath:touch.path kind:UITouchKindUnknown];
    //[touchAnalyzer checkSwipe:swipe print:YES];
    //[self showTouch:myTouch inView:touch.view ? touch.view : touch.window];
    lastTouch = touch;
  
    [oddTouches removeObject:touch];
    [evenTouches removeObject:touch];
  }
  
  
  //NSLog(@"ended in %.6f", CFAbsoluteTimeGetCurrent() - start);
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  NSLog(@"DebugGestureRecognizer: touchesCancelled %d", [touches count]);
  for (UITouch* touch in touches) {
    [self addPointForTouch:touch];
  }
}

@end
