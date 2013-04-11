//
//  UIRotorRecognizer.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 5/12/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface UIRotorRecognizer : UIRotationGestureRecognizer<UIGestureRecognizerDelegate> {
  
  id originalTarget;
  SEL originalAction;
  
  int slices;
  
  int previousPosition;
  int position;
  int positionSinceLastTouchDown;
}

@property int slices;
@property (readonly) int position;
@property (readonly) int previousPosition;

@end
