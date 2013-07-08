//
//  CustomScrollView.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/23/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "CustomScrollView.h"
#import "Settings.h"
#import "FLTheme.h"

#define USE_ZOOM_OUT_EFFECT YES

@implementation CustomScrollView

- (id) initWithFrame:(CGRect) frame view1:(UIView*) v1 view2A:(UIView*) v2a view2B:(UIView*) v2b {
  
  if (self = [super initWithFrame:frame]) {
    
    view1 = v1;
    view2A = v2a;
    view2B = v2b;
    
    [self addSubview:view1];
    [self addSubview:view2A];
    [self addSubview:view2B];
    
    activeView = v1;
    view2A.alpha = 0;
    view2B.alpha = 0;
    
    //self.backgroundColor = [UIColor redColor];
    //self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height * 2);
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.bounces = NO;
    self.delegate = self;
    //self.decelerationRate = UIScrollViewDecelerationRateFast;
    
    [self.panGestureRecognizer setMinimumNumberOfTouches:1];
    [self.panGestureRecognizer setMaximumNumberOfTouches:1];
    
    self.delaysContentTouches = NO;
    self.panGestureRecognizer.delaysTouchesBegan = NO;
    
    //NSLog(@"panGestureRecognizer %@", self.panGestureRecognizer);
    
    self.multipleTouchEnabled = YES;
    self.clipsToBounds = NO; //for top row key popups
    
  }
  
  return self;
}

//override this to only allow pan if drag began at the very bottom of our view
//NOTE: this only receives the starting touch events, not the moving ones, so 
//we cant monitor if we get near the top here
- (BOOL) gestureRecognizer:(UIGestureRecognizer*) gestureRecognizer shouldReceiveTouch:(UITouch*) touch {
  
  //This method will be called not just for the UIScrollViewPanGestureRecognizer, but also for the
  //UIScrollViewDelayedTouchesBeganGestureRecognizer and UIScrollViewPagingSwipeGestureRecognizer of 
  //this view. We need to tell the system we wont handle the delayed touches so that they will fall back
  //to our view
  //NSLog(@"shouldReceiveTouch %@", gestureRecognizer);
  if (gestureRecognizer != self.panGestureRecognizer) {
    //NSLog(@"1111");
    return NO;
  }
  
  if (gestureRecognizer.numberOfTouches >= 1) {
    //NSLog(@"2222");
    return NO;
  }
  
  //we use the superview here so even if we are transformed / squeezed / shifted it will be consistent
  int maxY = self.superview.frame.size.height - BOTTOM_GRAB_HEIGHT;
  CGPoint point = [touch locationInView:self.superview];
  //NSLog(@">>>> gestureRecognizer shouldReceiveTouch y: %.1f, height: %.1f, maxY: %d", point.y, self.superview.frame.size.height, maxY);
  BOOL result = point.y > maxY;

  if (result) {
  
    if (point.x > BOTTOM_GRAB_WIDTH && point.x < (self.superview.frame.size.width - BOTTOM_GRAB_WIDTH)) {
      NSLog(@"ignoring middle flick up");
      return NO;
    }
    if (self.contentOffset.y != 0) {
      //prevent grabbing with a second finger (or same but really fast) while still moving
      //return NO;
      // UPDATE: we allow really fast repeat of gesture, but force an initial state first
      //NSLog(@"gestureRecognizer shouldReceiveTouch, self.contentOffset.y != 0 (%.1f)", self.contentOffset.y);
      int height = self.bounds.size.height;
      if (self.contentOffset.y > height/2) {
        self.contentOffset = CGPointMake(self.contentOffset.x, height);
      } else {
        self.contentOffset = CGPointMake(self.contentOffset.x, 0);
      }
    }
  
    if (activeView == view1) {
      incomingView = point.x < self.superview.frame.size.width / 2 ? view2A : view2B;
      // set both to zero but we will then set the incoming to 1
      view2A.alpha = 0;
      view2B.alpha = 0;
    } else {
      incomingView = view1;
    }
    //prepare inactive view to be in front for next scroll
    [self bringSubviewToFront:incomingView];
    incomingView.alpha = 1;
    incomingView.transform = CGAffineTransformIdentity;
  }
  
//  if (!result) {
//    NSLog(@"pan ignoring touch %@", NSStringFromCGPoint(point));
//  } else {
//    NSLog(@"pan  USING   touch %@", touch);
//  }
  return result;
}


