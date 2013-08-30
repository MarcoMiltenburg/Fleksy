//
//  FleksyKeyboard.m
//
//  Created by Kostas Eleftheriou on 09/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FleksyKeyboard.h"
#import <UIKit/UIResponder.h>
#import "HookingUtilities.h"
#import "FileManager.h"
#import "UITouchManager.h"
#import "AppDelegate.h"
#import "UIRotorRecognizer.h"
#import "UITapGestureRecognizer2.h"
#import "UILongPressGestureRecognizer2.h"
#import "Settings.h"
#import "FLKeyboardContainerView.h"
#import "VariousUtilities.h"
#import "UIView+Extensions.h"
#import <QuartzCore/QuartzCore.h>
#import "FleksyAppMainViewController.h"

//#import "/usr/include/objc/objc-runtime.h"

#define ALLOW_KB_FLICKUP_CHANGE 0
#define SPACEBAR_HEIGHT (FLEKSY_APP_SETTING_SPACE_BUTTON ? (deviceIsPad() ? 75 : 50) : 0)

#define USE_TOUCH_INTERCEPTOR 0
#if USE_TOUCH_INTERCEPTOR
#import "FLTouchEventInterceptor.h"
#endif

static BOOL webviewSupportEnabled = NO;
static FleksyKeyboard* instance = nil;

@interface FleksyKeyboard (Private)

@property (readonly) UIResponder<UITextInput>* currentResponder;

@end

@implementation FleksyKeyboard {
  
  FLKeyboardContainerView* keyboardContainerView;
  UISwipeAndHoldGestureRecognizer* swipeAndHoldRecognizer;
  FeedbackRecognizer* feedbackRecognizer;
  DebugGestureRecognizer* debugRecognizer;
  
  UIButton* spacebar;
  UIButton* spacebarSeperator1;
  UIButton* spacebarSeperator2;
  
  //UITapGestureRecognizer* tripleTapRecognizer;
  
  MySwipeGestureRecognizer* actionRecognizer2Up;
  MySwipeGestureRecognizer* actionRecognizer2Down;
  UILongPressGestureRecognizer* oldActionRecognizer;
  
  int focusedCount;
  
  BOOL hasFinishedLoading;
}

//TODO: should be on scroll, not gesture. Pan gesture ends on release, not end of scroll
//we cant just use requireGestureRecognizerToFail:keyboard.panGestureRecognizer because there
//is a delay before the keyboard.panGestureRecognizer activates (wait till drag)
- (void) handlePanGesture:(UIPanGestureRecognizer*) recognizer {
  
  //NSLog(@"handlePanGesture %@", [UIGestureUtilities getStateString:recognizer.state]);
  
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    //NSLog(@"Disabling recognizers...");
    //customTapRecognizer.enabled = NO;
    swipeAndHoldRecognizer.enabled = NO;
    feedbackRecognizer.enabled = NO;
    //keyboardContainerView->scrollWheelRecognizer.enabled = NO;
    return;
  }
  
  if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
    //NSLog(@"Re-enabling recognizers...");
    //customTapRecognizer.enabled = YES;
    swipeAndHoldRecognizer.enabled = YES;
    feedbackRecognizer.enabled = YES;
    //keyboardContainerView->scrollWheelRecognizer.enabled = YES;
    return;
  }
  
}

