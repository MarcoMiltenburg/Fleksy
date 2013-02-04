//
//  FeedbackRecognizer.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/13/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FeedbackRecognizer.h"
#import "KeyboardImageView.h"
#import "FLKeyboard.h"
#import "FLKeyboardContainerView.h"
#import "UITouchManager.h"
#import "AppDelegate.h"
#import "VariousUtilities.h"
#import <Foundation/NSProcessInfo.h>

#define POPUP_DELAY    0.060
#define TAP_DELAY      0.100
#define POPUP_DURATION 0.100
#define TOCK_DELAY     POPUP_DELAY

// we use a small delay here to ensure we don't get erroneous characters on lift up
#define FLEKSY_HOVER_FEEDBACK_DELAY 0.050

@implementation FeedbackNATO

- (void) speakNATOforChar:(NSString*) charString {
  unichar c = [charString characterAtIndex:0];
  if (FleksyUtilities::isalpha(c)) {
    c = FleksyUtilities::toupper(c);
  }
  NSString* speak = nil;
  switch (c) {
    case 'A':
      speak = @"Alpha";
      break;
    case 'B':
      speak = @"Bravo";
      break;
    case 'C':
      speak = @"Charlie";
      break;
    case 'D':
      speak = @"Delta";
      break;
    case 'E':
      speak = @"Echo";
      break;
    case 'F':
      //speak = @"Foxtrot";
      speak = @"Fleksy"; // :)
      break;
    case 'G':
      speak = @"Golf";
      break;
    case 'H':
      speak = @"Hotel";
      break;
    case 'I':
      speak = @"India";
      break;
    case 'J':
      speak = @"Juliet";
      break;
    case 'K':
      speak = @"Kilo";
      break;
    case 'L':
      speak = @"Lima";
      break;
    case 'M':
      speak = @"Mike";
      break;
    case 'N':
      speak = @"November";
      break;
    case 'O':
      speak = @"Oscar";
      break;
    case 'P':
      speak = @"Papa";
      break;
    case 'Q':
      speak = @"Quebec";
      break;
    case 'R':
      speak = @"Romeo";
      break;
    case 'S':
      speak = @"Sierra";
      break;
    case 'T':
      speak = @"Tango";
      break;
    case 'U':
      speak = @"Uniform";
      break;
    case 'V':
      speak = @"Victor";
      break;
    case 'W':
      speak = @"Whiskey";
      break;
    case 'X':
      speak = @"X-ray";
      break;
    case 'Y':
      speak = @"Yankee";
      break;
    case 'Z':
      speak = @"Zulu";
      break;
    default:
      NSString* character = [NSString stringWithFormat:@"%C", c];
      NSLog(@"speakNATOforChar: %@ -> unknown", character);
      return;
      break;
  }
  [VariousUtilities performAudioFeedbackFromString:speak];
}

@end

@implementation FeedbackRecognizer

- (id) initWithTarget:(id) _target action:(SEL) _action {
  if (self = [super initWithTarget:_target action:_action]) {
    nato = [[FeedbackNATO alloc] init];
    hoverMode = NO;
    currentTouches = [[NSMutableArray alloc] init];
    lastTouchDown = nil;
    lastTouchUpTime = 0;
    self.delegate = self;
    swipeAnalyzers = [[NSMutableDictionary alloc] init];
    
    FLSwipeStatisticalAnalyzer* swipeLeftAnalyzer  = [[FLSwipeStatisticalAnalyzer alloc] initWithDirection:UISwipeGestureRecognizerDirectionLeft];
    FLSwipeStatisticalAnalyzer* swipeRightAnalyzer = [[FLSwipeStatisticalAnalyzer alloc] initWithDirection:UISwipeGestureRecognizerDirectionRight];
    FLSwipeStatisticalAnalyzer* swipeUpAnalyzer    = [[FLSwipeStatisticalAnalyzer alloc] initWithDirection:UISwipeGestureRecognizerDirectionUp];
    FLSwipeStatisticalAnalyzer* swipeDownAnalyzer  = [[FLSwipeStatisticalAnalyzer alloc] initWithDirection:UISwipeGestureRecognizerDirectionDown];
    
    [swipeAnalyzers setObject:swipeLeftAnalyzer  forKey:[NSNumber numberWithInteger:swipeLeftAnalyzer.direction]];
    [swipeAnalyzers setObject:swipeRightAnalyzer forKey:[NSNumber numberWithInteger:swipeRightAnalyzer.direction]];
    [swipeAnalyzers setObject:swipeUpAnalyzer    forKey:[NSNumber numberWithInteger:swipeUpAnalyzer.direction]];
    [swipeAnalyzers setObject:swipeDownAnalyzer  forKey:[NSNumber numberWithInteger:swipeDownAnalyzer.direction]];
  }
  return self;
}