//TODO scrolling that starts with an off screen tap is "delayed": there will 
//always be about 20-30 pixel discrepancy between the desired grabbing point.
//Test using safari on a zoomed page, scroll from the sides.



- (void)scrollViewDidScroll:(UIScrollView*) scrollView {
  //NSLog(@"scroll %.1f, incoming=%d, active=%d", scrollView.contentOffset.y, incomingView.tag, activeView.tag);
  
  int height = self.bounds.size.height;
  
  //only if ended a page up, not both directions
  //effectively this prepares for the same behavior but with the images swapped
  if (self.contentOffset.y == height) {
    //shift up by frame.height, should be the same as placing the frame origin y to 0 or center to height/2
    incomingView.center = CGPointMake(incomingView.center.x, incomingView.center.y - height /*incomingView.bounds.size.height/2*/);
    assert(incomingView);
    activeView = incomingView;
    incomingView = nil;
    
    //scroll to top
    [self setContentOffset:CGPointMake(0, 0) animated:NO];
    return;
  }
  
  //release pan gesture if we go near the top.
  //this is desired but also necessary otherwise we 
  //could keep panning past the limit
  if (self.panGestureRecognizer.numberOfTouches && self.contentOffset.y > height/2) {
    //NSLog(@"almost top, will release pan gesture. %.1f, n=%d, state=%d", self.contentOffset.y, self.panGestureRecognizer.numberOfTouches, self.panGestureRecognizer.state);
    self.panGestureRecognizer.enabled = NO;
    self.panGestureRecognizer.enabled = YES;
  }
}


- (void) scrollViewWillBeginDecelerating:(UIScrollView*) scrollView {
  //self.userInteractionEnabled = NO;
}

- (void)scrollViewWillBeginDragging:(UIScrollView*) scrollView {
  //FLSuggestionsView* suggestionsView = [FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.suggestionsView;
  //[suggestionsView hide];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView*) scrollView {
  //NSLog(@"scrollViewDidEndDecelerating @ %.1f, height=%.1f", self.contentOffset.y, self.frame.size.height);
  //self.userInteractionEnabled = YES;
  //self.transform = CGAffineTransformMakeScale(0.5, 1);
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView*) scrollView {
  NSLog(@"scrollViewDidEndScrollingAnimation");  
}


- (void) resetWithActiveView:(UIView*) view {
  activeView.alpha = 0;
  view.alpha = 1;
  view2A.alpha = view == view2A ? 1 : 0;
  view2B.alpha = view == view2B ? 1 : 0;
  activeView = view;
  [self setNeedsLayout];
}

- (void) reset {
  [self resetWithActiveView:view1];
}

- (void) layoutSubviews {
  NSLog(@"CustomScrollView layoutSubviews, self.frame: %@, self.bounds: %@", NSStringFromCGRect(self.frame), NSStringFromCGRect(self.bounds));
  if (USE_ZOOM_OUT_EFFECT) {
    float scaleFactor = 1.0 - 0.3 * self.contentOffset.y / self.bounds.size.height;
    activeView.transform = CGAffineTransformConcat(CGAffineTransformMakeScale(scaleFactor, scaleFactor), CGAffineTransformMakeTranslation((1.0 - scaleFactor) * self.bounds.size.width * 0.5, 0));
  }
  
  //we use center here instead of frame because transform might not be identity AND we dont want to squeeze
  //active view goes down twice as fast as we scroll up
  activeView.center   = CGPointMake(0.5 * self.bounds.size.width, 1.2 * self.contentOffset.y + 0.5 * self.bounds.size.height);
  //incoming view remains fixed but appears to move up since we are scrolling the whole view up
  incomingView.center = CGPointMake(0.5 * self.bounds.size.width, self.bounds.size.height  + 0.5 * self.bounds.size.height);
  activeView.alpha = fmax(1.0 - (2 * self.contentOffset.y / self.bounds.size.height), 0);
}

- (UIView*) activeView {
  return activeView;
}

@end