- (void) handleSettingsChanged:(NSNotification*) notification {

  if([NSThread isMainThread] == NO) {
    [self performSelectorOnMainThread:_cmd withObject:notification waitUntilDone:NO];
    return;
  }

  //NSLog(@"handleSettingsChanged: %@, userInfo: %@, delay: %.6f", notification, [notification userInfo], [VariousUtilities getNotificationDelay:notification]);
  
  double startTime = CFAbsoluteTimeGetCurrent();
  
  
  NSDictionary* settings = [FileManager settings];
  if (!settings) {
    NSLog(@"no settings!");
    return;
  }
  
  NSString* oldFavorites = @"";
  if (FLEKSY_APP_SETTING_SPEED_DIAL_1) {
    oldFavorites = FLEKSY_APP_SETTING_SPEED_DIAL_1;
  }
  
  FLEKSY_APP_SETTING_SPEAK                     = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SPEAK" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_KEYBOARD_CLICKS           = YES; //[[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_KEYBOARD_CLICKS" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_SHOW_TRACES               = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SHOW_TRACES" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_KEY_SNAP                  = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_KEY_SNAP" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_INVISIBLE_KEYBOARD        = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_INVISIBLE_KEYBOARD" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_TOUCH_HOME                = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_TOUCH_HOME" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_DICTATE_MODE              = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_DICTATE_MODE" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_USE_SYSTEM_AUTOCORRECTION = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_USE_SYSTEM_AUTOCORRECTION" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_SHOW_SUGGESTIONS          = YES;
  FLEKSY_APP_SETTING_LIVE_SUGGESTIONS          = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_LIVE_SUGGESTIONS" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_HOME_BUTTON_STRING        =  [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_HOME_BUTTON_STRING" fromSettings:settings];
  FLEKSY_APP_SETTING_SPEED_DIAL_1              =  [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SPEED_DIAL_1" fromSettings:settings];
  FLEKSY_APP_SETTING_SMS_REPLY_TO              =  [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SMS_REPLY_TO" fromSettings:settings];
  FLEKSY_APP_SETTING_EMAIL_REPLY_TO            =  [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_EMAIL_REPLY_TO" fromSettings:settings];
  FLEKSY_APP_SETTING_EMAIL_SIGNATURE           =  [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_EMAIL_SIGNATURE" fromSettings:settings];
  FLEKSY_APP_SETTING_SPEAKING_RATE             = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SPEAKING_RATE" fromSettings:settings] floatValue];
  FLEKSY_APP_SETTING_LOCK_ORIENTATION          = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_LOCK_ORIENTATION" fromSettings:settings] intValue];
  FLEKSY_APP_SETTING_SPELL_WORDS               = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SPELL_WORDS" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_RAISE_TO_SPEAK            = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_RAISE_TO_SPEAK" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_EMAIL_INCLUDE_FIRST_LINE  = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_EMAIL_INCLUDE_FIRST_LINE" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_SPACE_BUTTON              = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SPACE_BUTTON" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_LANGUAGE_PACK             =  [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_LANGUAGE_PACK" fromSettings:settings];
  FLEKSY_APP_SETTING_THEME                     = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_THEME" fromSettings:settings] intValue];
  // Only saved locally, not across devices
  //FLEKSY_APP_CACHE_QUESTIONAIRE          = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_CACHE_QUESTIONAIRE" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_COPY_ON_EXIT              = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_COPY_ON_EXIT" fromSettings:settings] boolValue];
  FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER          = [[VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER" fromSettings:settings] boolValue];
  

  if (FLEKSYTHEME.currentThemeType != FLEKSY_APP_SETTING_THEME) {
    //[FLEKSYTHEME.handler themeDidChange:(FLThemeType)FLEKSY_APP_SETTING_THEME];
    [[FLThemeManager sharedManager].handler themeDidChange:(FLThemeType)FLEKSY_APP_SETTING_THEME];
  }
  
  //NSLog(@"FleksyKeyboard handleSettingsChanged: %@", settings);
  
  /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  //now apply individual settings as necessary
  keyboardContainerView.alpha = FLEKSY_APP_SETTING_INVISIBLE_KEYBOARD ? INVISIBLE_ALPHA : 1;
  
  
  // DIRECT TOUCH
  self.isAccessibilityElement = YES;
  //NOTE: seems we cant have direct touch and elements hidden at the same time!
  self.accessibilityTraits |= UIAccessibilityTraitAllowsDirectInteraction /*| UIAccessibilityTraitSummaryElement*/; //summary is hint to default focus
  //self.accessibilityTraits |= UIAccessibilityTraitAdjustable;
  //  self.accessibilityLabel = @"Fleksy keyboard";
  //  self.accessibilityHint = @"You don't need to wait for feedback for every letter";
  
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < 7.0)
  {
    self.accessibilityHint = FLEKSY_ACTIVATE_KEYBOARD_WARNING;
  }
  
  //self.accessibilityViewIsModal = YES;
  // END DIRECT TOUCH
  
  //self.exclusiveTouch = YES;
  

  AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
  NSString* newFavorites = FLEKSY_APP_SETTING_SPEED_DIAL_1;
  if (![newFavorites isEqualToString:oldFavorites]) {
    NSLog(@"%s: favorites DID change in background (0) = %d", __PRETTY_FUNCTION__, [NSThread isMainThread]);
    [appDelegate.fleksyAppViewController performSelectorOnMainThread:@selector(reloadFavorites) withObject:nil waitUntilDone:YES];
  } else {
    //NSLog(@"favorites didn't change");
  }
  [appDelegate setProximityMonitoringEnabled:FLEKSY_APP_SETTING_RAISE_TO_SPEAK];

  
  //  if (FLEKSY_APP_SETTING_TOUCH_HOME) {
  //    [kbView->homeButtonTouchRecognizer start];
  //  } else {
  //    [kbView->homeButtonTouchRecognizer stop];
  //  }
  
  //keyboardContainerView->scrollWheelRecognizer.enabled = NO; //!FLEKSY_APP_SETTING_SPEAK;
  //NSLog(@"kbView->scrollWheelRecognizer.enabled: %d", kbView->scrollWheelRecognizer.enabled);
  
  [self setNeedsLayout];
  NSLog(@"FleksyKeyboard handleSettingsChanged: %@", settings);
  NSLog(@"END of handleSettingsChanged:, took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
#pragma unused(startTime)
}


- (UIResponder<UITextInput>*) currentResponder {
  return (UIResponder<UITextInput>*) [UIView findFirstResponder];
}


- (id) initWithFrame:(CGRect)frame {
  
  if (instance) {
    return instance;
  }
  
  if (self = [super initWithFrame:frame]) {
    // Initialization code
    //    self.backgroundColor = [UIColor greenColor];
    //    self.alpha = 0.5;
    
    NSLog(@"FleksyKeyboard initWithFrame: %@", NSStringFromCGRect(frame));
    
    
    keyboardContainerView = [FLKeyboardContainerView sharedFLKeyboardContainerView];
    [self addSubview:keyboardContainerView];
    
    swipeAndHoldRecognizer = [[UISwipeAndHoldGestureRecognizer alloc] initWithView:self target:keyboardContainerView action:@selector(handleSwipeAndHold:)];
    [swipeAndHoldRecognizer setRepeatDelay:0.3 repeatInterval:1.0 forDirection:UISwipeGestureRecognizerDirectionRight];
    //[swipeAndHoldRecognizer setRepeatDelay:0.6 repeatInterval:0.08 forDirection:UISwipeGestureRecognizerDirectionLeft]; // was faster for video
    [self addGestureRecognizer:swipeAndHoldRecognizer];
    
    
    feedbackRecognizer = [[FeedbackRecognizer alloc] initWithTarget:self action:@selector(handleFeedback:)];
    //feedbackRecognizer.delegate = keyboardContainerView;
    feedbackRecognizer.returnKeyLabel = @"\n";
#if USE_TOUCH_INTERCEPTOR
    [[FLTouchEventInterceptor sharedFLTouchEventInterceptor] addListener:feedbackRecognizer];
    [self addGestureRecognizer:[FLTouchEventInterceptor sharedFLTouchEventInterceptor]];
#else
    [self addGestureRecognizer:feedbackRecognizer];
#endif
    
    //also keep a reference here
    keyboardContainerView.feedbackRecognizer = feedbackRecognizer;
    
    if (!DEBUG_GESTURES) {
      UILongPressGestureRecognizer2* longPressRecognizer = [[UILongPressGestureRecognizer2 alloc] initWithTarget:self action:@selector(handleLongPressFrom:)];
      longPressRecognizer.numberOfTouchesRequired = 1;
      longPressRecognizer.minimumPressDuration = 0.35;
      if (deviceIsPad()) {
        longPressRecognizer.allowableMovement *= 1.8;
      }
      [keyboardContainerView addGestureRecognizer:longPressRecognizer];
      
      // without this we might get the same touch to be tagged and processed as long tap, and then as long swipe too!
      // still not sure why, but the following line guarantees it wont
      [swipeAndHoldRecognizer requireGestureRecognizerToFail:longPressRecognizer];
      
    } else {
      debugRecognizer = [[DebugGestureRecognizer alloc] initWithTarget:self action:@selector(nop:)];
      keyboardContainerView->debugRecognizer = debugRecognizer;
#if USE_TOUCH_INTERCEPTOR
      [[FLTouchEventInterceptor sharedFLTouchEventInterceptor] addListener:debugRecognizer];
      [self addGestureRecognizer:[FLTouchEventInterceptor sharedFLTouchEventInterceptor]];
#else
      [self addGestureRecognizer:debugRecognizer];
#endif
    }
    
    //    UIRotorRecognizer* rotor = [[UIRotorRecognizer alloc] initWithTarget:self action:@selector(rotorDetected:)];
    //    //rotor.delegate = (id<UIGestureRecognizerDelegate>) self;
    //    [self addGestureRecognizer:rotor];
    
    if (FLEKSY_FULLSCREEN) {
      
      actionRecognizer2Up = [[MySwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwipeUp:)];
      actionRecognizer2Up.numberOfTouchesRequired = 2;
      actionRecognizer2Up.direction = UISwipeGestureRecognizerDirectionUp;
      
      actionRecognizer2Down = [[MySwipeGestureRecognizer alloc] initWithTarget:self action:@selector(twoFingerSwipeDown:)];
      actionRecognizer2Down.numberOfTouchesRequired = 2;
      actionRecognizer2Down.direction = UISwipeGestureRecognizerDirectionDown;
      
      [self addGestureRecognizer:actionRecognizer2Up];
      [self addGestureRecognizer:actionRecognizer2Down];
      
      //[feedbackRecognizer requireGestureRecognizerToFail:actionRecognizer2Up];
      //[feedbackRecognizer requireGestureRecognizerToFail:actionRecognizer2Down];
      
      // for backwards compatibility, long tap high up will alert users of new method
      oldActionRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTapAboveKeyboard:)];
      oldActionRecognizer.numberOfTouchesRequired = 1;
      oldActionRecognizer.minimumPressDuration = 0.3;
      oldActionRecognizer.delaysTouchesBegan = YES;
      oldActionRecognizer.delegate = self;
      [self addGestureRecognizer:oldActionRecognizer];
    }
    
    
    //    for (int touchCount = 1; touchCount <= 4; touchCount++) {
    //      UITapGestureRecognizer2* tap = [[UITapGestureRecognizer2 alloc] initWithTarget:keyboardContainerView action:@selector(handleTapFrom2:)];
    //      tap.numberOfTouchesRequired = touchCount;
    //      tap.delegate = keyboardContainerView;
    //      [tap requireGestureRecognizerToFail:longPressRecognizer];
    //      [tap requireGestureRecognizerToFail:[swipeAndHoldRecognizer swipeRecognizerForDirection:UISwipeGestureRecognizerDirectionRight]];
    //      [tap requireGestureRecognizerToFail:[swipeAndHoldRecognizer swipeRecognizerForDirection:UISwipeGestureRecognizerDirectionLeft]];
    //    }
    
    
    ///////////////////////////////////////////////////////////////////////////
    spacebar = [UIButton buttonWithType:UIButtonTypeCustom];
    spacebarSeperator1 = [UIButton buttonWithType:UIButtonTypeCustom];
    spacebarSeperator2 = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [spacebar setTitle:@"space" forState:UIControlStateNormal];
    //[spacebar setTitleColor:[UIColor redColor] forState:UIControlEventTouchDown];
    //[spacebarSeperator1 setTitle:@"space" forState:UIControlStateNormal];
    //[spacebarSeperator1 setTitleColor:[UIColor colorWithWhite:0.4 alpha:1] forState:UIControlStateNormal];
    //[spacebarSeperator1 setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    //spacebarSeperator1.showsTouchWhenHighlighted = YES;
    //[spacebarSeperator2 setTitle:@">" forState:UIControlStateNormal];
    
    
    [self resetSpacebar:spacebar];
    [self resetSpacebar:spacebarSeperator1];
    [self resetSpacebar:spacebarSeperator2];
    
    //////////////////////////////////////////////////////////////////////////
    [spacebar addTarget:self action:@selector(handleSpacebarPress:) forControlEvents:UIControlEventTouchDown];
    [spacebar addTarget:self action:@selector(handleSpacebarRelease:) forControlEvents:UIControlEventTouchUpInside];
    [spacebar addTarget:self action:@selector(resetSpacebar:) forControlEvents:UIControlEventTouchDragExit];
    
    [spacebarSeperator1 addTarget:self action:@selector(handleSpacebarPress:) forControlEvents:UIControlEventTouchDown];
    [spacebarSeperator1 addTarget:self action:@selector(handleSpacebarRelease:) forControlEvents:UIControlEventTouchUpInside];
    [spacebarSeperator1 addTarget:self action:@selector(resetSpacebar:) forControlEvents:UIControlEventTouchDragExit];
    
    [spacebarSeperator2 addTarget:self action:@selector(handleSpacebarPress:) forControlEvents:UIControlEventTouchDown];
    [spacebarSeperator2 addTarget:self action:@selector(handleSpacebarRelease:) forControlEvents:UIControlEventTouchUpInside];
    [spacebarSeperator2 addTarget:self action:@selector(resetSpacebar:) forControlEvents:UIControlEventTouchDragExit];
    ///////////////////////////////////////////////////////////////////////////
    
    
    [keyboardContainerView.typingController setTextFieldDelegate:(id<MyTextField>)self];
    [VariousUtilities loadSettingsAndListen:self action:@selector(handleSettingsChanged:)];
    
    [UITouchManager initializeTouchManager];
    
    focusedCount = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged:) name:UIAccessibilityVoiceOverStatusChanged object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndo:) name:NSUndoManagerDidUndoChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadingProgress:) name:FLEKSY_LOADING_NOTIFICATION object:nil];
    hasFinishedLoading = NO;
    
    
    if (ALLOW_KB_FLICKUP_CHANGE) {
      [[FLKeyboardView sharedFLKeyboardView].panGestureRecognizer addTarget:self action:@selector(handlePanGesture:)];
    } else {
      [FLKeyboardView sharedFLKeyboardView].panGestureRecognizer.enabled = NO;
      [FLKeyboardView sharedFLKeyboardView].scrollEnabled = NO;
    }
    //[feedbackRecognizer requireGestureRecognizerToFail:[FLKeyboardView sharedFLKeyboardView].panGestureRecognizer];
    //[longPressRecognizer requireGestureRecognizerToFail:[Keyboard sharedKeyboard].panGestureRecognizer];
  }
  instance = self;
  return self;
}

