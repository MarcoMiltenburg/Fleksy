//
//  FLTouchEventInterceptor.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 11/15/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FLTouchEventInterceptor.h"
#import "TouchSynthesis.h"
#import "UITouchManager.h"
#import "MathFunctions.h"
#import "SynthesizeSingleton.h"
#import "VariousUtilities.h"
#import "Settings.h"

#define MINIMUM_CONCURRENT_TAP_DISTANCE 55


@implementation FLTouchEventInterceptor

SYNTHESIZE_SINGLETON_FOR_CLASS(FLTouchEventInterceptor)

+ (CGPoint) furthestPointFrom:(CGPoint) point inTouch:(UITouch*) touch {
  double maxDistance = -1;
  CGPoint result = CGPointZero;
  for (PathPoint* pathPoint in touch.path) {
    float distance = distanceOfPoints(pathPoint.location, point);
    if (distance > maxDistance) {
      maxDistance = distance;
      result = pathPoint.location;
    }
  }
  assert(maxDistance >= 0);
  return result;
}

- (void) updateSynthesizedTouch:(UITouch*) touch timestamp:(NSTimeInterval) timestamp location:(CGPoint) location phase:(UITouchPhase) phase {
  [touch setTimestamp:timestamp];
  //int noise = 15;
  //location = addPoints(location, CGPointMake((rand() % noise)-noise/2, (rand() % noise)-noise/2));
  location = addPoints(location, self.shiftValue);
  [touch _setLocationInWindow:location resetPrevious:phase == UITouchPhaseBegan];
  [touch setPhase:phase];
  [self forwardToListeners:[NSSet setWithObject:touch] withEvent:nil phase:touch.phase];
}

- (void) updateSynthesizedTouch:(UITouch*) touch fromOriginalTouch:(UITouch*) originalTouch copySteps:(int) steps {
  for (int i = 0; i < fmin(steps, originalTouch.path.count); i++) {
    PathPoint* pathPoint = [originalTouch.path objectAtIndex:i];
    if (i == 0) {
      assert(CGPointEqualToPoint(pathPoint.location, [originalTouch initialLocationInView:originalTouch.window]));
    }
    [self updateSynthesizedTouch:touch timestamp:pathPoint.timestamp location:pathPoint.location phase:pathPoint.phase];
  }
}

- (UITouch*) synthesizeTouchFromTouch:(UITouch*) originalTouch copySteps:(int) steps {
  //assert(originalTouch.phase == UITouchPhaseBegan);
  UITouch* touch = [[UITouch alloc] initFromTouch:originalTouch];
  [self updateSynthesizedTouch:touch fromOriginalTouch:originalTouch copySteps:steps];  
  return touch;
}

- (id) init {
  if (self = [super init]) {
    self->forwardListeners = [[NSMutableArray alloc] init];
    self->touchAnalyzer = [TouchAnalyzer sharedTouchAnalyzer];
    //newTouchesDictionary = [[NSMutableDictionary alloc] init];
    startedTouches = [[NSMutableDictionary alloc] init];
    endedTouches = [[NSMutableDictionary alloc] init];
    
    self.forwardRawValues = 0;
    self.shiftValue = CGPointZero;
    self.splitSwipesInPoints = 0;
  
    FLEKSY_APP_SETTING_SPEAK = YES;
    FLEKSY_APP_SETTING_SPEAKING_RATE = 1.4;
  }
  return self;
}

- (void) addListener:(id)listener {
  [forwardListeners addObject:listener];
}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"FLTouchEventInterceptor touchesBegan: %d", touches.count);
  if (self.forwardRawValues) {
    [self forwardToListeners:touches withEvent:event phase:[[touches anyObject] phase]];
  }
  
  // we need to create the synthesized touches here, if we wait till touchesEnd .window (+others?) might not be available anymore
  for (UITouch* originalTouch in touches) {
    NSValue* key = [NSValue valueWithPointer:(const void*) originalTouch];
    UITouch* synthesizedTouch = [self synthesizeTouchFromTouch:originalTouch copySteps:0];
    [startedTouches setObject:synthesizedTouch forKey:key];
  }
  //UIEvent* newEvent = [[UIEvent alloc] initWithTouches:newTouches];
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"FLTouchEventInterceptor touchesMoved: %d", touches.count);
  if (self.forwardRawValues) {
    [self forwardToListeners:touches withEvent:event phase:[[touches anyObject] phase]];
  }
}