- (KeyboardImageView*) keyboardImageView {
  return (KeyboardImageView*) [FLKeyboard sharedFLKeyboard].activeView;
}

- (void) playTockForTouch:(UITouch*) touch {
  //after swiping to change keyboard or other cases the runloop might finally fire
  //this event much later than requested, we will skip it then
  NSProcessInfo* processInfo = [NSProcessInfo processInfo];
  double delay = processInfo.systemUptime - touch.initialTimestamp;
  if (delay <= TOCK_DELAY + 0.3) {
    [VariousUtilities playTock];
    //NSLog(@"playing tock with delay  %.6f", delay);
  } else {
    NSLog(@"skipping tock with delay %.6f", delay);
  }
}

- (void) setNewChar:(UITouch*) touch {
  if (pendingChar == lastChar) {
    NSLog(@"ignoring pendingChar == lastChar %c", pendingChar);
    return;
  }
  //NSLog(@"setNewChar %p <%c>", touch, pendingChar);
  if (lastChar) {
    [[self keyboardImageView] doPopupForTouch:touch];
    [VariousUtilities playTock];
  }
  lastChar = pendingChar;
  [NSObject cancelPreviousPerformRequestsWithTarget:nato];
  if (lastChar == '\n') {
    [VariousUtilities performAudioFeedbackFromString:self.returnKeyLabel];
  } else {
    FLChar c = FleksyUtilities::tolower(lastChar);
    FLString temp(&c, 1);
    NSString* charString = FLStringToNSString(temp);
    [VariousUtilities performAudioFeedbackFromString:charString];
    [nato performSelector:@selector(speakNATOforChar:) withObject:charString afterDelay:1];
  }
}

- (void) updateHoverChar:(UITouch*) touch {
  //NSLog(@"updateHoverChar %p", touch);
  CGPoint point = [touch locationInView:[self keyboardImageView]];
  unichar newChar = [[self keyboardImageView] getNearestCharForPoint:point];
  //newChar = tolower(newChar);
  if (newChar != pendingChar) {
    pendingChar = newChar;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (lastChar) {
      [self performSelector:@selector(setNewChar:) withObject:touch afterDelay:FLEKSY_HOVER_FEEDBACK_DELAY];
    } else {
      [self setNewChar:touch];
    }
  }
}


// TODO merge the 2 calls into one in the queue if delays are the same?
- (void) queueTap:(UITouch*) touch {
  //NSLog(@"queue touch %p:%d", touch, touch.tag);
  [[self keyboardImageView] performSelector:@selector(doPopupForTouch:) withObject:touch afterDelay:POPUP_DELAY];
  //[[FLKeyboardContainerView sharedFLKeyboardContainerView] performSelector:@selector(handleTouch:) withObject:touch afterDelay:TAP_DELAY];
}

- (void) stopTrackingTouch:(UITouch*) touch {
  //NSLog(@"unque touch %p, delay: %.6f, tag: %d", touch, touch.timeSinceTouchdown, touch.tag);
  [NSObject cancelPreviousPerformRequestsWithTarget:[self keyboardImageView] selector:@selector(doPopupForTouch:) object:touch];
  [NSObject cancelPreviousPerformRequestsWithTarget:[FLKeyboardContainerView sharedFLKeyboardContainerView] selector:@selector(handleTouch:) object:touch];

  if (touch.tag == UITouchTypePending) {
    if (!touch.didFeedback) {
      [[self keyboardImageView] doPopupForTouch:touch];
    }
    [[FLKeyboardContainerView sharedFLKeyboardContainerView] performSelector:@selector(handleTouch:) withObject:touch];
  } else {
    NSLog(@"stopTrackingTouch was not pending, tag: %d", touch.tag);
  }
}


- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"touches began feedback! %d", [touches count]);
  
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView cancelAllSpellingRequests];
  
  self.state = UIGestureRecognizerStateBegan;
  
  //can choose if we want a small delay to eliminate some popups on quick swipes
  for (UITouch* touch in touches) {
    //NSLog(@" - began %p", touch);
    [currentTouches addObject:touch];
    lastTouchDown = touch;
    //NSLog(@"touchesBegan, distance since start: %.3f", [touch distanceSinceStartInView:self.view]);
    [self queueTap:touch];
    //[self performSelector:@selector(playTockForTouch:) withObject:touch afterDelay:TOCK_DELAY];
    [self playTockForTouch:touch];
  }
  
  //[self.nextResponder touchesBegan:touches withEvent:event];
}