- (void) nop:(id) object {
  NSLog(@"nop %@", object);
}

- (void) resetSpacebar:(UIView*) target {
  CGContextRef context = UIGraphicsGetCurrentContext();
  [UIView beginAnimations:nil context:context];
  [UIView setAnimationCurve:UIViewAnimationCurveLinear];
  [UIView setAnimationDuration:.1];
  target.backgroundColor =  [UIColor colorWithWhite:0 alpha:1];
  [UIView commitAnimations];
}

- (void) handleSpacebarRelease:(UIView*) target {
  if (target == spacebar) {
    [keyboardContainerView performSelector:@selector(handleSpacebarPress)];
  }
  [self resetSpacebar:target];
}

- (void) handleSpacebarPress:(UIView*) target {
  
  if (target == spacebar) {
    [VariousUtilities playTock];
    target.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1];
  }
  
  //  if (target == spacebarSeperator1) {
  //    [[FLKeyboardContainerView sharedFLKeyboardContainerView] handleSwipeDirection:UISwipeGestureRecognizerDirectionUp];
  //  }
  //  if (target == spacebarSeperator2) {
  //    [[FLKeyboardContainerView sharedFLKeyboardContainerView] handleSwipeDirection:UISwipeGestureRecognizerDirectionDown];
  //  }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  if (gestureRecognizer == oldActionRecognizer) {
    CGPoint location = [touch locationInView:self];
    int limit = self.bounds.size.height - self.activeHeight;
    BOOL result = location.y < limit;
    //NSLog(@"actionRecognizer shouldReceiveTouch %@, limit = %d, height = %.3f RESULT: %d", NSStringFromCGPoint(location), limit, self.height, result);
    return result;
  }
  NSLog(@"WARNING shouldReceiveTouch !actionRecognizer");
  return NO;
}

