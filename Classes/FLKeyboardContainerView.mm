//
//  FLKeyboardContainerView.m
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FLKeyboardContainerView.h"
#import "FLWord.h"
#import "MathFunctions.h"
#import "Settings.h"
#import "SynthesizeSingleton.h"
#import "FLKeyboard.h"
#import "FileManager.h"
#import "UIGestureUtilities.h"
#import "UITapGestureRecognizer2.h"
#import "UITouchManager.h"
#import "HookingUtilities.h"
#import "FLTouchEventInterceptor.h"
#import <AudioToolbox/AudioToolbox.h>
#import "VariousUtilities.h"
#import <QuartzCore/QuartzCore.h>

#import <Foundation/NSObjCRuntime.h>

@implementation FLKeyboardContainerView

SYNTHESIZE_SINGLETON_FOR_CLASS(FLKeyboardContainerView);

- (void) reset {
  [suggestionsView reset];
  [suggestionsViewSymbols reset];
  [typingController reset];
}

- (id) init {
  
  if (self = [super initWithFrame:CGRectMake(0, 0, 10, 10)]) {
    
    // TODO: FleksyAPI Testing
    
    NSLog(@" ***** FleksyAPI Testing: START of Loading");
    
    fleksyListener = new FleksyListenerImplC();
    fleksyApi = new FleksyAPI(*fleksyListener);
    
    NSString* resourcePath = [NSString stringWithFormat:@"%@/en-US/", [[NSBundle mainBundle] bundlePath]];
    
    fleksyApi->setResourcePath(resourcePath.UTF8String);
    fleksyApi->loadResources();
    
    NSLog(@" ***** FleksyAPI Testing: END of Loading");

    self.backgroundColor = [UIColor clearColor];
    
    typingController = [FLTypingController_iOS sharedFLTypingController_iOS];
    
    //FLOutputImplementation* outputImplementation = new FLOutputImplementation();
    //typingControllerGeneric = new FLTypingController(*outputImplementation);
    
    suggestionsView = [[FLSuggestionsView alloc] initWithListener:typingController];
    suggestionsViewSymbols = [[FLSuggestionsView alloc] initWithListener:typingController];
    suggestionsViewSymbols.needsSpellingFeedback = NO;
    keyboard = [FLKeyboard sharedFLKeyboard];
    
    [self addSubview:keyboard];
    [self addSubview:suggestionsView];
    [self addSubview:suggestionsViewSymbols];
    
    self.userInteractionEnabled = YES;
    self.multipleTouchEnabled = YES;
    
    lastActivationPointTap = CFAbsoluteTimeGetCurrent();
    
    feedbackView = [[SwipeFeedbackView alloc] init];
    [self addSubview:feedbackView];
   
//    scrollWheelRecognizer = [[ScrollWheelGestureRecognizer alloc] initWithTarget:self action:@selector(handleScrollFrom:)];
//    scrollWheelRecognizer.delegate = self;
//    [scrollWheelRecognizer requireGestureRecognizerToFail:[swipeAndHoldRecognizer swipeRecognizerForDirection:UISwipeGestureRecognizerDirectionRight]];
//    [scrollWheelRecognizer requireGestureRecognizerToFail:[swipeAndHoldRecognizer swipeRecognizerForDirection:UISwipeGestureRecognizerDirectionLeft]];
//    [scrollWheelRecognizer requireGestureRecognizerToFail:[swipeAndHoldRecognizer swipeRecognizerForDirection:UISwipeGestureRecognizerDirectionDown]];
//    [scrollWheelRecognizer requireGestureRecognizerToFail:[swipeAndHoldRecognizer swipeRecognizerForDirection:UISwipeGestureRecognizerDirectionUp]];
//    [self addGestureRecognizer:scrollWheelRecognizer];
    
    //homeButtonTouchRecognizer = [[HomeButtonTouchRecognizer alloc] initWithTarget:self action:@selector(handleHomeButtonTouch)];
  
    topShadowView = [[UIView alloc] init];
    topShadowView.userInteractionEnabled = NO;
    topShadowView.backgroundColor = [UIColor blackColor];
    topShadowView.layer.shadowOffset = CGSizeMake(0, -4);
    topShadowView.layer.shadowRadius = 4;
    topShadowView.layer.shadowOpacity = 0.4;
    [self addSubview:topShadowView];
    [self sendSubviewToBack:topShadowView];
  }

  return self;
}

