//
//  UICustomTapGestureRecognizer.m
//  EasyType
//
//  Created by Kostas Eleftheriou on 1/10/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "UICustomTapGestureRecognizer.h"
#import "MathsUtilities.h"

@implementation TouchData
@end

@implementation UICustomTapGestureRecognizer

- (id) initWithTarget:(id)target action:(SEL)action {
  if (self = [super initWithTarget:target action:action]) {
    trackedTouches = [[NSMutableDictionary alloc] init];
    pendingTouches = [[NSMutableArray alloc] init];
  }
  return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  NSLog(@"shouldRecognizeSimultaneouslyWithGestureRecognizer");
  return YES;
}


- (void) reset {
  NSLog(@"UICustomTapGestureRecognizer reset");
  [trackedTouches removeAllObjects];
  [pendingTouches removeAllObjects];
  [super reset];
}

//- (void) timerFired:(NSTimer*) timer {
//  UITouch* touch = (UITouch*) [timer userInfo];
//  NSLog(@" >>> timerFired %@", NSStringFromCGPoint([touch locationInView:self.view]));
//  if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
//    [timer invalidate];
//  }
//}

- (TouchData*) touchDataFromUITouch:(UITouch*) touch {
  TouchData* value = [[TouchData alloc] init];
  value->startLocation = [touch locationInView:self.view];
  //NSLog(@"adding with location: %@", NSStringFromCGPoint(value->startLocation));
  value->startTime = touch.timestamp;
  //value->timer = [NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(timerFired:) userInfo:touch repeats:YES];
  return value; //autorelease
}

- (void) addTrackedTouch:(UITouch*) touch {
  
  //NSLog(@"trackedTouches BEFORE add: %@", trackedTouches);
  
  TouchData* value = [self touchDataFromUITouch:touch];
  
  NSValue* key = [NSValue valueWithPointer:touch];
  //NSLog(@"adding key: %08X for %08X", [key pointerValue], touch);
  
  if ([trackedTouches objectForKey:key]) {
    TouchData* value2 = [trackedTouches objectForKey:key];
    NSLog(@"LOGIC ERROR: trackedTouch to add already added! existing start: %.6f, adding start: %.6f", value2->startTime, touch.timestamp);
  }  
  
  [trackedTouches setObject:value forKey:key];
  
  //NSLog(@"trackedTouches AFTER add: %@", trackedTouches);
  
  //[value release];
}

- (float) getDistanceOfTrackedTouch:(UITouch*) touch {
  NSValue* key = [NSValue valueWithPointer:touch];
  TouchData* value = [trackedTouches objectForKey:key];
  if (!value) {
    NSLog(@"getDistanceOfTrackedTouch %08X does not exist!", touch);
    return 9999;
  }
  CGPoint currentPoint = [touch locationInView:self.view];
  return distanceBetweenPoints(value->startLocation, currentPoint);
}

- (TouchData*) trackingTouch:(UITouch*) touch {
  NSValue* key = [NSValue valueWithPointer:touch];
  TouchData* result = [trackedTouches objectForKey:key];
  //NSLog(@"trackedTouches in trackingTouch: %@", trackedTouches);
  return result;
}

- (void) removeTrackedTouch:(UITouch*) touch {
  
  //NSLog(@"trackedTouches BEFORE removeTrackedTouch: %@", trackedTouches);
  
  NSValue* key = [NSValue valueWithPointer:touch];
  TouchData* touchData = [trackedTouches objectForKey:key];
  if (touchData) {

    //for some reason invalidating here doesnt work
//    NSLog(@"thread2: %@", [NSThread currentThread]);
//    [touchData->timer invalidate];
//    touchData->timer = nil;
//    
    [trackedTouches removeObjectForKey:key];
    //NSLog(@"Stopped tracking %08X", touch);
  } else {
    NSLog(@"LOGIC ERROR: trackedTouch to remove not found for %08X", touch);
  }
  
  //NSLog(@"trackedTouches AFTER removeTrackedTouch: %@", trackedTouches);
}



- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  
  for (NSValue* key in trackedTouches) {
    TouchData* touchData = [trackedTouches objectForKey:key];
    [pendingTouches addObject:touchData];
    self.state = UIGestureRecognizerStateChanged;
    [trackedTouches removeObjectForKey:key];
  }
  
  for (UITouch* touch in touches) {
    NSLog(@"touchesBegan UICustomTapGestureRecognizer! %08X %@", touch, NSStringFromCGPoint([touch locationInView:self.view]));
    [self addTrackedTouch:touch];
  }
}

#define DISTANCE_LIMIT 70

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesMoved:touches withEvent:event];
  for (UITouch* touch in touches) {
    
    if (![self trackingTouch:touch]) {
      //NSLog(@"touchesMoved UICustomTapGestureRecognizer! %08X, [IGNORING, not tracked anymore]", touch);
      continue;
    }
    
    CGPoint point0 = [touch previousLocationInView:self.view];
    CGPoint point1 = [touch locationInView:self.view];
    float stepDistance = distanceBetweenPoints(point0, point1);
    //NSLog(@"moved stepDistance: %.3f (%@ to %@) for %08X", stepDistance, NSStringFromCGPoint(point0), NSStringFromCGPoint(point1), touch);
    if (stepDistance > 70) {
      NSLog(@"this was possibly a new tap that we missed %08X", touch);
    }
    
    float distance = [self getDistanceOfTrackedTouch:touch];
    if (distance > DISTANCE_LIMIT) {
      
      NSLog(@"touchesMoved UICustomTapGestureRecognizer! %08X, [REMOVING, distance: %.3f (%@ to %@)]",
            touch, distance, NSStringFromCGPoint([self trackingTouch:touch]->startLocation), NSStringFromCGPoint(point1));
      
      [self removeTrackedTouch:touch];
    }
  }
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesEnded:touches withEvent:event];
  for (UITouch* touch in touches) {
    
    if (![self trackingTouch:touch]) {
      //NSLog(@"touchesEnded UICustomTapGestureRecognizer! %08X, [IGNORING, not tracked anymore]", touch);
      continue;
    }
    
    CGPoint point0 = [touch previousLocationInView:self.view];
    CGPoint point1 = [touch locationInView:self.view];
    float stepDistance = distanceBetweenPoints(point0, point1);
    NSLog(@"ended stepDistance: %.3f (%@ to %@) for %08X", stepDistance, NSStringFromCGPoint(point0), NSStringFromCGPoint(point1), touch);
        
    //NSLog(@"touchesEnded UICustomTapGestureRecognizer! %08X", touch);
    //we need to check distance again here, we might not have had a touchesMoved for this touch
    float distance = [self getDistanceOfTrackedTouch:touch];
    if (distance <= DISTANCE_LIMIT) {
      NSLog(@"touchesEnded ALLOWING distance %.3f for %08X", distance, touch);
      [pendingTouches addObject:[self touchDataFromUITouch:touch]];
      self.state = UIGestureRecognizerStateChanged;
    } else {
      NSLog(@"touchesEnded UICustomTapGestureRecognizer! %08X %@, [IGNORING, distance too large (%.3f)]", touch, NSStringFromCGPoint([touch locationInView:self.view]), distance);
    }
    [self removeTrackedTouch:touch];
  }
  if ([trackedTouches count]) {
    NSLog(@"!!! tracking: %d", [trackedTouches count]);
  }
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesCancelled:touches withEvent:event];
  for (UITouch* touch in touches) {
    NSLog(@"touchesCancelled UICustomTapGestureRecognizer! %08X", touch);
    [self removeTrackedTouch:touch];
  }
  if ([trackedTouches count]) {
    NSLog(@"!!! tracking: %d", [trackedTouches count]);
  }
}

- (TouchData*) popNextPendingTouch {
  if (![pendingTouches count]) {
    return nil;
  }
  TouchData* result = [pendingTouches objectAtIndex:0];
  [pendingTouches removeObjectAtIndex:0];
  return result;
}





@end