//- (void) singleTap:(UIGestureRecognizer*) gestureRecognizer {
//
//  NSLog(@"singleTap! %d", gestureRecognizer.state);
//
//  if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
//    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
//    [appDelegate speakCurrentText];
//  }
//}

- (void) didUndo:(NSNotification*) notification {
  NSLog(@"didUndo: %@", notification);
  [keyboardContainerView.typingController resetAndHideSuggestions];
}

- (void) twoFingerSwipeUp:(MySwipeGestureRecognizer*) gestureRecognizer {
  NSLog(@"twoFingerSwipeUp! %d, numberOfTouches: %d, location1: %@", gestureRecognizer.state, gestureRecognizer.numberOfTouches, NSStringFromCGPoint([gestureRecognizer locationInView:self]));
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    [[NSNotificationCenter defaultCenter] postNotificationName:FLEKSY_MENU_INVOKED_NOTIFICATION object:nil];
    for (UITouch* touch in gestureRecognizer.activeTouches) {
      touch.tag = UITouchTypeProcessedSwipe;
    }
    [feedbackRecognizer removePendingTouches];
  }
}

- (void) twoFingerSwipeDown:(MySwipeGestureRecognizer*) gestureRecognizer {
  NSLog(@"twoFingerSwipeDown! %d, numberOfTouches: %d, location1: %@", gestureRecognizer.state, gestureRecognizer.numberOfTouches, NSStringFromCGPoint([gestureRecognizer locationInView:self]));
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
    [keyboardContainerView performNewLine];
    for (UITouch* touch in gestureRecognizer.activeTouches) {
      touch.tag = UITouchTypeProcessedSwipe;
    }
    [feedbackRecognizer removePendingTouches];
  }
}