- (void) setAlpha:(CGFloat)alpha {
  //NSLog(@"FLKeyboardContainerView setAlpha: %.3f", alpha);
  [super setAlpha:alpha];
  
  // we have to overide and do this since topShadowView is the only view with non-clear color apart from FLKeyboard
  if (alpha == 1) {
    topShadowView.alpha = 1;
  } else {
    topShadowView.alpha = 0;
  }
}


- (BOOL) landscape {
  //BOOL result = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);
  UIWindow* window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
  //BOOL result = UIInterfaceOrientationIsLandscape(FLEKSY_APP_SETTING_LOCK_ORIENTATION ? FLEKSY_APP_SETTING_LOCK_ORIENTATION : window.rootViewController.interfaceOrientation);
  //BOOL result = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);
  BOOL result = UIDeviceOrientationIsLandscape((UIDeviceOrientation) window.rootViewController.interfaceOrientation);
  //NSLog(@"FLKeyboardContainerView landscape: %d", result);
  return result;
}

- (float) topPadding {
  return [self landscape] ? FLEKSY_TOP_PADDING_LANDSCAPE : FLEKSY_TOP_PADDING_PORTRAIT;
}

- (void) layoutSubviews {
  
  //NSLog(@"FLKeyboardContainerView layoutSubviews, self.frame: %@, self.bounds: %@", NSStringFromCGRect(self.frame), NSStringFromCGRect(self.bounds));

  //CGAffineTransform previous = keyboard.transform;
  
  //NSLog(@"FLKeyboardContainerView layoutSubviews");
  //we HAVE to set transform to identity before setting the frame!
  keyboard.transform = CGAffineTransformIdentity;
  keyboard.frame = CGRectMake(0, 0, 320, 216);
  
  //NSLog(@"keyboard.frame: %@", NSStringFromCGRect(keyboard.frame));
  
  keyboard.contentSize = CGSizeMake(keyboard.frame.size.width, keyboard.frame.size.height * 2);
  
  //NSLog(@"containerView self.bounds: %@", NSStringFromCGRect(self.bounds));
  
  int extraHeight = [self topPadding];
  
  CGAffineTransform scaleTransform = CGAffineTransformMakeScale(self.bounds.size.width / keyboard.frame.size.width, (self.bounds.size.height - extraHeight) / keyboard.frame.size.height);
  
  keyboard.transform = scaleTransform;
  
  CGRect keyboardFrame = [self convertRect:keyboard.bounds fromView:keyboard];
  //NSLog(@"FLKeyboardContainerView layoutSubviews, keyboard.transform: %@", NSStringFromCGAffineTransform(keyboard.transform));
  //NSLog(@"FLKeyboardContainerView layoutSubviews, keyboardFrame %@", NSStringFromCGRect(keyboardFrame));
  keyboard.center = CGPointMake(self.frame.size.width * 0.5, self.frame.size.height - keyboardFrame.size.height * 0.5);
  
  //float locationTop = [self convertPoint:CGPointZero fromView:keyboard].y; 
  //NSLog(@"FLKeyboardContainerView layoutSubviews 1111");
  
  float paddingRight = 0;
  
  suggestionsView.frame = CGRectMake(0, [self topPadding], self.bounds.size.width - paddingRight, FLEKSY_SUGGESTIONS_HEIGHT);
  suggestionsViewSymbols.frame = suggestionsView.frame;
  feedbackView.frame = suggestionsView.frame;
  
  //NSLog(@"FLKeyboardContainerView layoutSubviews 2222");
  [keyboard setNeedsLayout];
  
  
  CGRect f = [FLKeyboard sharedFLKeyboard].frame;
  // it doesnt matter exactly how high this is, but shadow wont be drawn if its very small...
  float z = 10; //topShadowView.layer.shadowRadius;
  topShadowView.frame = CGRectMake(f.origin.x, f.origin.y, f.size.width, z);

  //NSLog(@"FLKeyboardContainerView layoutSubviews DONE");
}



