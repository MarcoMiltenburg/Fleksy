//
//  FLSwipeStatisticalAnalyzer.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 11/7/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FLSwipeStatisticalAnalyzer : NSObject {

  UISwipeGestureRecognizerDirection direction;
  float totalSwipeDistance;
  int numberOfSwipes;
  CGPoint averageSlope;
  
}

- (id) initWithDirection:(UISwipeGestureRecognizerDirection) _direction;
- (void) touchEndedWithSwipe:(UITouch*) touch;
- (void) enable;

@property (readonly) float averageDistance;
@property (readonly) float effectiveThreshold;
@property (readonly) UISwipeGestureRecognizerDirection direction;
@property BOOL enabled;

@end