// old way for backwards compatibility
- (void) longTapAboveKeyboard:(UILongPressGestureRecognizer*) gestureRecognizer {
  
  NSLog(@"longTapAboveKeyboard! %d, numberOfTouches: %d, location1: %@",
        gestureRecognizer.state, gestureRecognizer.numberOfTouches, NSStringFromCGPoint([gestureRecognizer locationInView:self]));
  
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    [[NSNotificationCenter defaultCenter] postNotificationName:FLEKSY_MENU_INVOKED_NOTIFICATION object:nil];
  }
  
  if (gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
    [actionRecognizer2Up clearTouches];
    [actionRecognizer2Down clearTouches];
  }
}


- (BOOL) landscape {
  UIWindow* window = [[[UIApplication sharedApplication] windows] objectAtIndex:0];
  //BOOL result = UIInterfaceOrientationIsLandscape(FLEKSY_APP_SETTING_LOCK_ORIENTATION ? FLEKSY_APP_SETTING_LOCK_ORIENTATION : window.rootViewController.interfaceOrientation);
  //BOOL result = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);
  BOOL result = UIDeviceOrientationIsLandscape((UIDeviceOrientation) window.rootViewController.interfaceOrientation);
  //NSLog(@"FleksyKeyboard landscape: %d, device: %d, self.interface: %d, app.interface: %d, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d", result, [UIDevice currentDevice].orientation, self.window.rootViewController.interfaceOrientation, window.rootViewController.interfaceOrientation, FLEKSY_APP_SETTING_LOCK_ORIENTATION);
  return result;
}

- (float) activeHeight {
  
#ifndef __clang_analyzer__
  // Code not to be analyzed
  float result = [self landscape] ?
  FLEKSY_DEFAULT_HEIGHT_LANDSCAPE + FLEKSY_TOP_PADDING_LANDSCAPE : FLEKSY_DEFAULT_HEIGHT_PORTRAIT + FLEKSY_TOP_PADDING_PORTRAIT;
#endif
  
  
  if ([self landscape]) {
    result = FLEKSY_DEFAULT_HEIGHT_LANDSCAPE + FLEKSY_TOP_PADDING_LANDSCAPE;
  } else {
    result = FLEKSY_DEFAULT_HEIGHT_PORTRAIT + FLEKSY_TOP_PADDING_PORTRAIT;
  }
  //NSLog(@"FleksyKeyboard.height1: %.3f", result);
  result -= SPACEBAR_HEIGHT;
  //NSLog(@"FleksyKeyboard.height2: %.3f", result);
  return result;
}

- (float) visualHeight {
  float result = [self landscape] ? FLEKSY_DEFAULT_HEIGHT_LANDSCAPE : FLEKSY_DEFAULT_HEIGHT_PORTRAIT;
  return result;
}

- (void) layoutSubviews {
  NSLog(@"FleksyKeyboard layoutSubviews self.frame: %@", NSStringFromCGRect(self.frame));
  
  //  if (feedbackRecognizer.hoverMode) {
  //    // vertical align bottom
  //    keyboardContainerView.frame = CGRectMake(0, self.bounds.size.height - keyboardContainerView.frame.size.height, self.bounds.size.width, keyboardContainerView.frame.size.height);
  //  } else {
  //    keyboardContainerView.frame = self.bounds;
  //  }
  
  // vertical align bottom
  keyboardContainerView.frame = CGRectMake(0, self.bounds.size.height - self.activeHeight - SPACEBAR_HEIGHT, self.bounds.size.width, self.activeHeight /*+ SPACEBAR_HEIGHT*/ /* comment out +SH to allow spacebar at the bottom */);
  keyboardContainerView.backgroundColor = FLClearColor;
  
  if (FLEKSY_APP_SETTING_SPACE_BUTTON) {
    if (!spacebar.superview) {
      [self.window addSubview:spacebar];
      [self.window addSubview:spacebarSeperator1];
      [self.window addSubview:spacebarSeperator2];
    }
    float padding = deviceIsPad() ? 120 : 80;
    spacebar.frame = CGRectMake(padding, self.window.bounds.size.height - SPACEBAR_HEIGHT, keyboardContainerView.frame.size.width - 2 * padding, SPACEBAR_HEIGHT);
    spacebarSeperator1.frame = CGRectMake(0, self.window.bounds.size.height - SPACEBAR_HEIGHT, padding, SPACEBAR_HEIGHT);
    spacebarSeperator2.frame = CGRectMake(self.window.bounds.size.width-padding, self.window.bounds.size.height - SPACEBAR_HEIGHT, padding, SPACEBAR_HEIGHT);
  } else {
    [spacebar removeFromSuperview];
    [spacebarSeperator1 removeFromSuperview];
    [spacebarSeperator2 removeFromSuperview];
  }
  
  //NSLog(@"FleksyKeyboard layoutSubviews DONE");
  //NSLog(@"FLKeyboardContainerView.frame: %@", NSStringFromCGRect(keyboardContainerView.frame));
}

