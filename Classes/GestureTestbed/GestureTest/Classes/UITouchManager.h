//
//  UITouchManager.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/11/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


#define UITOUCH_STORE_PATH 1

typedef enum {
  UITouchTypePending = 0,
  UITouchTypeProcessedTap,
  UITouchTypeProcessedSwipe,
  UITouchTypeProcessedLongTap,
  UITouchTypeIgnore
} UITouchType;

#define UITouchTypeIsProcessed(touchType) ((touchType) == UITouchTypeProcessedTap || (touchType) == UITouchTypeProcessedSwipe)

@interface PathPoint : NSObject {
  CGPoint location;
  NSTimeInterval timestamp;
  double notificationTime;
  UITouchPhase phase;
}

- (id) initWithLocation:(CGPoint) _location timestamp:(NSTimeInterval) _timestamp phase:(UITouchPhase) _phase;
- (void) setEnded:(UITouchPhase) _phase;

@property (readonly) CGPoint location;
@property (readonly) NSTimeInterval timestamp;
@property (readonly) double notificationTime;
@property (readonly) UITouchPhase phase;


@end

@interface UITouch (Extensions)

@property (readwrite) UITouchType tag;
@property (readwrite) BOOL didFeedback;
@property (readonly) NSTimeInterval initialTimestamp;
@property (readonly) NSTimeInterval timeSinceTouchdown;
- (CGPoint) initialLocationInView:(UIView*) view;
- (float) distanceSinceStartInView:(UIView*) view;
#if UITOUCH_STORE_PATH
@property (readonly) NSArray* path;
#endif
@end



@interface UITouchManager : NSObject


+ (void) initializeTouchManager;
+ (void) initTouch:(UITouch*) touch;
+ (NSTimeInterval) lastTouchTimestamp;
+ (UITouchManager*) sharedUITouchManager;

- (void) checkTouch:(UITouch*) touch forEndTimestamp:(NSTimeInterval) timestamp;
- (NSMutableArray*) removeTouch:(UITouch*) touch fromDealloc:(BOOL) fromDealloc;

@property (readonly) NSMutableDictionary* touchWindows;
@property (readonly) NSMutableDictionary* touchPaths;
@property (readonly) NSMutableDictionary* touchTags;
@property (readonly) NSMutableDictionary* touchDidFeedbacks;
@property (readwrite) NSTimeInterval lastTouchTimestamp;

@property (readonly) IMP UITouch_setTimestampImplementation;
@property (readonly) IMP UITouch_setLocationImplementation;
@property (readonly) IMP UITouch_dealloc;

@end
