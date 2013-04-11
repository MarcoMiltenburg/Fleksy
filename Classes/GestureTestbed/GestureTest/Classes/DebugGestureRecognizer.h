//
//  DebugGestureRecognizer.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 10/29/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLTouch.h"

#define DEBUG_GESTURES 0

@interface DebugGestureRecognizer : UIGestureRecognizer {
  NSMutableDictionary* points;
  UITouch* lastTouch;
  
  NSMutableArray* storedOKSwipes;
  NSMutableArray* storedErrorSwipes;
  
  NSMutableArray* oddTouches;
  NSMutableArray* evenTouches;
  
  
  UIView* target;
}

- (void) showTouch:(FLTouch*) touch inView:(UIView*) view;
- (void) clear:(UIView*) view;

+ (DebugGestureRecognizer*) sharedDebugGestureRecognizer;

@property BOOL clearBeforeNextTouch;

@end
