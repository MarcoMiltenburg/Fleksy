//
//  MySwipeGestureRecognizer.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 10/18/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

// simply add currentLocationInView to get swipe "endpoint"
// UISwipeGestureRecognizer only provides startpoint
// Note: current != end point

@interface MySwipeGestureRecognizer : UISwipeGestureRecognizer {
  NSMutableSet* _activeTouches;
  BOOL clearTouches;
}

- (CGPoint) currentLocationInView:(UIView*) view;
- (void) clearTouches;

@property (readonly) NSSet* activeTouches;

@end
