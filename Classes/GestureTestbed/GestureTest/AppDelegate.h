//
//  AppDelegate.h
//  GestureTest
//
//  Created by Kostas Eleftheriou on 10/30/12.
//  Copyright (c) 2012 Kostas Eleftheriou. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
  UIButton* greenSwipeButton;
  UIButton* redSwipeButton;
  UILabel* label;
}

- (void) setLabel:(NSString*) text;
- (void) setSwipeOk:(BOOL) swipeOK;
- (void) setPassedTest:(BOOL) passedTest;

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