- (UISwipeGestureRecognizerDirection) getDirectionForTouch:(UITouch*) touch {
  CGPoint point1 = [touch initialLocationInView:self.view];
  CGPoint point2 = [touch locationInView:self.view];
  float dx = point1.x - point2.x;
  float dy = point1.y - point2.y;
  if (fabs(dx) > fabs(dy)) {
    return dx > 0 ? UISwipeGestureRecognizerDirectionLeft : UISwipeGestureRecognizerDirectionRight;
  } else {
    return dy > 0 ? UISwipeGestureRecognizerDirectionUp : UISwipeGestureRecognizerDirectionDown;
  }
}

- (void) checkTouchForSwipe:(UITouch*) touch {
  if (!FLEKSY_USE_CUSTOM_GESTURE_DETECTION) {
    return;
  }
  
  float distance = [touch distanceSinceStartInView:self.view];
  
  UISwipeGestureRecognizerDirection direction = [self getDirectionForTouch:touch];
  FLSwipeStatisticalAnalyzer* swipeAnalyzer = [swipeAnalyzers objectForKey:[NSNumber numberWithInteger:direction]];
  
  if (distance > swipeAnalyzer.effectiveThreshold && touch.tag == UITouchTypePending) {
    double dt = touch.timeSinceTouchdown;
    double velocity = distance / dt;
    NSLog(@"could be swipe, distance:%.3f, dt:%.3f, v:%.3f", distance, dt, velocity);
    if (dt < 0.150) {
      BOOL allowSwipe = YES; //swipeAnalyzer.enabled;
      if (direction == UISwipeGestureRecognizerDirectionDown || direction == UISwipeGestureRecognizerDirectionUp || direction == UISwipeGestureRecognizerDirectionLeft) {
        double timeSinceLastTouchUp = CFAbsoluteTimeGetCurrent() - lastTouchUpTime;
        NSLog(@"timeSinceLastTouchUp: %.6f", timeSinceLastTouchUp);
        if (timeSinceLastTouchUp < 0.3) {
          allowSwipe = NO;
        }
      }
      if (allowSwipe) {
        // we have to force other touches that LANDED BEFORE WE LANDED
        [self forceTouchesBeforeTouch:touch];
        [[FLKeyboardContainerView sharedFLKeyboardContainerView] handleSwipeDirection:direction fromTouch:touch caller:@"FeedbackRecognizer"];
      } else {
        NSLog(@"swipe disabled for direction %d, ignoring for now...", swipeAnalyzer.direction);
      }
    } else {
      NSLog(@"ignoring touch %p", touch);
      //touch.tag = UITouchTypeIgnore;
    }
  }
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"touches moved feedback! %d", [touches count]);
  
  self.state = UIGestureRecognizerStateChanged;
  
  //can assume asap that this is swipe and hide the popup immediately, or on the contrary,
  //adjust the popup in case we have moved to a different button (hover character selection?)
  
  //  UITouch* touch = [touches anyObject];
  //  CGPoint point0 = [touch previousLocationInView:self];
  //  CGPoint point1 = [touch locationInView:self];
  //  float delta = distanceOfPoints(point0, point1);
  //  NSLog(@"delta: %.3f", delta);
  
  for (UITouch* touch in touches) {
    if (UITouchTypeIsProcessed(touch.tag)) {
      //NSLog(@"skipping touch %p in move, has been processed (%d)", touch, touch.tag);
      continue;
    } else if (touch.tag == UITouchTypeIgnore) {
      //NSLog(@"found ignored touch %p", touch);
      continue;
    } else {
      //NSLog(@"NOT skipping touch %p in move, (%d)", touch, touch.tag);
    }
    //NSLog(@" - moved %p", touch);
    if (self.hoverMode) {
      [self updateHoverChar:touch];
    } else {
      [self checkTouchForSwipe:touch];
    }
  }
  //[self.nextResponder touchesMoved:touches withEvent:event];
}