// if point is closer to anchor than threshold, this will return point shifted on the line
// formed so that it is exactly threshold units apart. Otherwise returns point unchanged
- (CGPoint) ensurePoint:(CGPoint)point isFarFrom:(CGPoint)anchor threshold:(float)threshold {
  CGPoint delta = subtractPoints(point, anchor);
  float mag = magnitude(delta);
  if (mag > threshold) {
    return point;
  }
  delta = multiplyPoint(delta, threshold / mag);
  delta = addPoints(delta, anchor);
  return delta;
}

- (void) forwardEquallySpacedIdealSwipe:(FLTouch*) myTouch fromOriginalSwipe:(UITouch*) originalTouch synthesizedTouch:(UITouch*) synthesizedTouch {
  // forward an ideal swipe where all points are equally spaced out. Mostly for debugging
  
  CGPoint deltaPoint = subtractPoints(myTouch.endPoint, myTouch.startPoint);
  double dt = originalTouch.timestamp - originalTouch.initialTimestamp;
  
  int splits = myTouch.endpointDistance / self.splitSwipesInPoints;
  for (int i = 0; i < splits; i++) {
    float f = (float) i / (float) (splits-1);
    CGPoint vector = multiplyPoint(deltaPoint, f);
    CGPoint location = addPoints(myTouch.startPoint, vector);
    double  time = originalTouch.initialTimestamp + f * dt;
    
    UITouchPhase phase = UITouchPhaseMoved;
    if (i == 0) {
      phase = UITouchPhaseBegan;
    } else if (i == splits-1) {
      phase = UITouchPhaseEnded;
    }
    [self updateSynthesizedTouch:synthesizedTouch timestamp:time location:location phase:phase];
  }
}

- (NSArray*) sortedTouches:(NSArray*) touches {
  return [touches sortedArrayUsingComparator:
   
   ^NSComparisonResult(NSValue* v1, NSValue* v2) {
     
     UITouch* t1 = (UITouch*) [v1 pointerValue];
     UITouch* t2 = (UITouch*) [v2 pointerValue];
     double time1 = t1.initialTimestamp;
     double time2 = t2.initialTimestamp;
     
     if (time2 > time1) {
       return NSOrderedAscending;
     }
     if (time2 < time1) {
       return NSOrderedDescending;
     }
     return NSOrderedSame;
   }];
}

