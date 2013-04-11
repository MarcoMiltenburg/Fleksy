//
//  MySwipeGestureRecognizer.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 10/18/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "MySwipeGestureRecognizer.h"
#import "UIGestureUtilities.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@implementation MySwipeGestureRecognizer

- (id) initWithTarget:(id)target action:(SEL)action {
  if (self = [super initWithTarget:target action:action]) {
    _activeTouches = [[NSMutableSet alloc] init];
    clearTouches = NO;
  }
  return self;
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesBegan:touches withEvent:event];
  
  if (clearTouches) {
    [_activeTouches removeAllObjects];
    clearTouches = NO;
  }
  
  assert(_activeTouches.count < 10);
  
  [_activeTouches addObjectsFromArray:[touches allObjects]];
  //NSLog(@"began %p, _activeTouches: %d", self, _activeTouches.count);
  
  if (self.numberOfTouches != self.numberOfTouchesRequired && self.numberOfTouchesRequired != 2) {
    NSLog(@"INFO: MySwipeGestureRecognizer%@ touches are %d out of %d", [UIGestureUtilities getDirectionString:self.direction], self.numberOfTouches, self.numberOfTouchesRequired);
  }
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesEnded:touches withEvent:event];
  for (UITouch* touch in touches) {
    [_activeTouches removeObject:touch];
  }
  //NSLog(@"end %p, _activeTouches: %d", self, _activeTouches.count);
}

- (void) touchesCancelled:(NSSet*)touches withEvent:(UIEvent*)event {
  [super touchesCancelled:touches withEvent:event];
  for (UITouch* touch in touches) {
    [_activeTouches removeObject:touch];
  }
  //NSLog(@"cancelled %p, _activeTouches: %d", self, _activeTouches.count);
}


- (CGPoint) currentLocationInView:(UIView*) view {
  return [[_activeTouches anyObject] locationInView:view];
}


- (NSSet*) activeTouches {
  //NSLog(@"self: %p, %d %d %d", self, _activeTouches.count, self.numberOfTouches, self.numberOfTouchesRequired);
  assert(_activeTouches.count == self.numberOfTouches);
  //assert(_activeTouches.count == self.numberOfTouchesRequired);
  if (_activeTouches.count != self.numberOfTouchesRequired) {
    NSLog(@"WARNING: _activeTouches.count != self.numberOfTouchesRequired");
  }
  return _activeTouches;
}

- (void) setState:(UIGestureRecognizerState) s {
  //NSLog(@"MySwipeGestureRecognizer%@ %p wants to set state from %@ to %@", [UIGestureUtilities getDirectionString:self.direction], self, [UIGestureUtilities getStateString:super.state], [UIGestureUtilities getStateString:s]);
  [super setState:s];
  if (s == UIGestureRecognizerStatePossible || s == UIGestureRecognizerStateCancelled || s == UIGestureRecognizerStateFailed) {
    [_activeTouches removeAllObjects];
  } else if (s == UIGestureRecognizerStateRecognized) {
    clearTouches = YES;
  } else {
    NSLog(@"setState %p, %d, _activeTouches: %d", self, s, _activeTouches.count);
  }
}

// for some reason when doing a long tap, the two 2-finger swipe recognizers won't get a touchesEnded or Cancelled, so we manually call this...
- (void) clearTouches {
  [_activeTouches removeAllObjects];
}

@end
