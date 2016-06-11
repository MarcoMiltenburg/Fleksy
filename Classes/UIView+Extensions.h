//
//  UIView+Extensions.h
//  Fleksy
//
//  Created by Kosta Eleftheriou on 4/10/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (FleksyAdditions)
- (UIView*) findFirstResponder;
+ (UIView*) findFirstResponder;

- (void) removeAllSubviews;
@end