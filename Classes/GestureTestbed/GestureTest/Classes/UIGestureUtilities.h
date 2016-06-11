//
//  UIGestureUtilities.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/30/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define UISwipeGestureRecognizerDirectionNone 9999

@interface UIGestureUtilities : NSObject

+ (NSString*) getStateString:(UIGestureRecognizerState) state;
+ (NSString*) getDirectionString:(UISwipeGestureRecognizerDirection) direction;

@end