- (BOOL) cycleSuggestion:(int) offset {
  
  [typingController deleteAllPoints];
  
//  if ([suggestionsView isHidden] && [suggestionsViewSymbols isHidden]) {
//    FLSuggestionsView* sView = suggestionsView.lastInteractedTime > suggestionsViewSymbols.lastInteractedTime ? suggestionsView : suggestionsViewSymbols;
//    [sView show];
//  }
  
  if (![suggestionsViewSymbols isHidden]) {
    [suggestionsViewSymbols selectSuggestionWithOffset:offset replaceText:YES];
    return YES;
  }
  if (![suggestionsView isHidden]) {
    [suggestionsView selectSuggestionWithOffset:offset replaceText:YES];
    return YES;
  }
  
  return NO;
}

- (void) toggleLettersNumbers {
  BOOL isLetters = keyboard.activeView.tag == KEYBOARD_TAG_ABC_UPPER;
  if (isLetters) {
    [VariousUtilities performAudioFeedbackFromString:@"Numbers"];
    [[FLKeyboard sharedFLKeyboard] resetWithActiveView:[FLKeyboard sharedFLKeyboard]->imageViewSymbolsA];
  } else {
    [VariousUtilities performAudioFeedbackFromString:@"Letters"];
    [[FLKeyboard sharedFLKeyboard] resetWithActiveView:[FLKeyboard sharedFLKeyboard]->imageViewABC];
  }
}

- (void) processTouchPoint:(CGPoint) point precise:(BOOL) precise character:(unichar) c {
 
  //NSLog(@"processTouchPoint %d", c);
  
  if (c == '\t' || c == BACK_TO_LETTERS) {
    [self toggleLettersNumbers];
  } else {
    
    [typingController tapOccured:point precise:precise rawChar:c];
    
    //std::string* s = new std::string("");
    //s->push_back(c);
    //typingControllerGeneric->sendCharacter(*s, point.x, point.y, 0);
    
    NSLog(@" ***** FleksyAPI Testing: START api->sendTap");
    fleksyApi->sendTap(point.x, point.y);
    NSLog(@" ***** FleksyAPI Testing: END api->sendTap");    
    
    if (FleksyUtilities::isalpha(c)) { // [VariousUtilities charIsAlpha:c]) {
      [suggestionsView fadeout];
      [suggestionsViewSymbols fadeout];
    }
  }
}


- (void) handleHomeButtonTouch {
  AudioServicesPlaySystemSound(0x450);
  [typingController nonLetterCharInput:' ' autocorrectionType:kAutocorrectionChangeAndSuggest];
}

- (void) handleSpacebarPress {
  [self space];
}

- (void) space {
  
  if ([FLKeyboard sharedFLKeyboard].activeView != [FLKeyboard sharedFLKeyboard]->imageViewABC) {
    [[FLKeyboard sharedFLKeyboard] resetWithActiveView:[FLKeyboard sharedFLKeyboard]->imageViewABC];
  }
  
  [typingController nonLetterCharInput:' ' autocorrectionType:keyboard.activeView.tag == KEYBOARD_TAG_ABC_UPPER ? kAutocorrectionChangeAndSuggest : kAutocorrectionNone];
  [feedbackView swipeRecognized:UISwipeGestureRecognizerDirectionRight padding:![suggestionsView isHidden] || ![suggestionsViewSymbols isHidden]];  
  //typingControllerGeneric->swipeRight();
  NSLog(@" ***** FleksyAPI Testing: START api->space");
  fleksyApi->space();
  NSLog(@" ***** FleksyAPI Testing: END api->space");
}

