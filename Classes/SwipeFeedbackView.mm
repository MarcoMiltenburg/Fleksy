//
//  SwipeFeedbackView.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 2/23/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "SwipeFeedbackView.h"
#import "UITouchManager.h"
#import "MathFunctions.h"
#import "FLThemeManager.h"


@implementation SwipeFeedbackView

- (id) init {
    self = [super init];
    if (self) {
      
      //self.hidden = YES;
      self.alpha = 1;
      self.userInteractionEnabled = NO;
      
      staticSubview  = [[UIView alloc] init];
      [self addSubview:staticSubview];
    }
    return self;
}

- (void) prepareWithTouch:(UITouch*) touch {
  swipeRecognized = NO;
  //self.backgroundColor = [UIColor clearColor];
  //touchView.hidden = YES;
  //self.center = [touch locationInView:self.superview];
  //[[Keyboard sharedKeyboard] sendSubviewToBack:staticView];
}

- (void) animationDidStop {
  
  BOOL previousAnimationsState = [UIView areAnimationsEnabled];
  [UIView setAnimationsEnabled:YES];
  [UIView animateWithDuration:0.35
                        delay:0.2
                      options: UIViewAnimationOptionCurveEaseIn
                   animations:^{
                     self.backgroundColor = FLClearColor;
                   }
                   completion:^(BOOL finished){
                     //even though this might be off screen, when we switch from portrait to landscape
                     //we might see it hanging on the side. We could either do something in layoutSubviews 
                     //or just hide it here
                     staticSubview.hidden = YES;
                   }];
  
  [UIView setAnimationsEnabled:previousAnimationsState];
}

- (void) swipeRecognized:(UISwipeGestureRecognizerDirection) direction padding:(BOOL) padding {
  swipeRecognized = YES;
  
  float width = self.bounds.size.width;
  float height = self.bounds.size.height;
  
  staticSubview.hidden = NO;
  staticSubview.frame = CGRectMake(0, 0, width, height);
  //TODO: Theme Vanilla
  staticSubview.backgroundColor  = FLEKSYTHEME.swipeFeedbackView_staticSubview_backgroundColor;

  self.backgroundColor = padding ? FLClearColor : FLClearColor;
  
//  switch (direction) {
//    case UISwipeGestureRecognizerDirectionRight:
//      staticSubview.backgroundColor  = [UIColor colorWithRed:0 green:0.5 blue:0 alpha:0.5];
//      break;
//    case UISwipeGestureRecognizerDirectionLeft:
//      staticSubview.backgroundColor  = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:0.5];
//      break;
//    default:
//      break;
//  }
 
  BOOL previousAnimationsState = [UIView areAnimationsEnabled];
  [UIView setAnimationsEnabled:YES];
  [UIView animateWithDuration:0.22
                        delay: 0.0
                      options: UIViewAnimationOptionCurveEaseInOut
                   animations:^{
                     switch (direction) {
                       case UISwipeGestureRecognizerDirectionRight:
                         staticSubview.frame = CGRectMake(width, 0, width, height);
                         break;
                       case UISwipeGestureRecognizerDirectionLeft:
                         staticSubview.frame = CGRectMake(-width, 0, width, height);
                         break;
                       default:
                         break;
                     }
                   }
                   completion:^(BOOL finished){
                     [self animationDidStop];
                   }];
  
  [UIView setAnimationsEnabled:previousAnimationsState];
}

- (void) dismiss {
  //self.hidden = YES;
  if (!swipeRecognized) {
    //staticSubView.hidden = YES;
  }
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect2:(CGRect)rect {
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  UIGraphicsPushContext(ctx);
  //CGContextSetFillColorWithColor(ctx, [touchView.backgroundColor CGColor]);
  CGContextFillEllipseInRect(ctx, self.bounds);
  UIGraphicsPopContext();
}

@end
