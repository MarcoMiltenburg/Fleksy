//
//  AppDelegate+Theme.h
//  iFleksy
//
//  Created by Vince Mansel on 7/6/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate (Theme) <FLThemeChangeHandler>

- (id)themeWithHandler:(id)handler withType:(FLThemeType)themeType;

@end