- (void) handleSwipeDirection:(UISwipeGestureRecognizerDirection) direction fromTouch:(UITouch*) touch caller:(NSString*) caller {
  
  NSLog(@"handleSwipe caller:%@ dir: %d, touch %p, tag = %d, Dt: %.6f", caller, direction, touch, touch.tag, touch.timeSinceTouchdown);
  assert(touch);
  
  // we might process a swipe multiple times if it's held down
  if (touch.tag != UITouchTypePending && touch.tag != UITouchTypeProcessedSwipe) {
    [NSException raise:@"handleSwipeDirection already processed touch" format:@"touch: %@, tag: %d", touch, touch.tag];
  }
  
  touch.tag = UITouchTypeProcessedSwipe;
  [self.feedbackRecognizer stopTrackingTouch:touch];
  
  if (direction == UISwipeGestureRecognizerDirectionRight) {
    NSString* string = @"swipe_right";
    //TestFlightLog(@"%@", string);
    [typingController.diagnostics append:string];
    [self space];
  }
  
  if (direction == UISwipeGestureRecognizerDirectionLeft) {
    NSString* string = @"swipe_left";
    TestFlightLog(@"%@", string);
    [typingController.diagnostics append:string];
    [typingController backspace];
    [feedbackView swipeRecognized:direction padding:![suggestionsView isHidden] || ![suggestionsViewSymbols isHidden]];
    //typingControllerGeneric->backspace();
    NSLog(@" ***** FleksyAPI Testing: START api->backspace");
    fleksyApi->backspace();
    NSLog(@" ***** FleksyAPI Testing: END api->backspace");
  }
  
  if (direction == UISwipeGestureRecognizerDirectionUp) {
    if (typingController.hasPendingPoints && typingController.currentWordIsPrecise) {
      [typingController swapCaseForLastTypedCharacter];
    } else {
      [self cycleSuggestion:-1];
      //typingControllerGeneric->swipeUp();
      NSLog(@" ***** FleksyAPI Testing: START api->previousSuggestion");
      fleksyApi->previousSuggestion();
      NSLog(@" ***** FleksyAPI Testing: END api->previousSuggestion");
    }
  }
  
  if (direction == UISwipeGestureRecognizerDirectionDown) {
    if (typingController.hasPendingPoints && typingController.currentWordIsPrecise) {
      [typingController swapCaseForLastTypedCharacter];
    } else {
      [self cycleSuggestion:1];
      //typingControllerGeneric->swipeDown();
      NSLog(@" ***** FleksyAPI Testing: START api->nextSuggestion");
      fleksyApi->nextSuggestion();
      NSLog(@" ***** FleksyAPI Testing: END api->nextSuggestion");
    }
  }
  
  self->debugRecognizer.clearBeforeNextTouch = YES;
  
  //[scrollWheelRecognizer setDirection:direction];
}


