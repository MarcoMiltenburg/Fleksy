//
//  UIRotorRecognizer.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 5/12/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "UIRotorRecognizer.h"
#import "VariousUtilities.h"

@implementation UIRotorRecognizer

- (void) reset {
  
  //NSLog(@"UIRotorRecognizer reset");
  positionSinceLastTouchDown = 0;
  [super reset];
}


- (id) initWithTarget:(id) target action:(SEL) action {
  if (self = [super initWithTarget:self action:@selector(handleRotation)]) {
    originalTarget = target;
    originalAction = action;
    position = 0;
    previousPosition = 0;
    slices = 3;
    self.delegate = self;
    [self reset];
  }
  return self;
}


- (void) changePosition:(int) change {
  previousPosition = position;
  position += change;
  positionSinceLastTouchDown += change;
  //super.state = UIGestureRecognizerStateChanged;
  SuppressPerformSelectorLeakWarning([originalTarget performSelector:originalAction withObject:self]);
}

#define DEGREES_TO_RADIANS(x) ((x) * M_PI / 180.0)

- (void) handleRotation {
  
  int splitDegrees = 30;
  
  //NSLog(@"handleRotation %.6f BEGIN", self.rotation);
  
  //NOTE: we could not do a simple self.rotation = 0 here, we got some wierd results, bugs?
  
  if (self.rotation < DEGREES_TO_RADIANS(-splitDegrees + positionSinceLastTouchDown * splitDegrees)) {
    [self changePosition:-1];
  }
  
  if (self.rotation > DEGREES_TO_RADIANS(splitDegrees + positionSinceLastTouchDown * splitDegrees)) {
    [self changePosition:1];
  }
  
  //NSLog(@"handleRotation %.6f END", self.rotation);
}

- (int) slice:(int) slice {
  int result = slice % slices;
  if (result < 0) {
    result += slices;
  }
  return result;
}

- (int) position {
  return [self slice:position];
  //NSLog(@"real position: %d, result: %d", position, result);
}

- (int) previousPosition {
  return [self slice:previousPosition];
}


//- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesBegan:touches withEvent:event];
//  NSLog(@"UIRotorRecognizer touchesBegan %d, state: %d, enabled: %d", [touches count], self.state, self.enabled);
//}
//
//- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesMoved:touches withEvent:event];
//  NSLog(@"UIRotorRecognizer touchesMoved %d, state: %d, enabled: %d", [touches count], self.state, self.enabled);
//}
//
//- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesEnded:touches withEvent:event];
//  NSLog(@"UIRotorRecognizer touchesEnded %d, state: %d, enabled: %d", [touches count], self.state, self.enabled);
//}
//
//- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//  [super touchesCancelled:touches withEvent:event];
//  NSLog(@"UIRotorRecognizer touchesCancelled %d, state: %d, enabled: %d", [touches count], self.state, self.enabled);
//}

// called when a gesture recognizer attempts to transition out of UIGestureRecognizerStatePossible. returning NO causes it to transition to UIGestureRecognizerStateFailed
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  //NSLog(@"gestureRecognizerShouldBegin");
  return YES;
}

// called when the recognition of one of gestureRecognizer or otherGestureRecognizer would be blocked by the other
// return YES to allow both to recognize simultaneously. the default implementation returns NO (by default no two gestures can be recognized simultaneously)
//
// note: returning YES is guaranteed to allow simultaneous recognition. returning NO is not guaranteed to prevent simultaneous recognition, as the other gesture's delegate may return YES
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  //NSLog(@"shouldRecognizeSimultaneouslyWithGestureRecognizer  slice: %d", [self currentSlice]);
  return YES;
}

// called before touchesBegan:withEvent: is called on the gesture recognizer for a new touch. return NO to prevent the gesture recognizer from seeing this touch
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  //NSLog(@"shouldReceiveTouch  slice: %d", [self currentSlice]);
  return YES;
}

@synthesize slices;

@end
