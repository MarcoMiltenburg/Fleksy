//
//  UITapGestureRecognizer2.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/11/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "UITapGestureRecognizer2.h"
#import <UIKit/UIGestureRecognizerSubclass.h>
#import "MathFunctions.h"
#import "UITouchManager.h"

//only for cancelling spelling requests on touchdown, we wanna do that before touch up
//#import "FLKeyboardContainerView.h"

@interface UITapGestureRecognizer (Private)
@property(readonly) NSArray * touches;
@end


@implementation UITapGestureRecognizer2

- (id)initWithTarget:(id)target action:(SEL)action { // default initializer
  
  if (self = [super initWithTarget:target action:action]) {
    self.delaysTouchesEnded = NO;
  }
  return self;
}

- (NSArray*) orderedTouches {
  
  NSMutableArray* sortedTouches = [NSMutableArray arrayWithArray:self.touches];
  [sortedTouches sortUsingComparator: ^NSComparisonResult(UITouch* t1, UITouch* t2) {

    double time1 = t1.initialTimestamp;
    double time2 = t2.initialTimestamp;

    if (time2 > time1) {
      return NSOrderedAscending;
    }
    if (time2 < time1) {
      return NSOrderedDescending;
    }
    return NSOrderedSame;
  }];
  
  return sortedTouches;
}

- (CGPoint) locationOfTouch:(NSUInteger) touchIndex inView:(UIView*) view { // the location of a particular touch

  NSLog(@"WARNING: using locationOfTouch in UITapGestureRecognizer2. Use orderedTouches instead");
  
  if (self.numberOfTouches == 1) {
    return [super locationOfTouch:touchIndex inView:view];
  }  
  
  if (self.numberOfTouches == 2) {
    UITouch* touch1 = [self.touches objectAtIndex:0];
    UITouch* touch2 = [self.touches objectAtIndex:1];
    BOOL orderOK = touch1.initialTimestamp <= touch2.initialTimestamp;
    if (!orderOK) {
      //NSLog(@"order is reversed!");
      touchIndex = touchIndex ? 0 : 1;
    }
    return [super locationOfTouch:touchIndex inView:view];
  }
  
  //slower fallback for >= 3 touches
  //TODO speed up, only sort once on some hook like state = ended
  //or have sorted instance be nil, if nil sort and keep, and nil on reset
  
  NSArray* sortedTouches = [self orderedTouches];
  CGPoint sortedPoint = [[sortedTouches objectAtIndex:touchIndex] locationInView:view];
  
  return sortedPoint;
}

- (CGPoint) initialLocationOfTouch:(NSUInteger) touchIndex inView:(UIView*) view {
  CGPoint result = [self locationOfTouch:touchIndex inView:view];
  
//  NSArray* sortedTouches = [self orderedTouches];
//  UITouch* touch = [sortedTouches objectAtIndex:touchIndex];
//  CGPoint expected = touch.initialLocation;
//  //we need to use the same view we used when saving earlier
//  CGPoint current  = [touch locationInView:touch.window];
//  CGPoint adjust = subtractPoints(expected, current);
//  
//  //NSLog(@"point seems to have moved, will adjust by %@", NSStringFromCGPoint(adjust));
//  result = addPoints(adjust, result);
  
  return result;
}

- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  NSLog(@"touches began UITapGestureRecognizer2[%d out of %d], event.count=%d", self.numberOfTouches, self.numberOfTouchesRequired, touches.count);

  
  //[[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView cancelAllSpellingRequests];
  
  //NSLog(@"UITapGestureRecognizer2[%d] touchesBegan", self.numberOfTouchesRequired);
  for (UITouch* touch in touches) {
    //once we get more touches than numberOfTouchesRequired we wont be called again,
    //since the recognizer has failed
    if (self.numberOfTouches == self.numberOfTouchesRequired) {
      //NSLog(@"xxx reports new touch (DING) timestamp: %.6f", [number doubleValue]);
      //[VariousUtilities playTock];
      //TODO: key popup here? vibration? tock? or after???
      //force previous touches on new begin, cut them off and "tap" them. cant swipe anymore on those
      //also: concurrent tap+swipe: same as above force, just new touch is not tap for sure yet, may be swipe
    }
    
  }
}



//- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
//  [super touchesMoved:touches withEvent:event];
//  NSLog(@"touches moved UITapGestureRecognizer2[%d]! %@", self.numberOfTouchesRequired, touches);
//}
//
//- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
//  [super touchesEnded:touches withEvent:event];
//  NSLog(@"touches ended UITapGestureRecognizer2[%d]! %@", self.numberOfTouchesRequired, touches);
//}
//
//- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
//  [super touchesCancelled:touches withEvent:event];
//  NSLog(@"touches cancelled UITapGestureRecognizer2[%d]! %@", self.numberOfTouchesRequired, touches);
//}



@end