- (void) handleSwipe:(SWIPE_RECOGNIZER_CLASS*) recognizer {
  
  UITouch* touch = [recognizer.activeTouches anyObject];
  
  UISwipeGestureRecognizerDirection direction = recognizer.direction;
  BOOL invertUpDown = NO;
  if (invertUpDown) {
    if (direction == UISwipeGestureRecognizerDirectionUp) {
      direction = UISwipeGestureRecognizerDirectionDown;
    } else if (direction == UISwipeGestureRecognizerDirectionDown) {
      direction = UISwipeGestureRecognizerDirectionUp;
    }
  }
  
  BOOL directSuggestionSelection = NO;
  if (directSuggestionSelection) {
#ifndef __clang_analyzer__
      // Code not to be analyzed
      float beganX = [recognizer locationInView:recognizer.view].x;
#endif
    
    float currentX = [recognizer currentLocationInView:recognizer.view].x;
    //NSLog(@"startX: %.3f, currentX: %.3f", x, currentX);
    beganX = currentX;
    
    FLSuggestionsView* activeSuggestions = nil;
    if (![suggestionsViewSymbols isHidden]) {
      activeSuggestions = suggestionsViewSymbols;
    } else if (![suggestionsView isHidden]) {
      activeSuggestions = suggestionsView;
    }
    
    if (direction == UISwipeGestureRecognizerDirectionUp) {
      [activeSuggestions selectSuggestionNearestScreenX:beganX];
      touch.tag = UITouchTypeIgnore;
      [self.feedbackRecognizer stopTrackingTouch:touch];
      return;
    }
    
    CGPoint suggestionPosition = [activeSuggestions selectedSuggestionPosition];
    
    float suggestionBegin = suggestionPosition.x - suggestionPosition.y * 0.5;
    float suggestionEnd   = suggestionPosition.x + suggestionPosition.y * 0.5;
    //NSLog(@"suggestionPosition: %@, %.3f <--> %.3f", NSStringFromCGPoint(suggestionPosition), suggestionBegin, suggestionEnd);
    
    
    if (direction == UISwipeGestureRecognizerDirectionDown) {
      if (beganX < suggestionBegin) {
        direction = UISwipeGestureRecognizerDirectionUp;
      } else if (beganX > suggestionEnd) {
        //
      } else {
        NSLog(@"ignoring swipe");
        touch.tag = UITouchTypeIgnore;
        [self.feedbackRecognizer stopTrackingTouch:touch];
        return;
      }
    }
  }
  

  [self handleSwipeDirection:direction fromTouch:touch caller:@"handleSwipe/MySwipeGestureRecognizer"];
  return;

#if UITOUCH_STORE_PATH  
  //ATTEMPT to handle weird (too fast/long) swipes
  NSArray* touches = [recognizer valueForKey:@"_touches"];
  //if this is a repeat/hold, the actual recognizer wont have any touches
  if ([touches count]) {
    UITouch* touch = [touches objectAtIndex:0]; //should only be one
    //CGPoint startPoint = recognizer.startPoint; //same as our [touch initialLocationInView:recognizer.view];
    //CGPoint endPoint = [touch locationInView:recognizer.view];
    //double startTime = touch.initialTimestamp; //slightly different result: *(double*) [recognizer primitiveInstanceVariableForKey:@"_startTime"];
    //double endTime = touch.timestamp;
    //float distance = distanceOfPoints(FLPointFromCGPoint(startPoint), FLPointFromCGPoint(endPoint));
    //double dt = endTime - startTime;
    
    //NSLog(@"path: %@", touch.path);
    
    BOOL didSplit = NO;
    
    NSLog(@"=====");
    NSArray* path = touch.path;
    for (int i = 1; i < [path count]; i++) {
      CGPoint previous = [[path objectAtIndex:i-1] CGPointValue];
      CGPoint current  = [[path objectAtIndex:i]  CGPointValue];
      float delta = distanceOfPoints(FLPointFromCGPoint(current), FLPointFromCGPoint(previous));
      NSLog(@"delta: %.3f", delta);
#pragma unused(delta)
//      if ((delta > 40 && i > 1) || (delta > 60)) {
//        NSLog(@"SPLITTING!!");
//        if (!didSplit) {
//          [self processTouchPoint:startPoint];
//        }
//        
//        current = [self.window convertPoint:current toView:recognizer.view];
//        [self processTouchPoint:current];
//        didSplit = YES;
//      }
    }
    if (didSplit) {
      return; //dont treat as swipe anymore
    }
  }
#endif
}

- (void) performNewLine {
  char newLine = '\n';
  [VariousUtilities playTock];
  [typingController nonLetterCharInput:newLine autocorrectionType:kAutocorrectionChangeAndSuggest];
  [VariousUtilities performAudioFeedbackFromString:[VariousUtilities descriptionForCharacter:newLine]];
  [feedbackView swipeRecognized:UISwipeGestureRecognizerDirectionRight padding:![suggestionsView isHidden] || ![suggestionsViewSymbols isHidden]];
}

