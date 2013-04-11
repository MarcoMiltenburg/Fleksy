//
//  UICustomTapGestureRecognizer.h
//  EasyType
//
//  Created by Kostas Eleftheriou on 1/10/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIGestureRecognizerSubclass.h>

@interface TouchData : NSObject {
@public
  CGPoint startLocation;
  double startTime;
  NSTimer* timer;
}
@end

@interface UICustomTapGestureRecognizer : UIGestureRecognizer<UIGestureRecognizerDelegate> {

  NSMutableDictionary* trackedTouches;
  NSMutableArray* pendingTouches;
}

- (TouchData*) popNextPendingTouch;

@end
