//
//  KeyboardImageView.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/9/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "FleksyDefines.h"
//#import "AUIAnimatableLabel.h"
#import <PatternRecognizer/Structures.h>
#import "KSLabel.h"

@interface KeyboardImageView : UIImageView {
@private
  UIView* popupView;
  UIImageView* imageView;
  UIView* popupInnerView;
  
  CGPoint keyPoints[KEY_MAX_VALUE];
  CGPoint disabledKeyPoints[KEY_MAX_VALUE];
  
  NSMutableDictionary* keyLabels;
  NSMutableDictionary* keyPopupLabels;
  
  NSMutableArray* centroids;
  //UITapGestureRecognizer* tapRecognizer;

  UIView* homeRowStripe;
  
  CGAffineTransform lastTransform;
}

//@property (readonly) UITapGestureRecognizer* tapRecognizer;
- (void) setKeys:(FLPoint[]) _keys;
- (FLChar) getNearestCharForPoint:(CGPoint) target;
- (CGPoint) getKeyboardPointForChar:(FLChar) c;
- (void) doPopupForTouch:(UITouch*) touch;
- (void) hidePopupWithDuration:(float) duration delay:(float) delay;
- (void) disableKey:(FLChar) c;
- (void) enableKey:(FLChar) c;
- (void) restoreAllKeyLabelsWithDuration:(float) duration delay:(float) delay;

- (void) highlightKeysForWord:(NSString*) wordString;
- (void) unhighlightAllKeys;

@end
