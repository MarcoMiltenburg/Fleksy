//
//  UITouchManagerHooks.mm
//  Fleksy
//
//  Created by Kostas Eleftheriou on 2/4/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "UITouchManagerHooks.h"
#import "UITouchManager.h"

@implementation UITouchManagerHooks

- (void) setTimestamp:(NSTimeInterval) t {
  //NOTE: here both window and view are not yet set
  //seems that this line alone is enough to cause extra release messages to be sent. ARC, __bridged ??
  UITouch* touch = (UITouch*) self;
  //NSLog(@"UITouch %08x: setTimestamp: from %.6f to %.6f, phase: %d", touch, touch.timestamp, t, touch.phase);
  //automatic boxing here
  NSTimeInterval timestamp = [[self valueForKey:@"timestamp"] doubleValue];
  // if there is no timestamp we assume that this is a new touch, so we also have to set default values
  if (!timestamp) {
    [UITouchManager initTouch:touch];
    [UITouchManager sharedUITouchManager].lastTouchTimestamp = t;
  }
  //NSTimeInterval dt = t - timestamp;
  //NSLog(@"%p: set timestamp %.6f, location %@, phase: %d", touch, t, NSStringFromCGPoint([touch locationInView:touch.window]), touch.phase);
  
#if UITOUCH_STORE_PATH
  // we need to do this here as well as in _setLocationInWindow. _setLocationInWindow might (or will) not be called on ended/cancelled,
  // and here the location is not yet updated. Lifecycle seems to be set time/location, time/location, ... time on end
  if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
    [[UITouchManager sharedUITouchManager] checkTouch:touch forEndTimestamp:t];
  }
#endif
  
  
  //  NSLog(@" >1 UITouch_setTimestampImplementation: %p", [UITouchManager sharedUITouchManager].UITouch_setTimestampImplementation);
  //  NSLog(@" >2 UITouch_setTimestampImplementation: %@", self);
  //  NSLog(@" >3 UITouch_setTimestampImplementation: %@", NSStringFromSelector(_cmd));
  //  NSLog(@" >4 UITouch_setTimestampImplementation: %.6f", t);
  
  [UITouchManager sharedUITouchManager].UITouch_setTimestampImplementation(touch, _cmd, t);
}


- (void) _setLocationInWindow:(CGPoint) point resetPrevious:(BOOL) reset {
  //seems that this line alone is enough to cause extra release messages to be sent. ARC, __bridged ??
  UITouch* touch = (UITouch*) self;
  //NSLog(@"UITouch %08x: _setLocationInWindow: %@ resetPrevious: %d. Previous location: %@, window: %@, view: %@", touch, NSStringFromCGPoint(point), reset, NSStringFromCGPoint([touch locationInView:touch.window]), touch.window, touch.view);
  
  //reset shows us that it is the first location
  if (reset) {
    //NSValue* pointValue = [NSValue valueWithCGPoint:point];
    NSValue* key = [NSValue valueWithPointer:(const void*) touch];
    [[UITouchManager sharedUITouchManager].touchWindows setObject:[touch valueForKey:@"window"] forKey:key];
    if (![touch valueForKey:@"window"]) {
      NSLog(@"_setLocationInWindow: NO WINDOW!!!!");
    }
  }
  
  [UITouchManager sharedUITouchManager].UITouch_setLocationImplementation(touch, _cmd, point, reset);
  
  assert(CGPointEqualToPoint(point, [touch locationInView:touch.window]));
  
  
#if UITOUCH_STORE_PATH
  NSValue* key = [NSValue valueWithPointer:(const void*) touch];
  if (reset) {
    NSMutableArray* path = [[NSMutableArray alloc] init];
    [[UITouchManager sharedUITouchManager].touchPaths setObject:path forKey:key];
  }
  
  NSTimeInterval timestamp = [[self valueForKey:@"timestamp"] doubleValue];
  [[UITouchManager sharedUITouchManager] checkTouch:touch forEndTimestamp:timestamp];
#endif
  
  //NSLog(@"%p: set location %@, timestamp: %.6f, phase: %d", touch, NSStringFromCGPoint(point), touch.timestamp, touch.phase);
}

- (void) customDealloc {
  
  NSMutableArray* path = [[UITouchManager sharedUITouchManager] removeTouch:(UITouch*)self fromDealloc:YES];
  [path release];
  
  
  //TODO remove this check here once we ensure this works
  //  if ([[UITouchManager sharedUITouchManager].touchTimestamps count] + [[UITouchManager sharedUITouchManager].touchLocations count] + [[UITouchManager sharedUITouchManager].touchWindows count] > 20 * 3) {
  //    NSLog(@"WARNING - UITouch_dealloc: %d %d %d, will flush", [[UITouchManager sharedUITouchManager].touchTimestamps count], [[UITouchManager sharedUITouchManager].touchLocations count], [[UITouchManager sharedUITouchManager].touchWindows count]);
  //    [[UITouchManager sharedUITouchManager].touchTimestamps removeAllObjects];
  //    [[UITouchManager sharedUITouchManager].touchLocations removeAllObjects];
  //    [[UITouchManager sharedUITouchManager].touchWindows removeAllObjects];
  //    [[UITouchManager sharedUITouchManager].touchTags removeAllObjects];
  //    [[UITouchManager sharedUITouchManager].touchDidFeedbacks removeAllObjects];
  //  }
  [UITouchManager sharedUITouchManager].UITouch_dealloc(self, _cmd);
}


@end