- (void) keyboardDidHide:(NSNotification*) notification {
  //NSLog(@"FleksyKeyboard keyboardDidHide");
}

- (void) keyboardDidShow:(NSNotification*) notification {
  // we cannot adjust activationPoint in layoutSubviews because that is called BEFORE the keboard
  // is animated into the screen. Also note that activationPoint is in SCREEN coordinates, not view
  // In keyboardDidShow the keyboard is already in place
  //NSLog(@"FleksyKeyboard keyboardDidShow, will adjust activation point");
  //  CGPoint originInScreen1 = self.accessibilityFrame.origin;
  //  CGPoint originInWindow1 = [self.window convertPoint:originInScreen1 fromWindow:nil]; //nil means screen
  //  CGPoint originInView1 = [self convertPoint:originInWindow1 fromView:self.window];
  //  NSLog(@"1 originInScreen: %@, originInWindow: %@, originInView: %@", NSStringFromCGPoint(originInScreen1), NSStringFromCGPoint(originInWindow1), NSStringFromCGPoint(originInView1));
  CGPoint originInView2 = FLEKSY_ACTIVATION_POINT;
  CGPoint originInWindow2 = [self convertPoint:originInView2 toView:self.window];
  CGPoint originInScreen2 = [self.window convertPoint:originInWindow2 toWindow:nil]; //nil means screen
  //NSLog(@"2 originInScreen: %@, originInWindow: %@, originInView: %@", NSStringFromCGPoint(originInScreen2), NSStringFromCGPoint(originInWindow2), NSStringFromCGPoint(originInView2));
  
  self.accessibilityActivationPoint = originInScreen2;
  //NSLog(@"FleksyKeyboard.accessibilityActivationPoint: %@, accessibilityFrame: %@, frame: %@", NSStringFromCGPoint(self.accessibilityActivationPoint), NSStringFromCGRect(self.accessibilityFrame), NSStringFromCGRect(self.frame));
}

- (void) voiceOverStatusChanged:(NSNotification*) notification {
  //[self setNeedsLayout];
  if (UIAccessibilityIsVoiceOverRunning()) {
    [self showEnabled:[self accessibilityElementIsFocused]];
  } else {
    [self showEnabled:YES];
  }
}


- (void) handleStringInput:(NSString*) s {
  UIResponder<UITextInput>* responder = self.currentResponder;
  [responder insertText:s];
  
  //marking text only works when not firsResponder...
  //[responder resignFirstResponder];
  //[responder setMarkedText:@" TESTING " selectedRange:NSMakeRange(0, 5)];
  
  //[self temporarilyEnlargeKeyboard];
  
  if ([s isEqualToString:@"\n"] && self.listener) {
    if ([self.listener respondsToSelector:@selector(enteredNewLine)]) {
      [self.listener enteredNewLine];
    }
  }
}

- (void) handleDelete:(int) n {
  id<UITextInput> responder = self.currentResponder;
  for (int i = 0; i < n; i++) {
    [responder deleteBackward];
  }
}

