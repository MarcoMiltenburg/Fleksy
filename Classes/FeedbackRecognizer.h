//
//  FeedbackRecognizer.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/13/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>
#import "FLSwipeStatisticalAnalyzer.h"

// (0, 0) does not seem to always work...
#define FLEKSY_ACTIVATION_POINT CGPointMake(1, 0)

// we split this on its own interface so we can use [NSObject cancelPreviousPerformRequestsWithTarget:xxx]
// and isolate it to NATO calls only
@interface FeedbackNATO : NSObject
- (void) speakNATOforChar:(NSString*) charString;
@end

@interface FeedbackRecognizer : UIGestureRecognizer<UIGestureRecognizerDelegate> {
  FeedbackNATO* nato;
  BOOL hoverMode;
  UITouch* lastTouchDown;
  double lastTouchUpTime;
  unichar lastChar;
  unichar pendingChar;
  NSMutableArray* currentTouches;
  
  NSMutableDictionary* swipeAnalyzers;
}

- (void) startHover;
- (void) stopHover;

// when we detect a swipe, since this class only deals with taps, make sure we cancel this potentially pending touch
// TODO: also long tap detection
- (void) stopTrackingTouch:(UITouch*) touch;

@property (readonly) unichar lastChar;
@property (readonly) BOOL hoverMode;
@property (readwrite) NSString* returnKeyLabel;

@end
