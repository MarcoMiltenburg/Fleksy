//
//  CircleUIView.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 9/3/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "CircleUIView.h"
#import <QuartzCore/QuartzCore.h>

@implementation CircleUIView

- (void) setRadius: (float) radius {
  CGPoint saveCenter = self.center;
  CGRect newFrame = CGRectMake(self.frame.origin.x, self.frame.origin.y, radius * 2, radius * 2);
  self.frame = newFrame;
  self.layer.cornerRadius = radius;
  self.center = saveCenter;
}

- (float) radius {
  return self.frame.size.width * 0.5;
}

@end