- (NSArray*) getTapsFromTouches:(NSArray*) touches {
  NSMutableArray* result = [[NSMutableArray alloc] init];
  for (NSValue* key in touches) {
    UITouch* originalTouch = (UITouch*) [key pointerValue];
    FLTouch* myTouch = [[FLTouch alloc] initWithPath:originalTouch.path kind:UITouchKindUnknown];
    UITouchKind kind = [TouchAnalyzer getKindForTouch:myTouch print:NO];
    if (kind == UITouchKindTap) {
      [result addObject:myTouch];
    }
  }
  return result;
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"FLTouchEventInterceptor touchesEnded: %d", touches.count);
  if (self.forwardRawValues) {
    [self forwardToListeners:touches withEvent:event phase:[[touches anyObject] phase]];
  }
  
  for (UITouch* originalTouch in touches) {
    NSValue* key = [NSValue valueWithPointer:(const void*) originalTouch];
    UITouch* synthesizedTouch = [startedTouches objectForKey:key];
    [startedTouches removeObjectForKey:key];
    [endedTouches setObject:synthesizedTouch forKey:key];
  }
  
  
  if (startedTouches.count) {
    //NSLog(@"will wait for startedTouches.count to be 0");
    return;
  }
  

  NSArray* taps = [self getTapsFromTouches:[endedTouches allKeys]];
  
  
  NSArray* sortedTouches = [self sortedTouches:[endedTouches allKeys]];
  
  for (NSValue* key in sortedTouches) {
    
    UITouch* originalTouch = (UITouch*) [key pointerValue];
    UITouch* synthesizedTouch = [endedTouches objectForKey:key];
    
    NSLog(@"processing originalTouch %x, synthesizedTouch %x, startedTouches: %d, endedTouches: %d",
          originalTouch, synthesizedTouch, startedTouches.count, endedTouches.count);
  
    FLTouch* myTouch = [[FLTouch alloc] initWithPath:originalTouch.path kind:UITouchKindUnknown];
    UITouchKind kind = [TouchAnalyzer getKindForTouch:myTouch print:NO];
    
    if (kind == UITouchKindPhantomSwipeI) {
      NSLog(@"UITouchKindPhantomSwipeI detected!, travelDistance: %.3f", myTouch.travelDistance);
      assert(taps.count < 2);
      
      if (taps.count) {
        FLTouch* tap = [taps objectAtIndex:0];
        // TODO: confirm which one should be earlier, the swipe or the tap?
        [VariousUtilities performAudioFeedbackFromString:@"phantom swipe, hasTap"];
        CGPoint location = [FLTouchEventInterceptor furthestPointFrom:tap.startPoint inTouch:originalTouch];
        location = [self ensurePoint:location isFarFrom:tap.startPoint threshold:MINIMUM_CONCURRENT_TAP_DISTANCE];
        [self updateSynthesizedTouch:synthesizedTouch timestamp:originalTouch.initialTimestamp location:location phase:UITouchPhaseBegan];
        [self updateSynthesizedTouch:synthesizedTouch timestamp:originalTouch.timestamp location:location phase:UITouchPhaseEnded];
      
      } else {
        
        [VariousUtilities performAudioFeedbackFromString:@"phantom swipe, no tap"];
        UITouch* tempTouch1 = synthesizedTouch;
        UITouch* tempTouch2 = [self synthesizeTouchFromTouch:synthesizedTouch copySteps:0];
        
        CGPoint location1 = [originalTouch initialLocationInView:synthesizedTouch.window];
        CGPoint location2 = [FLTouchEventInterceptor furthestPointFrom:location1 inTouch:originalTouch];
        location2 = [self ensurePoint:location2 isFarFrom:location1 threshold:MINIMUM_CONCURRENT_TAP_DISTANCE];
        
        // TODO: confirm which one should be earlier
        NSTimeInterval timestamp1 = originalTouch.initialTimestamp;
        NSTimeInterval timestamp2 = originalTouch.initialTimestamp + 0.01;
        
        [self updateSynthesizedTouch:tempTouch1 timestamp:timestamp1 location:location1 phase:UITouchPhaseBegan];
        [self updateSynthesizedTouch:tempTouch2 timestamp:timestamp2 location:location2 phase:UITouchPhaseBegan];
        
        [self updateSynthesizedTouch:tempTouch1 timestamp:timestamp1+0.01 location:location1 phase:UITouchPhaseEnded];
        [self updateSynthesizedTouch:tempTouch2 timestamp:timestamp2+0.01 location:location2 phase:UITouchPhaseEnded];
      }
    } else if (kind == UITouchKindTap) {
      CGPoint location = myTouch.startPoint;
      [self updateSynthesizedTouch:synthesizedTouch timestamp:originalTouch.initialTimestamp location:location phase:UITouchPhaseBegan];
      [self updateSynthesizedTouch:synthesizedTouch timestamp:originalTouch.timestamp        location:location phase:UITouchPhaseEnded];
    
    } else if (kind == UITouchKindSwipe && self.splitSwipesInPoints > 0) {
      [self forwardEquallySpacedIdealSwipe:myTouch fromOriginalSwipe:originalTouch synthesizedTouch:synthesizedTouch];
      
    } else {
      // forward as-is
      [self updateSynthesizedTouch:synthesizedTouch fromOriginalTouch:originalTouch copySteps:originalTouch.path.count];
    }
    
  }
  
  [endedTouches removeAllObjects];
}


- (void) forwardToListeners:(NSSet*) touches withEvent:(UIEvent*) event phase:(UITouchPhase) phase {

  for (id listener in forwardListeners) {
    switch (phase) {
      case UITouchPhaseBegan:
        [listener performSelector:@selector(touchesBegan:withEvent:) withObject:touches withObject:event];
        break;
      case UITouchPhaseMoved:
        [listener performSelector:@selector(touchesMoved:withEvent:) withObject:touches withObject:event];
        break;
      case UITouchPhaseEnded:
        [listener performSelector:@selector(touchesEnded:withEvent:) withObject:touches withObject:event];
        break;
      case UITouchPhaseCancelled:
        [listener performSelector:@selector(touchesCancelled:withEvent:) withObject:touches withObject:event];
        break;
      default:
        [NSException raise:@"forwardToListeners" format:@"phase? %d", phase];
        break;
    }
  }
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  NSLog(@"FLTouchEventInterceptor touchesCancelled: %d", touches.count);
  [self touchesEnded:touches withEvent:event];
}

@end
