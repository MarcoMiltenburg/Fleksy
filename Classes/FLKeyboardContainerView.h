//
//  FLKeyboardContainerView.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/23/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FLTypingController_iOS.h"
//#import "FLTypingController.h"
#import "FLKeyboard.h"

//#import "UICustomTapGestureRecognizer.h"
#import "UISwipeAndHoldGestureRecognizer.h"
//#import "ScrollWheelGestureRecognizer.h"
//#import "HomeButtonTouchRecognizer.h"
#import "FeedbackRecognizer.h"
#import "SwipeFeedbackView.h"
#import "DebugGestureRecognizer.h"


#define FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPHONE 244
#define FLEKSY_DEFAULT_HEIGHT_LANDSCAPE_IPHONE FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPHONE
#define FLEKSY_TOP_PADDING_PORTRAIT_IPHONE (FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPHONE / 3)
#define FLEKSY_TOP_PADDING_LANDSCAPE_IPHONE 0
#define FLEKSY_SUGGESTIONS_HEIGHT_IPHONE 25

// 1.5 -> 1.1 for same height as default portrait iPad keyboard
#define FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPAD (FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPHONE * 1.5)
#define FLEKSY_DEFAULT_HEIGHT_LANDSCAPE_IPAD FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPAD
#define FLEKSY_TOP_PADDING_PORTRAIT_IPAD (FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPAD / 3)
#define FLEKSY_TOP_PADDING_LANDSCAPE_IPAD FLEKSY_TOP_PADDING_PORTRAIT_IPAD
#define FLEKSY_SUGGESTIONS_HEIGHT_IPAD (FLEKSY_SUGGESTIONS_HEIGHT_IPHONE * 1.5)



#define FLEKSY_DEFAULT_HEIGHT_LANDSCAPE (deviceIsPad() ? FLEKSY_DEFAULT_HEIGHT_LANDSCAPE_IPAD : FLEKSY_DEFAULT_HEIGHT_LANDSCAPE_IPHONE)
#define FLEKSY_DEFAULT_HEIGHT_PORTRAIT  (deviceIsPad() ? FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPAD  : FLEKSY_DEFAULT_HEIGHT_PORTRAIT_IPHONE)
#define FLEKSY_TOP_PADDING_LANDSCAPE    (deviceIsPad() ? FLEKSY_TOP_PADDING_LANDSCAPE_IPAD    : FLEKSY_TOP_PADDING_LANDSCAPE_IPHONE)
#define FLEKSY_TOP_PADDING_PORTRAIT     (deviceIsPad() ? FLEKSY_TOP_PADDING_PORTRAIT_IPAD     : FLEKSY_TOP_PADDING_PORTRAIT_IPHONE)
#define FLEKSY_SUGGESTIONS_HEIGHT       (deviceIsPad() ? FLEKSY_SUGGESTIONS_HEIGHT_IPAD       : FLEKSY_SUGGESTIONS_HEIGHT_IPHONE)


#define FLEKSY_KEYBOARD_CLICKED_NOTIFICATION @"FLEKSY_KEYBOARD_CLICKED_NOTIFICATION"
#define FLEKSY_MENU_INVOKED_NOTIFICATION @"FLEKSY_MENU_INVOKED_NOTIFICATION"

@interface FLKeyboardContainerView : UIView <UIGestureRecognizerDelegate> {
  // Where to pass all typing related events.
  FLTypingController_iOS* typingController;
  
  //FLTypingController* typingControllerGeneric;
  
  FLKeyboard* keyboard;
  FLSuggestionsView* suggestionsView;
  FLSuggestionsView* suggestionsViewSymbols;
  
  UIView* topShadowView;
  
  //UICustomTapGestureRecognizer* customTapRecognizer;
  SwipeFeedbackView* feedbackView;
  
  double lastActivationPointTap;
  
@public
  //ScrollWheelGestureRecognizer* scrollWheelRecognizer;
  //HomeButtonTouchRecognizer* homeButtonTouchRecognizer;
  DebugGestureRecognizer* debugRecognizer;
}

// Accessor function for the instance
+ (FLKeyboardContainerView *) sharedFLKeyboardContainerView;

- (void) performNewLine;
- (void) handleSwipeDirection:(UISwipeGestureRecognizerDirection) direction fromTouch:(UITouch*) touch caller:(NSString*) caller;
- (void) processTouchPoint:(CGPoint) point precise:(BOOL) precise character:(unichar) c;
- (void) reset;

@property (readonly) FLTypingController_iOS* typingController;
@property (readonly) FLSuggestionsView* suggestionsView;
@property (readonly) FLSuggestionsView* suggestionsViewSymbols;
@property FeedbackRecognizer* feedbackRecognizer;

@end