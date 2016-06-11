//
//  FLSwipeStatisticalAnalyzer.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 11/7/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FLSwipeStatisticalAnalyzer.h"
#import "UITouchManager.h"
#import "MathFunctions.h"
#import "VariousUtilities.h"

#define MIN_SAMPLES 123456
#define THRESHOLD 0.5

#define RADIANS_TO_DEGREES(x) ((x) * 180.0 / M_PI)

@implementation FLSwipeStatisticalAnalyzer

- (id) initWithDirection:(UISwipeGestureRecognizerDirection) _direction {
  if (self = [super init]) {
    self->direction = _direction;
    self->totalSwipeDistance = 0;
    self->numberOfSwipes = 0;
    self->averageSlope = CGPointMake(0, 0);
    self.enabled = YES;
  }
  return self;
}


- (void) touchEndedWithSwipe:(UITouch*) touch {
//  if (touch.tag != FLTouchTypeProcessedSwipe) {
//    NSLog(@"not a swipe!");
//    return;
//  }
  
  float distance = [touch distanceSinceStartInView:touch.view];
  self->totalSwipeDistance += distance;
  self->numberOfSwipes++;
  CGPoint slope = subtractPoints([touch locationInView:touch.view], [touch initialLocationInView:touch.view]);
  //NSLog(@"[%d]: swipe distance: %.3f, slope: %.3f, dt: %.3f", self.direction, distance, RADIANS_TO_DEGREES(atan2(-slope.y, slope.x)), touch.timeSinceTouchdown);
  averageSlope = addPoints(averageSlope, slope);
}

- (float) averageDistance {
  float result;
  if (self->numberOfSwipes > MIN_SAMPLES) {
    result = self->totalSwipeDistance / self->numberOfSwipes;
  } else {
    result = deviceIsPad() ? 100 : 130;
  }
  return result;
}

- (float) effectiveThreshold {
  float result = self.averageDistance * THRESHOLD;
  //NSLog(@"[%d]: average: %.3f, effectiveThreshold: %.3f, averageSlope: %.1f, samples: %d",
  //      self.direction, self.averageDistance, result, RADIANS_TO_DEGREES(atan2(-averageSlope.y, averageSlope.x)), self->numberOfSwipes);
  return result;
}

- (UISwipeGestureRecognizerDirection) direction {
  return self->direction;
}

- (void) enable {
  self.enabled = YES;
}

@synthesize enabled;

@end
