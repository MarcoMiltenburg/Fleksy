//
//  ScrollWheelGestureRecognizer.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 26/10/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "ScrollWheelGestureRecognizer.h"
#import "UIGestureUtilities.h"
#import "MathFunctions.h"
#import "VariousUtilities.h"


@implementation ScrollWheelGestureRecognizer


- (float) angleBetweenPoint:(int) p1 andPoint:(int) p2 andPoint:(int) p3 {
  float a1 = slopeBetweenPoints([[lastPoints objectAtIndex:p1] CGPointValue], [[lastPoints objectAtIndex:p2] CGPointValue]);
  float a2 = slopeBetweenPoints([[lastPoints objectAtIndex:p2] CGPointValue], [[lastPoints objectAtIndex:p3] CGPointValue]);
  return differenceOfAngles(a1, a2);
}

- (id) initWithTarget:(id)target action:(SEL)action {
  if (self = [super initWithTarget:target action:action]) {
    
    originalTarget = target;
    originalAction = action;
    
    //we need to remove all target/action pairs or they will be called for every touchesMoved.
    //Note that we cant even eliminate this by nop-ing touchesMoved (why?) 
    [self removeTarget:nil action:nil];
    
    lastPoints = [[NSMutableArray alloc] init];
  }
  return self;
}

- (CGPoint) lastPoint {
  return [[lastPoints lastObject] CGPointValue];
}


- (void) printPoints {
  int i = 0;
  NSLog(@"printPoints (%d)", [lastPoints count]);
  for (NSValue* pointValue in lastPoints) {
    NSLog(@"point.%d: %@", i, NSStringFromCGPoint([pointValue CGPointValue]));
    i++;
  } 
}


- (CGPoint) getPoint:(UITouch*) touch {
  return [touch locationInView:self.view.superview];
}

- (float) addPoint:(CGPoint) point {

  if (![lastPoints count]) {
    [lastPoints addObject:[NSValue valueWithCGPoint:point]];
    return 0;
  }
  
  float distance = distanceOfPoints([self lastPoint], point);
  if (distance < 3) {
    return 0;
  }
  
  travelDistance += distance;
  travelDistanceSinceDirectionChange += distance;
  
  [lastPoints addObject:[NSValue valueWithCGPoint:point]];
  if ([lastPoints count] > MAX_LAST_POINTS) {
    [lastPoints removeObjectAtIndex:0];
  }
    
  //NSLog(@"Added point (%.0f, %.0f)", point.x, point.y);
  //[self printPoints];
  
  return distance;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  
  if (self.numberOfTouches != 1) {
    self.state = UIGestureRecognizerStateFailed;
    return;
  }
  
//  self.state = UIGestureRecognizerStateBegan;
//  firstPoint = [self getPoint:[touches anyObject]];
//  [self addPoint:firstPoint];
//  travelDistance = 0;
//  index = 0;
//  trigger = NO;
//  timesFired = 0;
//  travelDistanceSinceDirectionChange = 0;
//  direction = (UISwipeGestureRecognizerDirection) UISwipeGestureRecognizerDirectionNone;
  
}


- (UISwipeGestureRecognizerDirection) direction {
  return direction;
}

- (void) start {
  self.state = UIGestureRecognizerStateBegan;
  travelDistance = 0;
  trigger = NO;
  travelDistanceSinceDirectionChange = 0;
  [lastPoints removeAllObjects];
}

