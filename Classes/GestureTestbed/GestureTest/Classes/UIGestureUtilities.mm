//
//  UIGestureUtilities.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 12/30/11.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "UIGestureUtilities.h"

@implementation UIGestureUtilities

+ (NSString*) getDirectionString:(UISwipeGestureRecognizerDirection) direction {
  if (direction == UISwipeGestureRecognizerDirectionUp) {
    return @"UP";
  }
  if (direction == UISwipeGestureRecognizerDirectionDown) {
    return @"DOWN";
  }
  if (direction == UISwipeGestureRecognizerDirectionLeft) {
    return @"LEFT";
  }
  if (direction == UISwipeGestureRecognizerDirectionRight) {
    return @"RIGHT";
  }
  if (direction == UISwipeGestureRecognizerDirectionNone) {
    return @"NONE";
  }
  return @"UNKNOWN!";
}



+ (NSString*) getStateString:(UIGestureRecognizerState) state {
  if (state == UIGestureRecognizerStatePossible) {
    return @"UIGestureRecognizerStatePossible";
  }
  if (state == UIGestureRecognizerStateBegan) {
    return @"UIGestureRecognizerStateBegan";
  }
  if (state == UIGestureRecognizerStateChanged) {
    return @"UIGestureRecognizerStateChanged";
  }
  if (state == UIGestureRecognizerStateEnded) {
    return @"UIGestureRecognizerStateEnded/Recognized";
  }
  if (state == UIGestureRecognizerStateCancelled) {
    return @"UIGestureRecognizerStateCancelled";
  }
  if (state == UIGestureRecognizerStateFailed) {
    return @"UIGestureRecognizerStateFailed";
  }
  return @"UNKNOWN!";
}


@end
