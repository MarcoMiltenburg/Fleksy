//
//  FLThemeManager.h
//  iFleksy
//
//  Created by Vince Mansel on 7/7/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLTheme.h"

#define FLEKSYTHEME [[FLThemeManager sharedManager] currentTheme]

@protocol FLThemeChangeHandler <NSObject>
/**
 *
 * Indicate that the theme has changed
 * Whichever class handles theme changes shall send this message to whichever object holds the theme object
 *
 */
@optional
- (void)themeDidChange:(FLThemeType)newTheme;
+ (void)themeDidChange:(FLThemeType)newTheme;

@end

@interface FLThemeManager : NSObject <FLThemeChangeHandler>

+  (FLThemeManager *)sharedManager;
- (FLTheme *)currentTheme;

@property (assign, nonatomic) id<FLThemeChangeHandler> handler;

@end

#pragma mark - Notificaition

extern NSString * const FleksyThemeDidChangeNotification;