- (void) handleSwipeAndHold:(UISwipeAndHoldGestureRecognizer*) recognizer {
  
//  if (recognizer.swipeDirection != UISwipeGestureRecognizerDirectionRight) {
//    NSLog(@"KV handleSwipeAndHold: %@ [%@] timesFired: %d", [UIGestureUtilities getDirectionString:recognizer.swipeDirection], [UIGestureUtilities getStateString:recognizer.state], recognizer.timesFired);
//  }
  
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    for (int i = 0; i < recognizer.numberOfTouchesRequired; i++) {
      if (FLEKSY_USE_CUSTOM_GESTURE_DETECTION) {
        // we dont do anything on first swipe now because we manually detect swipes in FeedbackRecognizer
        NSLog(@"ignore first swipe");
      } else {
        [self handleSwipe:recognizer.lastFiredSwipeRecognizer];
      }
    }
    return;
  }
  
  if (recognizer.state == UIGestureRecognizerStateChanged) {
    
    //NSLog(@"lastfired: %@, touches: %d", recognizer.lastFiredSwipeRecognizer, recognizer.lastFiredSwipeRecognizer.numberOfTouches);
  
    if (recognizer.lastFiredSwipeRecognizer.direction == UISwipeGestureRecognizerDirectionRight) {
      
      // old system for new line
      //[self performNewLine];
      
      // new idea for symbols KB
      if (false) {
        if ([FLKeyboard sharedFLKeyboard].activeView == [FLKeyboard sharedFLKeyboard]->imageViewABC) {
          [[FLKeyboard sharedFLKeyboard] resetWithActiveView:[FLKeyboard sharedFLKeyboard]->imageViewSymbolsB];
        } else if ([FLKeyboard sharedFLKeyboard].activeView == [FLKeyboard sharedFLKeyboard]->imageViewSymbolsB) {
          [[FLKeyboard sharedFLKeyboard] resetWithActiveView:[FLKeyboard sharedFLKeyboard]->imageViewSymbolsA];
        } else {
          [[FLKeyboard sharedFLKeyboard] resetWithActiveView:[FLKeyboard sharedFLKeyboard]->imageViewABC];
        }
      }
      
    } else if (recognizer.lastFiredSwipeRecognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
      [VariousUtilities playTock];
      [self handleSwipe:recognizer.lastFiredSwipeRecognizer];
    } else {
      //ignoring up down hold, we have the ScrollWheelRecognizer
    }
  }
}

//- (void) handleSwipeAndHold:(UISwipeAndHoldGestureRecognizer*) recognizer {
//  [self performSelectorOnMainThread:@selector(_handleSwipeAndHold:) withObject:recognizer waitUntilDone:NO];
//}

- (void) handleActivationPointTap {
  NSLog(@"FLKeyboardContainerView handleActivationPointTap!");
  //double timeSinceLastActivation = CFAbsoluteTimeGetCurrent() - lastActivationPointTap;
  //if (timeSinceLastActivation > 0.5) {
    //[self toggleLettersNumbers];
    lastActivationPointTap = CFAbsoluteTimeGetCurrent();
    [[NSNotificationCenter defaultCenter] postNotificationName:FLEKSY_KEYBOARD_CLICKED_NOTIFICATION object:nil];
  //} else {
  //  NSLog(@"ignoring too fast handleActivationPointTap");
  //}
}