- (void) setDirection:(UISwipeGestureRecognizerDirection) _direction {
  
  if (direction == _direction) {
    return;
  }
  
  //NSLog(@"setDirection %@", [UIGestureUtilities getDirectionString:_direction]);
  
//  if (direction == UISwipeGestureRecognizerDirectionNone) {
//    NSLog(@"dir is none");
//    direction = _direction;
//    return;
//  }
  
  if (_direction == UISwipeGestureRecognizerDirectionRight || _direction == UISwipeGestureRecognizerDirectionLeft) {
    direction = (UISwipeGestureRecognizerDirection) UISwipeGestureRecognizerDirectionNone;
    self.state = UIGestureRecognizerStateFailed;
    //NSLog(@"FAILED!! (LR)");
    return;
  }
  
  [self start];
  
  //NSLog(@"setDirection from %@ to %@", [UIGestureUtilities getDirectionString:direction], [UIGestureUtilities getDirectionString:_direction]);
  if (direction == UISwipeGestureRecognizerDirectionNone || _direction == UISwipeGestureRecognizerDirectionNone) {
    timesFired = 0;
    //if (travelDistanceSinceDirectionChange > -90) {
    //  travelDistanceSinceDirectionChange = 0;
    //NSLog(@"DIRECTION CHANGED");
    //[self printPoints];
    //}
  } else {
    //NSLog(@"direction swap");
  }
  
    
  
  self->direction = _direction;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  
  if (self.state == UIGestureRecognizerStateFailed) {
    //NSLog(@"touchesMoved but state is failed");
    return;
  }
  
  if (self.numberOfTouches != 1) {
    //NSLog(@"touchesMoved but numberOfTouches != 1");
    self.state = UIGestureRecognizerStateFailed;
    return;
  }
  
//  if ([[FLKeyboard sharedFLKeyboard] isDragging]) {
//    NSLog(@"ignoring touchesMoved, KB dragging");
//    self.state = UIGestureRecognizerStateFailed;
//    return;
//  }
  
  
  CGPoint currentPoint = [[touches anyObject] locationInView:self.view];

  
  float distance = [self addPoint:currentPoint];
  //NSLog(@"Distance: %.4f, total: %.4f", distance, travelDistance);
  if (distance == 0) {
    return;
  }
  
  
  //check for direction change
  if ([lastPoints count] == MAX_LAST_POINTS) { //if we got enough points
    int mid = (MAX_LAST_POINTS-1)/2;
    float angle = [self angleBetweenPoint:0 andPoint:mid andPoint:[lastPoints count] - 1];
    
    //float dist1 = distanceOfPoints(lastPoints[0],  lastPoints[mid]);
    //float dist2 = distanceOfPoints(lastPoints[LAST_POINTS_N-1], lastPoints[mid]);
    
    //NSLog(@"angle = %.4f, dist1: %.4f, dist2: %.4f", angle, dist1, dist2);
    if (fabs(angle) > 2.5) {
      
      if (self.direction == UISwipeGestureRecognizerDirectionUp) {
        self.direction = UISwipeGestureRecognizerDirectionDown;
      } else if (self.direction == UISwipeGestureRecognizerDirectionDown) {
        self.direction = UISwipeGestureRecognizerDirectionUp;
      }
      
    } else {
      
      //NSLog(@"angle = %.4f", angle);
      
      if (angle > 0.25) {
        self.direction = UISwipeGestureRecognizerDirectionDown;
      } else if (angle < -0.25) {
        self.direction = UISwipeGestureRecognizerDirectionUp;
      }
    }
  }
  
  
  
  
  
  
  float limit = 90;
  if (!timesFired) {
    limit += 50;
  }
  
  if (travelDistance > limit) {
    
    if (direction != UISwipeGestureRecognizerDirectionUp && direction != UISwipeGestureRecognizerDirectionDown) {
      //NSLog(@"moved but direction %@, returning", [UIGestureUtilities getDirectionString:self.direction]);
      return;
    }
    
    //CGPoint lastPoint = [self lastPoint];
    //float deltaY = firstPoint.y - lastPoint.y;
    //float deltaX = firstPoint.x - lastPoint.x;
    //NSLog(@"timesFired: %d, state: %@", timesFired, [UIGestureUtilities getStateString:self.state]);
    
    //if (fabs(deltaX) > 200) {
    //  NSLog(@"Direction NOT OK!");
    //  self.state = UIGestureRecognizerStateFailed;
    //} else {
    //travelDistance -= limit;
    
    trigger = YES;
    timesFired++;
    travelDistance2 = travelDistance; //keep this value for observers
    travelDistance = 0;
    self.state = UIGestureRecognizerStateChanged;
    SuppressPerformSelectorLeakWarning([originalTarget performSelector:originalAction withObject:self]);
    //}
  }
  
}


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  
  if (self.state == UIGestureRecognizerStateFailed) {
    //NSLog(@"touchesEnded self.state == UIGestureRecognizerStateFailed");
    return;
  }
  
  if (direction == UISwipeGestureRecognizerDirectionNone) {
    //NSLog(@"touchesEnded direction == UISwipeGestureRecognizerDirectionNone");
    self.state = UIGestureRecognizerStateFailed;
    return;
  }
  
  self.state = UIGestureRecognizerStateEnded;
  self.direction = (UISwipeGestureRecognizerDirection) UISwipeGestureRecognizerDirectionNone;
  //NSLog(@"touchesEnded self.state = UIGestureRecognizerStateEnded");
  return;
  
  
  if (!timesFired) {
    
    if (travelDistance > 22) {
      trigger = YES;
      self.state = UIGestureRecognizerStateChanged;
    }
    
    //    if (direction == UISwipeGestureRecognizerDirectionLeft || direction == UISwipeGestureRecognizerDirectionRight) {
    //    }
    //    
    //    CGPoint lastPoint = [self lastPoint];
    //    float deltaY = firstPoint.y - lastPoint.y;
    //    float deltaX = firstPoint.x - lastPoint.x;
    //    if (fabs(deltaY) > fabs(deltaX) && travelDistance > 60) {
    //      if (deltaY < 0) {
    //        direction = UISwipeGestureRecognizerDirectionDown;
    //      } else {
    //        direction = UISwipeGestureRecognizerDirectionUp;
    //      }
    //      trigger = YES;
    //      self.state = UIGestureRecognizerStateChanged;
    //    }
    
  } else if (timesFired > 1) {
    self.state = UIGestureRecognizerStateEnded;
  }
  
}



- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  self.state = UIGestureRecognizerStateCancelled;
  self.direction = (UISwipeGestureRecognizerDirection) UISwipeGestureRecognizerDirectionNone;
}

@synthesize trigger, travelDistance2;

@end
