//
//  UISwipeAndHoldGestureRecognizer.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/23/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "UIKit/UILongPressGestureRecognizer.h"

#if 1
#define SWIPE_RECOGNIZER_CLASS MySwipeGestureRecognizer
#import "MySwipeGestureRecognizer.h"
#else
#define SWIPE_RECOGNIZER_CLASS UISwipeGestureRecognizer
#import <UIKit/UISwipeGestureRecognizer.h>
#endif

#define DEFAULT_DELAY 0.6
#define DEFAULT_INTERVAL 0.15


@interface UISwipeGestureRecognizer (Private)
@property(readonly) CGPoint startPoint;
@property float minimumPrimaryMovement;
@property float maximumPrimaryMovement;
@property float minimumSecondaryMovement;
@property float maximumSecondaryMovement;
@property float rateOfMinimumMovementDecay;
@property float rateOfMaximumMovementDecay;
@end

//NOTES: does not currently support multiple target/action pairs!
//TODO set custom length threshold
@interface UISwipeAndHoldGestureRecognizer : UIGestureRecognizer<UIGestureRecognizerDelegate> {
@private
  NSMutableDictionary* swipeRecognizers;
  SWIPE_RECOGNIZER_CLASS* __weak lastFiredSwipeRecognizer;

  NSTimer* timer;
  
  id originalTarget;
  SEL originalAction;
  double swipeTime;
  
  int timesFired;
  
  NSMutableDictionary* directionRepeatDelays;
  NSMutableDictionary* directionRepeatIntervals;
}

- (id) initWithView:(UIView*) view target:(id)target action:(SEL)action;

- (void) setRepeatDelay:(float) delay repeatInterval:(float) interval forDirection:(UISwipeGestureRecognizerDirection) direction;
- (SWIPE_RECOGNIZER_CLASS*) swipeRecognizerForDirection:(UISwipeGestureRecognizerDirection) direction;

@property (weak, readonly) SWIPE_RECOGNIZER_CLASS* lastFiredSwipeRecognizer;
@property (readonly) int timesFired;
@property int numberOfTouchesRequired;



@end
