//
//  UITapGestureRecognizer2.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/11/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UITapGestureRecognizer.h>

//Drop-in replacement for UITapGestureRecognizer to ensure touches are returned in
//order when using the [locationOfTouch:(NSUInteger)touchIndex inView:(UIView*)view]

@interface UITapGestureRecognizer2 : UITapGestureRecognizer {
}

- (NSArray*) orderedTouches;

@end
