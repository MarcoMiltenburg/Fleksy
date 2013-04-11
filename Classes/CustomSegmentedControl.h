//
//  CustomSegmentedControl.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 2/24/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomSegmentedControl : UIView {
  
  NSMutableArray* labels;
  int selectedIndex;
  int currentSegments;
  
  UIView* selectionView;
  
  //UIColor* defaultBackgroundColor;
  UIColor* selectedBackgroundColor;
  UIColor* defaultTextColor;
  UIColor* selectedTextColor;
  UIFont* textFont;
  UIFont* selectedTextFont;
  UIFont* largeTextFont;
  UIFont* largeSelectedTextFont;
  
  BOOL large;
  BOOL differentFirst;
}

- (id) initWithVertical:(BOOL) vertical;
- (void) clear;
- (void) setItems:(NSArray*) items differentFirst:(BOOL) _differentFirst large:(BOOL) large;
- (UIView*) selectedView;
- (NSString*) titleForSegmentAtIndex:(int) index;
- (int) indexOfTitle:(NSString*) title;
- (int) indexOfItemNearestX:(float) x;

@property int selectedIndex;
@property (readonly) int numberOfSegments;
@property (readonly) CGSize currentSize;
@property BOOL vertical;

@end
