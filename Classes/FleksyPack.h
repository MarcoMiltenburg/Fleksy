//
//  FleksyPack.h
//  iFleksy
//
//  Created by Vince Mansel on 3/26/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FleksyAppMainViewController.h"
#import "FleksyKeyboard.h"
#import "FleksyTextView.h"
//#import "FLUserDictionary.h"

#define LOAD_SERVER YES

@interface FleksyPack : NSObject <FleksyKeyboardListener>
{
    FleksyAppMainViewController* fleksyAppViewController;
    FleksyTextView* textView;
    FleksyKeyboard* customInputView;
    
    NSTimer* loadingTimer;

    BOOL lastKnownVoiceOverState;
}

+ (id) sharedFleksyPack;
- (void) setupViewController:(FleksyAppMainViewController *)fleksyAppViewController inWindow:(UIWindow *)aWindow;
+ (void) setProximityMonitoringEnabled:(BOOL) b;
- (void) speakCurrentText;
- (BOOL) handleOpenURL:(NSURL *)url;

- (void)applicationWillResignActive;
- (void)applicationWillEnterForeground;
- (void)applicationDidEnterForeground;
- (void)applicationDidBecomeActive;

@property (strong, nonatomic) UIViewController *fleksyAppViewController;

@end
