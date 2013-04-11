//
//  UISwipeAndHoldGestureRecognizer.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/23/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "UISwipeAndHoldGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "UIGestureUtilities.h"
#import "UITouchManager.h"
#import "VariousUtilities.h"
#import "Settings.h"

@implementation UISwipeAndHoldGestureRecognizer

- (id) initWithTarget:(id)target action:(SEL)action {
  NSException* ex = [[NSException alloc] initWithName:@"UISwipeAndHoldGestureRecognizer error" reason:@"Use initWithView: instead" userInfo:nil];
  [ex raise];
  return self;
}

- (void) setRepeatDelay:(float) delay repeatInterval:(float) interval forDirection:(UISwipeGestureRecognizerDirection) direction {
  [directionRepeatDelays    setObject:[NSNumber numberWithFloat:delay]    forKey:[NSNumber numberWithInt:direction]];
  [directionRepeatIntervals setObject:[NSNumber numberWithFloat:interval] forKey:[NSNumber numberWithInt:direction]];
}

- (void) addSwipeRecognizerInView:(UIView*) theView forDirection:(UISwipeGestureRecognizerDirection) direction {
  SWIPE_RECOGNIZER_CLASS* swipeRecognizer = [[SWIPE_RECOGNIZER_CLASS alloc] initWithTarget:self action:@selector(swipeFired:)];
  //default is 50
  //#define MINIMUM_PRIMARY_MOVEMENT (deviceIsPad() ? 90 : 50)
  //swipeRecognizer.minimumPrimaryMovement = MINIMUM_PRIMARY_MOVEMENT;
  swipeRecognizer.direction = direction;
  swipeRecognizer.delegate = self;
  [theView addGestureRecognizer:swipeRecognizer];
  [swipeRecognizers setObject:swipeRecognizer forKey:[NSNumber numberWithInt:swipeRecognizer.direction]];
}

- (SWIPE_RECOGNIZER_CLASS*) swipeRecognizerForDirection:(UISwipeGestureRecognizerDirection) direction {
  return [swipeRecognizers objectForKey:[NSNumber numberWithInt:direction]];
}


- (id) initWithView:(UIView*) view target:(id) target action:(SEL) action {
  if (self = [super initWithTarget:target action:action]) {
    
    originalTarget = target;
    originalAction = action;
    
    directionRepeatDelays    = [[NSMutableDictionary alloc] init];
    directionRepeatIntervals = [[NSMutableDictionary alloc] init];
    
    self.delegate = self;
    
    swipeRecognizers = [[NSMutableDictionary alloc] initWithCapacity:4];
    
    [self addSwipeRecognizerInView:view forDirection:UISwipeGestureRecognizerDirectionRight];
    [self addSwipeRecognizerInView:view forDirection:UISwipeGestureRecognizerDirectionLeft];
    [self addSwipeRecognizerInView:view forDirection:UISwipeGestureRecognizerDirectionUp];
    [self addSwipeRecognizerInView:view forDirection:UISwipeGestureRecognizerDirectionDown];
    
    [self setRepeatDelay:DEFAULT_DELAY repeatInterval:DEFAULT_INTERVAL forDirection:UISwipeGestureRecognizerDirectionDown];
    [self setRepeatDelay:DEFAULT_DELAY repeatInterval:DEFAULT_INTERVAL forDirection:UISwipeGestureRecognizerDirectionLeft];
    [self setRepeatDelay:DEFAULT_DELAY repeatInterval:DEFAULT_INTERVAL forDirection:UISwipeGestureRecognizerDirectionRight];
    [self setRepeatDelay:DEFAULT_DELAY repeatInterval:DEFAULT_INTERVAL forDirection:UISwipeGestureRecognizerDirectionUp];
    
    [self reset];
  }
  return self;
}

// called before touchesBegan:withEvent: is called on the gesture recognizer for a new touch. return NO to prevent the gesture recognizer from seeing this touch
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  
  //TODO this is an attempt for swipe while tap
//  if (gestureRecognizer == swipeRightRecognizer2) {
//    NSLog(@"nTouches: %d", swipeRightRecognizer.numberOfTouches);
//    BOOL b = self.numberOfTouches == 1;
//    return b;
//  }
  
  return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  return YES;
}

- (void) requireGestureRecognizerToFail:(UIGestureRecognizer *)otherGestureRecognizer {
  [super requireGestureRecognizerToFail:otherGestureRecognizer];
  for (SWIPE_RECOGNIZER_CLASS* recognizer in [swipeRecognizers allValues]) {
    [recognizer requireGestureRecognizerToFail:otherGestureRecognizer];
  }
}


- (void) reset {
  //NSLog(@"UISwipeAndHoldGestureRecognizer reset called");
  [super reset];
  timesFired = 0;
  lastFiredSwipeRecognizer = nil;
  [self removeTarget:nil action:nil];
  [self addTarget:originalTarget action:originalAction];
}

- (void) repeatActionWithState:(UIGestureRecognizerState) state {
  //NSLog(@"timer fired");
  super.state = state;
  SuppressPerformSelectorLeakWarning([originalTarget performSelector:originalAction withObject:self]);
  timesFired++;
}

- (void) repeatAction {
  [self repeatActionWithState:UIGestureRecognizerStateChanged];
}

