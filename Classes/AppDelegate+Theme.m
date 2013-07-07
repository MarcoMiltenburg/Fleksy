//
//  AppDelegate+Theme.m
//  iFleksy
//
//  Created by Vince Mansel on 7/6/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "AppDelegate+Theme.h"
#import "FLTheme.h"
#import "FLThemeVanilla.h"
#import "FLThemeNightLight.h"

@implementation AppDelegate (Theme)

- (id)themeWithHandler:(id)handler withType:(FLThemeType)themeType {
//  FLTheme *aTheme = [FLTheme theme];
//  aTheme.currentThemeType = themeType;
//  aTheme.handler = handler;
//  return aTheme;
  return [self newTheme:@"FLTheme" withHandler:handler withType:themeType];
}

- (id)newTheme:(NSString *)className withHandler:(id)handler withType:(FLThemeType)themeType {
  FLTheme *aTheme = [NSClassFromString(className) theme];
  aTheme.currentThemeType = themeType;
  aTheme.handler = handler;
  return aTheme;
}

- (void)themeDidChange:(FLThemeType)newTheme {
  
  switch (newTheme) {
    case FLThemeTypeNormal:
      self.theme = [self newTheme:@"FLTheme" withHandler:self withType:FLThemeTypeNormal];
      break;
      
    case FLThemeTypeVanilla:
      self.theme = [self newTheme:@"FLThemeVanilla" withHandler:self withType:FLThemeTypeVanilla];
      break;
      
    case FLThemeTypeNightLight:
      self.theme = [self newTheme:@"FLThemeNightLight" withHandler:self withType:FLThemeTypeNightLight];
      break;
      
    default:
      NSLog(@"Error FLThemeType out of range");
      assert(0);
      break;
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksyThemeDidChangeNotification object:self.theme];
}

@end
