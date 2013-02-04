//
//  HomeButtonTouchRecognizer.h
//  EasyType
//
//  Created by Kostas Eleftheriou on 2/19/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>

@interface HomeButtonTouchRecognizer : NSObject {
  CMMotionManager *motionManager;
	//CMAttitude* lastAttitude;
  double lastRotation;
  double lastTimeTriggered;
  
  //CMDeviceMotionHandler handler;
  id target;
  SEL action;
}

- (id) initWithTarget:(id) target action:(SEL) action;
- (void) start;
- (void) stop;

@end
