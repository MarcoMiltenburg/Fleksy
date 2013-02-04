//
//  HomeButtonTouchRecognizer.m
//  EasyType
//
//  Created by Kostas Eleftheriou on 2/19/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "HomeButtonTouchRecognizer.h"
#import "UITouchManager.h"

@implementation HomeButtonTouchRecognizer

- (id) initWithTarget:(id) _target action:(SEL) _action {
  if (self = [super init]) {
    [UITouchManager initializeTouchManager];
    motionManager = [[CMMotionManager alloc] init];
    target = _target;
    action = _action;
  }
  return self;
}


- (void) start {
  [motionManager stopDeviceMotionUpdates];
  
  lastRotation = 0;
  lastTimeTriggered = CFAbsoluteTimeGetCurrent();
  
  CMDeviceMotionHandler handler = ^ (CMDeviceMotion *motion, NSError *error) {
    
    CMRotationRate rotate = motion.rotationRate;
    double angularAcceleration = rotate.x - lastRotation;
    
    if (angularAcceleration > 0.14 && lastRotation > -0.06 && rotate.x < 1.5 && fabs(rotate.y) < 0.35 && fabs(rotate.z) < 0.2 &&
        motion.userAcceleration.z > -0.12 && fabs(motion.userAcceleration.x) < 0.1 && fabs(motion.userAcceleration.y) < 0.1) {
      
      double now = CFAbsoluteTimeGetCurrent();
      double timeSinceLastTrigger = now - lastTimeTriggered;
      
      if (timeSinceLastTrigger > 0.25) {
        
        double deltaWithTouch = [NSProcessInfo processInfo].systemUptime - [UITouchManager lastTouchTimestamp];
        if (deltaWithTouch > 0.220) {
          
          //NSLog(@":) rotation [%f, %f, %f], lastX: %f. AA: %f. Acceleration [%f, %f, %f]. %.0f msec after last touch",
          //      rotate.x, rotate.y, rotate.z, lastRotation, angularAcceleration, motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z, deltaWithTouch * 1000);
          [target performSelectorOnMainThread:action withObject:target waitUntilDone:NO];
          //[target performSelector:action withObject:target];
          lastTimeTriggered = now;
        } else {
          //NSLog(@"was touch");
        }
      } else {
        //NSLog(@"ignoring too quick");
      }
    }
    
    //lastAttitude = motion.attitude;
    lastRotation = rotate.x;
  };

  
  [motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue] withHandler:handler];
  NSLog(@"HomeButtonTouchRecognizer started");
}

- (void) stop {
  [motionManager stopDeviceMotionUpdates];
  NSLog(@"HomeButtonTouchRecognizer stopped");
}

@end
