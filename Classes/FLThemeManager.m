//
//  FLThemeManager.m
//  iFleksy
//
//  Created by Vince Mansel on 7/7/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLThemeManager.h"
#import "FLThemeVanilla.h"
#import "FLThemeNightLight.h"
#import "FLThemeMidnight.h"

NSString * const FleksyThemeDidChangeNotification = @"FleksyThemeDidChangeNotification";

@interface FLThemeManager ()

@property (strong, nonatomic) FLTheme *currentTheme;

- (id)themeWithHandler:(id)handler withType:(FLThemeType)themeType;

@end

static FLThemeManager *themeManager;

@implementation FLThemeManager



+ (FLThemeManager *)sharedManager {
  
  if (!themeManager) {
    themeManager = [[FLThemeManager alloc] init];
    
    themeManager.currentTheme = [themeManager themeWithHandler:self withType:FLThemeTypeNormal];
    
  }
  return themeManager;
}

- (FLTheme *)currentTheme {
  return _currentTheme;
}

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
  self.handler = handler;
  return aTheme;
}


#pragma mark - FLThemeChangeHandler Methods

- (void)themeDidChange:(FLThemeType)newTheme {
  
  switch (newTheme) {
    case FLThemeTypeNormal:
      self.currentTheme = [self newTheme:@"FLTheme" withHandler:self withType:FLThemeTypeNormal];
      break;
      
    case FLThemeTypeVanilla:
      self.currentTheme = [self newTheme:@"FLThemeVanilla" withHandler:self withType:FLThemeTypeVanilla];
      break;
      
    case FLThemeTypeNightLight:
      self.currentTheme = [self newTheme:@"FLThemeNightLight" withHandler:self withType:FLThemeTypeNightLight];
      break;
      
    case FLThemeTypeMidnight:
      self.currentTheme = [self newTheme:@"FLThemeMidnight" withHandler:self withType:FLThemeTypeMidnight];
      break;
      
    default:
      NSLog(@"Error FLThemeType out of range");
      assert(0);
      break;
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksyThemeDidChangeNotification object:self.currentTheme];
}

+ (void)themeDidChange:(FLThemeType)newTheme {
  
  [themeManager themeDidChange:newTheme];
  return;
}


@end