- (NSString*) handleReplaceRange:(NSRange) range withText:(NSString*) text {
  
  id<UITextInput> responder = self.currentResponder;
  // we need to keep the actual offset, not a UITextRange because that is a mutable reference
  int cursor = [responder offsetFromPosition:responder.beginningOfDocument toPosition:[responder selectedTextRange].start];
  
  // convert NSRange to UITextRange
  UITextPosition* start = [responder positionFromPosition:responder.beginningOfDocument offset:range.location];
  UITextPosition* end = [responder positionFromPosition:start offset:range.length];
  UITextRange* textRange = [responder textRangeFromPosition:start toPosition:end];
  NSString* oldText = [responder textInRange:textRange];
  
  // replace
  [responder replaceRange:textRange withText:text];
  
  // restore previous cursor position, otherwise cursor automatically goes to end of replaced range
  UITextPosition* newCursorPosition = [responder positionFromPosition:responder.beginningOfDocument offset:cursor + text.length - oldText.length];
  responder.selectedTextRange = [responder textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
  
  // used for sanity checks
  return oldText;
}

- (NSString*) text {
  
  id<UITextInput> responder = self.currentResponder;
  //NSLog(@"responder text3: <%@>", [responder textInRange:[responder textRangeFromPosition:responder.beginningOfDocument toPosition:responder.endOfDocument]]);
  
  
//#if FLEKSY_SDK
//  //NSLog(@"responder: %@, %@", [testView class], testView.subviews);
//  if ([responder isKindOfClass:NSClassFromString(@"UIWebBrowserView")]) {
//    UIView* testView = (UIView*) responder;
//    UIView* testSubView = [testView.subviews objectAtIndex:0];
//    //NSLog(@"testSubView: %@", testSubView);
//    responder = [[testSubView performSelector:@selector(selection)] performSelector:@selector(document)];
//    //NSLog(@"new responder: %@", responder);
//  }
//#endif
  
  
  UITextRange* range = [responder selectedTextRange];
  //NSLog(@"selectedTextRange: %@", range);
  if (range.isEmpty) {
    range = [responder textRangeFromPosition:responder.beginningOfDocument toPosition:range.start];
  }
  NSString* result = [responder textInRange:range];
  //NSLog(@"text: <%@>", result);
  //NSLog(@"responder text4: <%@>", [responder textInRange:[responder textRangeFromPosition:responder.beginningOfDocument toPosition:responder.endOfDocument]]);
  return result;
}

- (NSString*) textUpToCaret {
  return [self text];
}


- (void) rotorDetected:(UIRotorRecognizer*) rotorRecognizer {
  
  NSLog(@"rotorDetected, position: %d, previousPosition: %d", rotorRecognizer.position, rotorRecognizer.previousPosition);
  
  if (rotorRecognizer.position == 0) {
    [VariousUtilities performAudioFeedbackFromString:@"Letters"];
    [[FLKeyboardView sharedFLKeyboardView] resetWithActiveView:[FLKeyboardView sharedFLKeyboardView]->imageViewABC];
  }
  
  //if we switch to any keyboard FROM the letter keyboard
  if (rotorRecognizer.previousPosition == 0) {
    if ([FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.hasPendingPoints) {
      [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController nonLetterCharInput:' ' autocorrectionType:kAutocorrectionChangeAndSuggest];
    }
  }
  
  if (rotorRecognizer.position == 1) {
    [VariousUtilities performAudioFeedbackFromString:@"Symbols"];
    [[FLKeyboardView sharedFLKeyboardView] resetWithActiveView:[FLKeyboardView sharedFLKeyboardView]->imageViewSymbolsB];
  }
  
  if (rotorRecognizer.position == 2) {
    [VariousUtilities performAudioFeedbackFromString:@"Numbers"];
    [[FLKeyboardView sharedFLKeyboardView] resetWithActiveView:[FLKeyboardView sharedFLKeyboardView]->imageViewSymbolsA];
  }
  
}

- (void) handleFeedback:(FeedbackRecognizer*) recognizer {
  //NSLog(@"handleFeedback %@", [UIGestureUtilities getStateString:recognizer.state]);
}

- (int) testZZZ {
  NSLog(@"this is a test");
  [NSException raise:@"randomException" format:@""];
  return 1;
}

#define enlarge_height 80

- (void) temporarilyEnlargeKeyboard {
  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillChangeFrameNotification object:self];
  self.backgroundColor = [UIColor redColor];
  CGRect rect = self.frame;
  //CGRect rect = self.accessibilityFrame;
  self.frame              = CGRectMake(rect.origin.x, rect.origin.y - enlarge_height, rect.size.width, rect.size.height + enlarge_height);
  //self.accessibilityFrame = CGRectMake(rect.origin.x, rect.origin.y - enlarge_height, rect.size.width, rect.size.height + enlarge_height);
  MyAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  //MyAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidChangeFrameNotification object:self];
}

- (void) restoreKeyboardSize {
  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillChangeFrameNotification object:self];
  self.backgroundColor = FLClearColor;
  CGRect rect = self.frame;
  //CGRect rect = self.accessibilityFrame;
  self.frame = CGRectMake(rect.origin.x, rect.origin.y + enlarge_height, rect.size.width, rect.size.height - enlarge_height);
  //self.accessibilityFrame = CGRectMake(rect.origin.x, rect.origin.y + enlarge_height, rect.size.width, rect.size.height - enlarge_height);
  //MyAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  //MyAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardDidChangeFrameNotification object:self];
}

- (void) handleLongPressFrom:(UILongPressGestureRecognizer2*) recognizer {
  
  //NSLog(@"handleLongPressFrom, state = %d, allowableMovement: %.1f, minimumPressDuration: %.3f", recognizer.state, recognizer.allowableMovement, recognizer.minimumPressDuration);
  
  if (recognizer.state == UIGestureRecognizerStateBegan) {
    
    //show extra buttons
    [[FLKeyboardView sharedFLKeyboardView] enableQWERTYextraKeys];
    //scrollWheelRecognizer.state = UIGestureRecognizerStateFailed;
    [feedbackRecognizer startHover];
    
    //
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView hide];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
    
    //[self temporarilyEnlargeKeyboard];
    
    recognizer.myTag = [FLKeyboardView sharedFLKeyboardView].activeView.tag;
  }
  
  if (recognizer.state == UIGestureRecognizerStateChanged) {
    
  }
  
  if (recognizer.state == UIGestureRecognizerStateEnded) {
    
    if ([FLKeyboardView sharedFLKeyboardView].activeView.tag != recognizer.myTag) {
      NSLog(@"Long tap release on different keyboard than it started. Ignoring");
    } else {
      
      //NSLog(@"handleLongPressFrom, state = %d", recognizer.state);
      FLChar c = feedbackRecognizer.lastChar;
      assert(c);
      //CGPoint point = [recognizer locationInView:[FLKeyboardView sharedFLKeyboardView]];
      CGPoint point = [((KeyboardImageView*) [FLKeyboardView sharedFLKeyboardView].activeView) getKeyboardPointForChar:c];
      
      
      //    NSLog(@"f.lastChar: %d @ %@", c, NSStringFromCGPoint(point));
      //    FLChar c2 = [((KeyboardImageView*) [FLKeyboardView sharedFLKeyboardView].activeView) getNearestCharForPoint:point];
      //    NSLog(@"c: %C, c2: %C, point: %@, activeView: %@", c, c2, NSStringFromCGPoint(point), [FLKeyboardView sharedFLKeyboardView].activeView);
      assert(c == [((KeyboardImageView*) [FLKeyboardView sharedFLKeyboardView].activeView) getNearestCharForPoint:point]);
      //assert([self testZZZ]);
      
      [VariousUtilities playTock];
      
      [keyboardContainerView processTouchPoint:point precise:YES character:c];
      
      //[self restoreKeyboardSize];
    }
  }
  
  if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
    [[FLKeyboardView sharedFLKeyboardView] disableQWERTYextraKeys];
    [actionRecognizer2Up clearTouches];
    [actionRecognizer2Down clearTouches];
  }
  
}

