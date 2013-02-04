//
//  SwipeFeedbackView.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 2/23/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIGestureUtilities.h"

@interface SwipeFeedbackView : UIView {
  
  BOOL swipeRecognized;
  UIView* staticSubview;
  
}

- (void) prepareWithTouch:(UITouch*) touch;
//- (void) touchMoved:(UITouch*) touch;
- (void) swipeRecognized:(UISwipeGestureRecognizerDirection) direction padding:(BOOL) padding;
- (void) dismiss;


@end