- (BOOL) handleTouch:(UITouch*) touch {
  //NSLog(@"handleTouch %p: %d. Dt:%.6f", touch, touch.tag, touch.timeSinceTouchdown);
  
  if (touch.tag != UITouchTypePending) {
    [NSException raise:@"handleTouch:" format:@"should not process touch %p again, tag = %d", touch, touch.tag];
  }
  
  touch.tag = UITouchTypeProcessedTap;
  
  CGPoint parentLocation = [touch locationInView:self.superview];
  CGPoint initialLocation = [touch initialLocationInView:keyboard];
  CGPoint currentLocation = [touch locationInView:keyboard];
  double dt = touch.timeSinceTouchdown;
  CGPoint point = dt < 0.3 ? initialLocation : currentLocation;
  //NSLog(@"touch (%08X) initialLocation: %@, currentLocation: %@, parentLocation: %@ (touch: %@), dt:%.6f", touch,
  //          NSStringFromCGPoint(initialLocation), NSStringFromCGPoint(currentLocation), NSStringFromCGPoint(parentLocation), touch, dt);
  
  if (CGPointEqualToPoint(parentLocation, FLEKSY_ACTIVATION_POINT)) {
    [self handleActivationPointTap];
    return NO;
  }
  
  KeyboardImageView* kbImageView = (KeyboardImageView*) [FLKeyboard sharedFLKeyboard].activeView;
  unichar rawChar = [kbImageView getNearestCharForPoint:point];
  [self processTouchPoint:point precise:NO character:rawChar];
  return YES;
}

- (void) handleTapFrom2:(UITapGestureRecognizer2*) recognizer {
  NSLog(@"handleTapFrom2: numberOfTouches:%d, state: %@", [recognizer numberOfTouches], [UIGestureUtilities getStateString:recognizer.state]);
  
//  double startTime = CFAbsoluteTimeGetCurrent();
//  for (int n = 0; n < 1; n++) {
//    NSArray* touches = [recognizer orderedTouches];
//    for (UITouch* touch in touches) {
//      CGPoint initialLocation = [touch initialLocationInView:keyboard];
//    }
//  }
//  double dt = CFAbsoluteTimeGetCurrent() - startTime;
//  NSLog(@"dt: %.6f", dt);
//  
 
  NSArray* touches = [recognizer orderedTouches];
  
  //double startTime = CFAbsoluteTimeGetCurrent();
  int i = 0;
  for (UITouch* touch in touches) {
    if (![self handleTouch:touch]) {
      break;
    }
    i++;
  }
  //double dt = CFAbsoluteTimeGetCurrent() - startTime;
  
  //NSLog(@"dt: %.6f", dt);

}

/*
- (void) handleScrollFrom:(ScrollWheelGestureRecognizer*) recognizer {
  
  if (recognizer.state != UIGestureRecognizerStateChanged) {
    NSLog(@"Ignoring ScrollWheelGestureRecognizer state %@", [UIGestureUtilities getStateString:recognizer.state]);
    return;
  }  
  
//  NSLog(@"handleScrollFrom, direction: %@, travelDistance: %.3f, state: %@", 
//        [UIGestureUtilities getDirectionString:recognizer.direction], recognizer.travelDistance2, [UIGestureUtilities getStateString:recognizer.state]);
  
  if (recognizer.state == UIGestureRecognizerStateChanged && recognizer.trigger) {
    if (recognizer.travelDistance2 > 1) {
      [VariousUtilities playTock];
      [self handleSwipeDirection:recognizer.direction fromTouch:nil];
      recognizer.trigger = NO;
    } else {
      NSLog(@"Ignoring ScrollWheelGestureRecognizer travelDistance %.3f", recognizer.travelDistance2);
    }
  }
  
  if (recognizer.state == UIGestureRecognizerStateEnded) {
    //NSLog(@"handleScrollFrom UIGestureRecognizerStateEnded");
    //typingController.suggestionsView.alpha = 0;
  }
}
*/

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  NSLog(@"touches began FLKeyboardContainerView! %@", touches);
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesMoved:touches withEvent:event];
  //NSLog(@"touches moved FLKeyboardContainerView! %@", touches);
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesEnded:touches withEvent:event];
  //NSLog(@"touches ended FLKeyboardContainerView! %@", touches);
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesCancelled:touches withEvent:event];
  //NSLog(@"touches cancelled FLKeyboardContainerView! %@", touches);
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer*) gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer*) otherGestureRecognizer {
  //NSLog(@"gestureRecognizer: %@ shouldRecognizeSimultaneouslyWithGestureRecognizer: %@", gestureRecognizer, otherGestureRecognizer);
  return YES;
}


@synthesize typingController, suggestionsView, suggestionsViewSymbols;

@end