- (void) showEnabled:(BOOL) enabled {
  keyboardContainerView.alpha = enabled ? 1 : 0.5;
}

// Override the following methods to know when an assistive technology has set or unset its virtual focus on the element.
- (void) accessibilityElementDidBecomeFocused {
  NSLog(@"FleksyKeyboard accessibilityElementDidBecomeFocused");
  focusedCount++;
  if (focusedCount > 2) {
    self.accessibilityHint = nil;
  }
  [self showEnabled:YES];
}

- (void) accessibilityElementDidLoseFocus {
  NSLog(@"FleksyKeyboard accessibilityElementDidLoseFocus");
  [self showEnabled:NO];
}

- (void)accessibilityIncrement {
  NSLog(@"FleksyKeyboard accessibilityIncrement");
}

- (void)accessibilityDecrement {
  NSLog(@"FleksyKeyboard accessibilityDecrement");
  
  char newLine = '\n';
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController nonLetterCharInput:newLine autocorrectionType:kAutocorrectionChangeAndSuggest];
  [VariousUtilities performAudioFeedbackFromString:[VariousUtilities descriptionForCharacter:newLine]];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  NSLog(@"FleksyKeyboard accessibilityScroll: %d", direction);
  return YES;
}

- (BOOL)accessibilityPerformEscape {
  NSLog(@"FleksyKeyboard accessibilityPerformEscape");
  return YES;
}


- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  NSLog(@"touches began FleksyKeyboard! %d", touches.count);
  //[keyboardContainerView.typingController playError];
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesMoved:touches withEvent:event];
  //NSLog(@"touches moved FleksyKeyboard! %@", touches);
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesEnded:touches withEvent:event];
  NSLog(@"touches ended FleksyKeyboard! %@", touches);
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesCancelled:touches withEvent:event];
  NSLog(@"touches cancelled FleksyKeyboard! %@", touches);
}



/// UIWebView hack/support

- (UIView*) UIWebBrowserView_inputView {
  //  UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
  //  view.backgroundColor = [UIColor blackColor];
  
  NSLog(@"UIWebBrowserView_inputView called");
  FleksyKeyboard* view = [[FleksyKeyboard alloc] initWithFrame:CGRectMake(0, 0, 320, 216)];
  return view;
}

- (UIView*) UIWebBrowserView_inputAccessoryView {
  return nil;
}

/////////////////////////////////////////

- (BOOL) speakWords {
  return FLEKSY_APP_SETTING_SPEAK;
}

- (void) setSpeakWords:(BOOL) speakWords {
  FLEKSY_APP_SETTING_SPEAK = speakWords;
  //[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:speakWords] forKey:@"FLEKSY_APP_SETTING_SPEAK"];
  //[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) loadingProgress:(NSNotification*) notification {
  NSLog(@"Handling Notification %@ NOW on Thread = %@", notification, [NSThread currentThread]);
  NSNumber* progress = notification.object;
  if (progress.floatValue == 1) {
    self->hasFinishedLoading = YES;
  }
  if ([self.listener respondsToSelector:@selector(loadingProgress:)]) {
    NSLog(@"Passing Notification Handling to listener %@ NOW", self.listener);
    [self.listener loadingProgress:progress.floatValue];
  }
}

- (BOOL) hasFinishedLoading {
  return self->hasFinishedLoading;
}

- (void) startLoading {
  self->hasFinishedLoading = NO;
  [keyboardContainerView.typingController forceLoad];
}

+ (void) enableFleksyForWebViews {
  if (webviewSupportEnabled) {
    NSLog(@"webview support already enabled");
    return;
  }
  [[HookingUtilities sharedHookingUtilities] swapMethodNamed:@"inputView" inClassNamed:@"UIWebBrowserView" withCustomMethodNamed:@"UIWebBrowserView_inputView" inClassNamed:@"FleksyKeyboard"];
  [[HookingUtilities sharedHookingUtilities] swapMethodNamed:@"inputAccessoryView" inClassNamed:@"UIWebBrowserView" withCustomMethodNamed:@"UIWebBrowserView_inputAccessoryView" inClassNamed:@"FleksyKeyboard"];
  webviewSupportEnabled = YES;
  NSLog(@"webview support enabled");
}


//- (void) setListener:(id<FleksyKeyboardListener>) theListener {
//  listener = theListener;
//  if ([self accessibilityElementIsFocused]) {
//    [self accessibilityElementDidBecomeFocused];
//  } else {
//    [self accessibilityElementDidLoseFocus];
//  }
//}

- (void) setReturnKeyLabel:(NSString *)returnKeyLabel {
  feedbackRecognizer.returnKeyLabel = returnKeyLabel;
}

- (NSString*) returnKeyLabel {
  return feedbackRecognizer.returnKeyLabel;
}


//@synthesize KEYBOARD_HEIGHT_PORTRAIT;
//@synthesize KEYBOARD_HEIGHT_LANDSCAPE;

@end
