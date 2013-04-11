//
//  UIView+Extensions.mm
//  Fleksy
//
//  Created by Kosta Eleftheriou on 4/10/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "UIView+Extensions.h"

//used to simply cache the last result
static UIView* lastKnownFirstResponder = nil;


@implementation UIView (FleksyAdditions)
- (UIView*) findFirstResponder {
  if (self.isFirstResponder) {
    return self;
  }
  for (UIView* subView in self.subviews) {
    UIView* r = [subView findFirstResponder];
    if (r) {
      return r;
    }
  }
  return nil;
}

+ (UIView*) findFirstResponder {
  
  if (lastKnownFirstResponder && [lastKnownFirstResponder isFirstResponder]) {
    return lastKnownFirstResponder;
  }
  
  //double startTime = CFAbsoluteTimeGetCurrent();
  //NSLog(@"recalculating lastKnownFirstResponder");
  UIView* result = [[UIApplication sharedApplication].keyWindow findFirstResponder];
  //NSLog(@"findFirstResponder took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
  lastKnownFirstResponder = result;
  return result;
}

- (void) removeAllSubviews {
  while (self.subviews.count){
    [self.subviews[0] removeFromSuperview];
  }
}

@end