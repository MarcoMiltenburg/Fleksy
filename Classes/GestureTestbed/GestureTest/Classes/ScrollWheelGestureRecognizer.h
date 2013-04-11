//
//  ScrollWheelGestureRecognizer.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 26/10/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>
#import <UIKit/UISwipeGestureRecognizer.h>

//TODO: more robust, infer dynamic center point, trigger speed based on angular speed,
//not absolute distance. Thus we wont have issue where swipe up will trigger more than once,
//only once we start turning will it fire again.
//Also: if we detect swipes AFTER finger up, then we could use the scroll wheel even when 
//starting a horizontal swipe without fear of it being detected as a L/R swipe.

#define MAX_LAST_POINTS 7

@interface ScrollWheelGestureRecognizer : UIGestureRecognizer {

  UISwipeGestureRecognizerDirection direction;
  float travelDistanceSinceDirectionChange;
  NSMutableArray* lastPoints;
  float travelDistance;
  float travelDistance2;
  //this is used as a flag to signal that something significant changed and needs to be acted upon.
  //normally gesture recognizers will call their target/action for any touchesMoved event
  BOOL trigger;
  
  //
  id originalTarget;
  SEL originalAction;
  
  
  int timesFired;
}


@property BOOL trigger;
@property UISwipeGestureRecognizerDirection direction;
//@property (readonly) float travelDistance;
@property (readonly) float travelDistance2;

@end