- (void) forceTouchesBeforeTouch:(UITouch*) touch {
  for (UITouch* forceTouch in currentTouches) {
    if (forceTouch.initialTimestamp < touch.initialTimestamp) {
      NSLog(@"forcing touch %p", forceTouch);
      [self stopTrackingTouch:forceTouch];
    } else {
      //NSLog(@"NOT forcing touch, was later");
    }
  }
}

- (void) touchesEnded:(NSSet*) touches {
  
  for (UITouch* touch in touches) {
    //NSLog(@" - ended %p", touch);
    if (self.hoverMode) {
      [self updateHoverChar:touch];
      [self stopHover];
    }
    if (touch.phase != UITouchPhaseCancelled) {
    //
    }
    
    // we have to force other touches THAT LANDED BEFORE WE LANDED
    [self forceTouchesBeforeTouch:touch];
    
    if (touch.tag == UITouchTypePending) {
      [self checkTouchForSwipe:touch];
    //}
    //if (touch.tag == UITouchTypePending) {
      [self stopTrackingTouch:touch];
    }
    
    float distance = [touch distanceSinceStartInView:self.view];
    
    
    // we want to notify the swipeAnalyzer that a swipe was finished, and we do it now rather
    // than at the point it is fired (in touchesMoved) so that we can have the final distance etc,
    // not the distance that it had when fired since that would always be near effectiveThreshold
    if (touch.tag == UITouchTypeProcessedSwipe) {
      UISwipeGestureRecognizerDirection direction = [self getDirectionForTouch:touch];
      FLSwipeStatisticalAnalyzer* swipeAnalyzer = [swipeAnalyzers objectForKey:[NSNumber numberWithInteger:direction]];
      [swipeAnalyzer touchEndedWithSwipe:touch];
    }
  
    if (touch.tag == UITouchTypeProcessedSwipe) {
      lastTouchUpTime = 0;
    } else {
      lastTouchUpTime = CFAbsoluteTimeGetCurrent(); //touch.timestamp;
    }
  }
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  //NSLog(@"touches ended feedback! %d", [touches count]);
  
  for (UITouch* touch in touches) {
    [currentTouches removeObject:touch];
    //NSLog(@"touchesEnded, distance since start: %.3f", [touch distanceSinceStartInView:self.view]);
  }
  [self touchesEnded:touches];
  
  //self.state = UIGestureRecognizerStateEnded;
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  NSLog(@"touches cancelled feedback! %d", [touches count]);
  self.state = UIGestureRecognizerStateCancelled;

  //some gesture recognizer (eg. the scrollview pan) might catch the touch so 
  //we need to stop handling it NOW
  for (UITouch* touch in touches) {
    touch.tag = UITouchTypeIgnore;
    //NSLog(@"touchesCancelled, distance since start: %.3f", [touch distanceSinceStartInView:self.view]);
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(playTockForTouch:) object:touch];
    [self stopTrackingTouch:touch];
  }
  
  [self touchesEnded:touches];
  //[self.nextResponder touchesCancelled:touches withEvent:event];
}

- (void) startHover {
#if !FLEKSY_SDK
  AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
  [appDelegate setProximityMonitoringEnabled:NO];
#endif
  hoverMode = YES;
  lastChar = 0;
  pendingChar = 0;
  lastTouchDown.tag = UITouchTypeProcessedLongTap;
  [self updateHoverChar:lastTouchDown];
}

- (void) stopHover {
  NSLog(@"stopHover");
  //[VariousUtilities performAudioFeedbackFromString:@"stop hover mode"];
  hoverMode = NO;
  //cancel NATO version of char
  [NSObject cancelPreviousPerformRequestsWithTarget:self];
  [NSObject cancelPreviousPerformRequestsWithTarget:nato];
#if !FLEKSY_SDK
  AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
  [appDelegate setProximityMonitoringEnabled:YES];
#endif
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  CGPoint location = [touch locationInView:self.view];
  //NSLog(@"FeedbackRecognizer shouldReceiveTouch %@, LOCATION: %@", touch, NSStringFromCGPoint(location));
  BOOL result = !CGPointEqualToPoint(location, FLEKSY_ACTIVATION_POINT);
  if (!result) {
    NSLog(@"FeedbackRecognizer ignoring FLEKSY_ACTIVATION_POINT touch");
  }
  return result;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*) gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*) otherGestureRecognizer {
  //NSLog(@"gestureRecognizer: %@ shouldRecognizeSimultaneouslyWithGestureRecognizer: %@", gestureRecognizer, otherGestureRecognizer);
  return YES;
}

@synthesize lastChar, hoverMode;

@end
