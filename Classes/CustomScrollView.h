//
//  CustomScrollView.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/23/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#define BOTTOM_GRAB_HEIGHT 18
#define BOTTOM_GRAB_WIDTH 70

@interface CustomScrollView : UIScrollView<UIScrollViewDelegate> {
@private
  UIView* view1;
  UIView* view2A;
  UIView* view2B;
  
  UIView* activeView;
  UIView* incomingView;
}


- (id) initWithFrame:(CGRect) frame view1:(UIView*) v1 view2A:(UIView*) v2a view2B:(UIView*) v2b;
- (void) resetWithActiveView:(UIView*) view;
- (void) reset;

@property (weak, readonly) UIView* activeView;

@end