- (void) startRepeat {
  
  assert(!timer);
  
  if (super.state != UIGestureRecognizerStateBegan) {
    NSLog(@"WARNING: startRepeat called but state is not began, its %@", [UIGestureUtilities getStateString:super.state]);
    return;
  }
  
  float interval = [[directionRepeatIntervals objectForKey:[NSNumber numberWithInt:lastFiredSwipeRecognizer.direction]] floatValue];
  timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(repeatAction) userInfo:nil repeats:YES];
  //also fire now
  [timer fire];
}

- (void) swipeFired:(SWIPE_RECOGNIZER_CLASS*) swipeRecognizer; {
  
  NSLog(@"swipeFired, direction: %@, state: %@, numberOfTouches: %d", [UIGestureUtilities getDirectionString:swipeRecognizer.direction], [UIGestureUtilities getStateString:swipeRecognizer.state], swipeRecognizer.numberOfTouches);
  
  lastFiredSwipeRecognizer = swipeRecognizer;
  swipeTime = CFAbsoluteTimeGetCurrent();
  //we need to remove all target/action pairs or they will be called for every touchesMoved.
  //Note that we cant even eliminate this by nop-ing touchesMoved (why?) 
  [self removeTarget:nil action:nil];
  
  //send initial swipe event now
  [self repeatActionWithState:UIGestureRecognizerStateBegan];
  
  //and setup timer
  float delay = [[directionRepeatDelays objectForKey:[NSNumber numberWithInt:swipeRecognizer.direction]] floatValue];
  [self performSelector:@selector(startRepeat) withObject:nil afterDelay:delay];
}

//overide to prevent state changing to UIGestureRecognizerStateChanged on touchesMoved
//Note that we cant even eliminate this by nop-ing touchesMoved (why?) 
- (void) setState:(UIGestureRecognizerState) s {
  //NSLog(@"UISwipeAndHoldGestureRecognizer wants to set state from %@ to %@", [UIGestureUtilities getStateString:super.state], [UIGestureUtilities getStateString:s]);
  //[super setState:s];
}

//- (void) markFailed {
//  super.state = UIGestureRecognizerStateFailed;
//  for (SWIPE_RECOGNIZER_CLASS* recognizer in [swipeRecognizers allValues]) {
//    recognizer.state = UIGestureRecognizerStateFailed;
//  }
//}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"touches began UISwipeAndHoldGestureRecognizer %d, %d/%d", touches.count, self.numberOfTouches, self.numberOfTouchesRequired);
  
  //NOTE that self.numberOfTouches already INCLUDES [touches count] here
  //NSLog(@"touchesBegan %d, numberOfTouches: %d, numberOfTouchesRequired: %d", [touches count], self.numberOfTouches, self.numberOfTouchesRequired);
  if (/*[touches count] + */ self.numberOfTouches > self.numberOfTouchesRequired) {
    //NSLog(@"%d failed, too many touches (%d)", self.numberOfTouchesRequired, self.numberOfTouches);
    // we dont want to fail if we want to support "overlapping" gestures, eg tap+hold, then swipe with another touch
    // also if we fail here we will never get touchesEnded and never stop the timer! (newline bug)
    //super.state = UIGestureRecognizerStateFailed;
    // optional since its not created yet?
    //[self disableTimer];
    return;
  }
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  //[feedbackView touchMoved:[touches anyObject]];
}

- (void) disableTimer {
  //NSLog(@"UISwipeAndHoldGestureRecognizer disable");
  //assert(timer);
  [timer invalidate];
  timer = nil;
  [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startRepeat) object:nil];
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"touches ended UISwipeAndHoldGestureRecognizer! %@", touches);
  if (super.state == UIGestureRecognizerStatePossible) {
    super.state = UIGestureRecognizerStateFailed;
  } else {
    super.state = UIGestureRecognizerStateEnded;
  }
  [self disableTimer];
  //[feedbackView dismiss];
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  NSLog(@"touches cancelled UISwipeAndHoldGestureRecognizer! %@", touches);
  super.state = UIGestureRecognizerStateFailed;
  [self disableTimer];
  //[self touchesEnded:touches withEvent:event];
  //[feedbackView dismiss];
}

//we need to overide this to stop and clear our timers
- (void) setEnabled:(BOOL) enabled {
  NSLog(@"UISwipeAndHoldGestureRecognizer setEnabled: %d", enabled);
  if (!enabled) {
    [self disableTimer];
  }
  [super setEnabled:enabled];
  for (SWIPE_RECOGNIZER_CLASS* recognizer in [swipeRecognizers allValues]) {
    recognizer.enabled = enabled;
  }
}

- (int) numberOfTouchesRequired {
  for (SWIPE_RECOGNIZER_CLASS* recognizer in [swipeRecognizers allValues]) {
    return recognizer.numberOfTouchesRequired;
  }
  NSLog(@"ERROR: numberOfTouchesRequired no recognizers?");
  return -1;
}

- (void) setNumberOfTouchesRequired:(int) n {
  for (SWIPE_RECOGNIZER_CLASS* recognizer in [swipeRecognizers allValues]) {
    recognizer.numberOfTouchesRequired = n;
  }
}

@synthesize timesFired, lastFiredSwipeRecognizer;

@end
