//
//  UITouchManager.mm
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/11/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "UITouchManager.h"
#import "SynthesizeSingleton.h"

@implementation PathPoint

- (id) initWithLocation:(CGPoint) _location timestamp:(NSTimeInterval) _timestamp phase:(UITouchPhase) _phase {
  if (self = [super init]) {
    location = _location;
    timestamp = _timestamp;
    phase = _phase;
    notificationTime = CFAbsoluteTimeGetCurrent();
  }
  return self;
}

- (void) setEnded:(UITouchPhase) _phase {
  phase = _phase;
}

- (NSString*) description {
  return [NSString stringWithFormat:@"PathPoint <phase: %d, location: %@, timestamp: %.6f", phase, NSStringFromCGPoint(location), timestamp];
}

@synthesize location, timestamp, notificationTime, phase;

@end

@implementation UITouchManager

SYNTHESIZE_SINGLETON_FOR_CLASS(UITouchManager)

+ (void) initializeTouchManager {
  [UITouchManager sharedUITouchManager];
}

+ (double) lastTouchTimestamp {
  return [UITouchManager sharedUITouchManager].lastTouchTimestamp;
}

- (id) init {
  
  if (self = [super init]) {
    
    lastTouchTimestamp = 0;
    
    touchWindows      = [[NSMutableDictionary alloc] init];
    touchTags         = [[NSMutableDictionary alloc] init];
    touchDidFeedbacks = [[NSMutableDictionary alloc] init];
#if UITOUCH_STORE_PATH
    touchPaths        = [[NSMutableDictionary alloc] init];
#endif
    
  }
  return self;
}


- (void) checkTouch:(UITouch*) touch forEndTimestamp:(NSTimeInterval) timestamp {
  //NSLog(@"checking end timestamps, self: %@, touch: %@", self, touch);
  NSValue* key = [NSValue valueWithPointer:(const void*) touch];
  NSMutableArray* path = [[UITouchManager sharedUITouchManager].touchPaths objectForKey:key];
  PathPoint* lastPoint = [path lastObject];
  if (lastPoint && lastPoint.timestamp == timestamp) {
    [lastPoint setEnded:touch.phase];
    //NSLog(@"checking end timestamps: equal, lastPoint: %@, phase: %d", lastPoint, touch.phase);
  } else {
    CGPoint point = [touch locationInView:touch.window];
    PathPoint* pathPoint = [[PathPoint alloc] initWithLocation:point timestamp:timestamp phase:touch.phase];
    [path addObject:pathPoint];
    //NSLog(@"checking end timestamps, NOT equal, lastPoint: %@, phase: %d", lastPoint, touch.phase);
  }
}

+ (void) initTouch:(UITouch*) touch {
  //NSNumber* number = [NSNumber numberWithDouble:t];
  //[[UITouchManager sharedUITouchManager].touchTimestamps setObject:number forKey:[NSValue valueWithPointer:(const void*)self]];
  touch.tag = UITouchTypePending;
  touch.didFeedback = NO;
  //NSLog(@"new touch @ %.8f", t);
}


- (NSMutableArray*) removeTouch:(UITouch*) touch {
  
  //NSLog(@"removeTouch: %p", touch);
  
  NSValue* key = [NSValue valueWithPointer:(const void*) touch];
  if (self.touchTags.count > 300) {
    NSLog(@"removeTouch %p knows: %p, count: %d", touch, [self.touchTags objectForKey:key], self.touchTags.count);
  }
  //seems that this line alone is enough to cause extra release messages to be sent. ARC, __bridged ??
  //UITouch* touch = (UITouch*) self;
  //NSLog(@"UITouch %08x: dealloc: window: %@, view: %@", touch, touch.window, touch.view);
  [self.touchWindows removeObjectForKey:key];
  [self.touchTags removeObjectForKey:key];
  [self.touchDidFeedbacks removeObjectForKey:key];

  NSMutableArray* path = [self.touchPaths objectForKey:key];
  [path removeAllObjects];
  [self.touchPaths removeObjectForKey:key];
  return path;
}

+ (void) reset {
  [[UITouchManager sharedUITouchManager].touchWindows removeAllObjects];
  [[UITouchManager sharedUITouchManager].touchTags removeAllObjects];
  [[UITouchManager sharedUITouchManager].touchDidFeedbacks removeAllObjects];
}

+ (NSTimeInterval) initialTimestampForTouch:(UITouch*) touch {
  NSArray* pathPoints = [[UITouchManager sharedUITouchManager].touchPaths objectForKey:[NSValue valueWithPointer:(const void*)touch]];
  if (!pathPoints || !pathPoints.count) {
    [NSException raise:@"initialTimestampForTouch" format:@"not found, touch: %@, touch.tag: %d", touch, touch.tag];
  }
  PathPoint* firstPoint = [pathPoints objectAtIndex:0];
  return firstPoint.timestamp;
}

+ (CGPoint) initialLocationForTouch:(UITouch*) touch  {
  NSArray* pathPoints = [[UITouchManager sharedUITouchManager].touchPaths objectForKey:[NSValue valueWithPointer:(const void*)touch]];
  if (!pathPoints || !pathPoints.count) {
    [NSException raise:@"initialLocationForTouch" format:@"not found, touch: %@, touch.tag: %d", touch, touch.tag];
  }
  PathPoint* firstPoint = [pathPoints objectAtIndex:0];
  return firstPoint.location;
}

