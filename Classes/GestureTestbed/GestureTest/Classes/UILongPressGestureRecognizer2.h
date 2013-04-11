//
//  UILongPressGestureRecognizer2.h
//  iFleksy
//
//  Created by Kostas Eleftheriou on 2/21/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import <UIKit/UILongPressGestureRecognizer.h>

//Drop-in replacement for UILongPressGestureRecognizer2 with added tag

@interface UILongPressGestureRecognizer2 : UILongPressGestureRecognizer {
  int _myTag;
}

@property int myTag;

@end
