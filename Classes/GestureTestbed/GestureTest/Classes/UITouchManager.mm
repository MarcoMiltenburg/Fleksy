//
//  UITouchManager.mm
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/11/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "UITouchManager.h"
#import "SynthesizeSingleton.h"
#import "MathFunctions.h"
#import "HookingUtilities.h"

#import <objc/runtime.h>

#define SET_LOCATION_METHOD @"_setLocationInWindow:resetPrevious:"
#define SET_TIMESTAMP_METHOD @"setTimestamp:"

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

@interface UITouch (Private)
//@property int phase;
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
    
    [[HookingUtilities sharedHookingUtilities] swapMethodNamed:SET_LOCATION_METHOD inClassNamed:@"UITouch"
                                         withCustomMethodNamed:SET_LOCATION_METHOD inClassNamed:@"UITouchManagerHooks"];
    
    [[HookingUtilities sharedHookingUtilities] swapMethodNamed:SET_TIMESTAMP_METHOD inClassNamed:@"UITouch"
                                         withCustomMethodNamed:SET_TIMESTAMP_METHOD inClassNamed:@"UITouchManagerHooks"];
    
    [[HookingUtilities sharedHookingUtilities] swapMethodNamed:@"dealloc"       inClassNamed:@"UITouch"
                                         withCustomMethodNamed:@"customDealloc" inClassNamed:@"UITouchManagerHooks"];
    
    
    UITouch_setLocationImplementation  = [[HookingUtilities sharedHookingUtilities] originalMethodNamed:SET_LOCATION_METHOD  inClass:[UITouch class]];
    UITouch_setTimestampImplementation = [[HookingUtilities sharedHookingUtilities] originalMethodNamed:SET_TIMESTAMP_METHOD inClass:[UITouch class]];
    UITouch_dealloc                    = [[HookingUtilities sharedHookingUtilities] originalMethodNamed:@"dealloc"    inClass:[UITouch class]];
    
//    NSLog(@"UITouch_setLocationImplementation: %p", UITouch_setLocationImplementation);
//    NSLog(@"UITouch_setTimestampImplementation: %p", UITouch_setTimestampImplementation);
//    NSLog(@"UITouch_dealloc: %p", UITouch_dealloc);
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


- (NSMutableArray*) removeTouch:(UITouch*) touch fromDealloc:(BOOL) fromDealloc {
  
  //NSLog(@"removeTouch: %p", touch);
  
  NSValue* key = [NSValue valueWithPointer:(const void*) touch];
  if (self.touchTags.count > 300) {
    NSLog(@"removeTouch %p fromDealloc: %d, knows: %p, count: %d", touch, fromDealloc, [self.touchTags objectForKey:key], self.touchTags.count);
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

@synthesize UITouch_setTimestampImplementation, UITouch_setLocationImplementation, UITouch_dealloc;

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

//- (void) removeFromTouchManager {
//  [[UITouchManager sharedUITouchManager] removeTouch:self fromDealloc:NO];
//}

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
    [NSException raise:@"UITouch.tag" format:@"not found, touch: %@", self];
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