@synthesize touchWindows, touchPaths, touchTags, touchDidFeedbacks;

@synthesize lastTouchTimestamp;

@end



@implementation UITouch (Extensions)

//takes about 25 usec on iPhone4S
- (NSTimeInterval) initialTimestamp {
  return [UITouchManager initialTimestampForTouch:self];
}

- (NSTimeInterval) timeSinceTouchdown {
  return self.timestamp - [UITouchManager initialTimestampForTouch:self];
}

- (void) updateInTouchManager {
  
  if (self.phase == UITouchPhaseBegan) {
    
    NSValue* key = [NSValue valueWithPointer:(const void*) self];
    
    [UITouchManager initTouch:self];
    [UITouchManager sharedUITouchManager].lastTouchTimestamp = self.timestamp;
    [[UITouchManager sharedUITouchManager].touchWindows setObject:self.window forKey:key];
    
    
#if UITOUCH_STORE_PATH
    NSMutableArray* path = [[NSMutableArray alloc] init];
    [[UITouchManager sharedUITouchManager].touchPaths setObject:path forKey:key];
#endif
    
  }
  
#if UITOUCH_STORE_PATH
  
  [[UITouchManager sharedUITouchManager] checkTouch:self forEndTimestamp:self.timestamp];
  
  //we need to do this here as well as in _setLocationInWindow. _setLocationInWindow might (or will) not be called on ended/cancelled,
  // and here the location is not yet updated. Lifecycle seems to be set time/location, time/location, ... time on end
  if (self.phase == UITouchPhaseEnded || self.phase == UITouchPhaseCancelled) {
    [[UITouchManager sharedUITouchManager] removeTouch:self];
  }
#endif
  

}


//takes about 35 usec on iPhone4S
- (CGPoint) initialLocationInView:(UIView*) view {
  //NSLog(@"UITouch %08x CALL: initialLocationInView: %@", self, view);
  CGPoint initialWindowLocation = [UITouchManager initialLocationForTouch:self];
  //NSLog(@"UITouch %08x: initialWindowLocation: %@, self.window: %@", self, NSStringFromCGPoint(initialWindowLocation), self.window);
  UIWindow* theWindow = self.window;
  if (!theWindow) {
    //NSLog(@"initialLocationInView: NO WINDOW! will fetch from our stored data");
    theWindow = [[UITouchManager sharedUITouchManager].touchWindows objectForKey:[NSValue valueWithPointer:(const void*)self]];
    if (!theWindow) {
      NSLog(@"initialLocationInView: NO WINDOW! AFTER FETCH!!!!");
      return CGPointZero;
    }
  }
  CGPoint result = [theWindow convertPoint:initialWindowLocation toView:view];
  return result;
}

#define FLEKSY_SMALL_VALUE 0.0001f

static float distanceOfPoints(CGPoint p1, CGPoint p2) {
  float dx = p1.x - p2.x;
  float dy = p1.y - p2.y;
  float result = hypotf(dx, dy);
  return((fabsf(result) < FLEKSY_SMALL_VALUE ) ? 0.0f : result);
}

- (float) distanceSinceStartInView:(UIView*) view {
  CGPoint start = [self initialLocationInView:view];
  CGPoint end = [self locationInView:view];
  return distanceOfPoints(start, end);
}

#if UITOUCH_STORE_PATH
- (NSArray*) path {
  return [[UITouchManager sharedUITouchManager].touchPaths objectForKey:[NSValue valueWithPointer:(const void*)self]];
}
#endif

- (void) setTag:(UITouchType) value {
  //NSLog(@"%p setTag: %d", self, value);
  NSNumber* number = [NSNumber numberWithInt:value];
  [[UITouchManager sharedUITouchManager].touchTags setObject:number forKey:[NSValue valueWithPointer:(const void*)self]];
}

- (UITouchType) tag {
  NSNumber* number = [[UITouchManager sharedUITouchManager].touchTags objectForKey:[NSValue valueWithPointer:(const void*)self]];
  if (!number) {
    //[NSException raise:@"UITouch.tag" format:@"not found, touch: %@", self];
    //TODO: Re-visit TouchManagager tag == nil
    NSLog(@" Would throw NSException raise: UITouch.tag format: not found, touch: %@", self);
  }
  return (UITouchType) [number intValue];
}

- (void) setDidFeedback:(BOOL) didFeedback {
  NSNumber* number = [NSNumber numberWithBool:didFeedback];
  [[UITouchManager sharedUITouchManager].touchDidFeedbacks setObject:number forKey:[NSValue valueWithPointer:(const void*)self]];
}

- (BOOL) didFeedback {
  NSNumber* number = [[UITouchManager sharedUITouchManager].touchDidFeedbacks objectForKey:[NSValue valueWithPointer:(const void*)self]];
  if (!number) {
    [NSException raise:@"UITouch.didFeedback" format:@"not found, touch: %@", self];
  }
  return [number boolValue];
}




@end



