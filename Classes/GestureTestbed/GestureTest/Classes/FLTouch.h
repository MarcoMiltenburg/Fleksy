//
//  FLTouch.h
//  GestureTest
//
//  Created by Kostas Eleftheriou on 11/13/12.
//  Copyright (c) 2012 Kostas Eleftheriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
  UITouchKindUnknown = 0,
  UITouchKindTap,
  UITouchKindSwipe,
  UITouchKindPhantomSwipeI,
  UITouchKindPhantomSwipeU,
} UITouchKind;


@interface FLTouch : NSObject {
@private
  NSArray* path;
}

- (id) initWithPath:(NSArray*) thePath kind:(UITouchKind) kind;
- (id) initFromString:(NSString*) swipeString;
+ (NSString*) stringForTouch:(UITouch*) touch kind:(UITouchKind) kind;

@property (readonly) NSArray* path;
@property (readonly) CGPoint startPoint;
@property (readonly) CGPoint endPoint;
@property (readonly) float endpointDistance;
@property (readonly) float travelDistance;
@property (readonly) float firstDistance;
@property (readonly) float lastDistance;
@property (readonly) float minimumDistance;
@property (readonly) float maximumDistance;
@property (readonly) float dt;
//http://stackoverflow.com/questions/3227176/error-writable-atomic-property-cannot-pair-a-synthesized-setter-getter-with-a-u
@property (nonatomic) BOOL useFirstPoint;
@property (nonatomic) BOOL useLastPoint;
@property UITouchKind kind;

@end
