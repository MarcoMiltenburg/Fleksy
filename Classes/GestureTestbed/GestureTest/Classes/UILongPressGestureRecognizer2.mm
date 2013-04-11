//
//  UILongPressGestureRecognizer2.mm
//  iFleksy
//
//  Created by Kostas Eleftheriou on 2/21/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "UILongPressGestureRecognizer2.h"

@implementation UILongPressGestureRecognizer2

- (id)initWithTarget:(id)target action:(SEL)action { // default initializer
  
  if (self = [super initWithTarget:target action:action]) {
    self.myTag = -1;  
  }
  return self;
}

@synthesize myTag = _myTag;

@end
