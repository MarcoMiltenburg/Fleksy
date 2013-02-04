//
//  CustomSegmentedControl.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 2/24/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "CustomSegmentedControl.h"
#import "VariousUtilities.h"

#define SEGMENTS_N 13
#define TAG_NO_TRAILING_SPACE 0
#define TAG_HAS_TRAILING_SPACE 1


@implementation CustomSegmentedControl

- (id) init {
    self = [super init];
    if (self) {
      
      //defaultBackgroundColor = [UIColor clearColor];
      selectedBackgroundColor = [UIColor clearColor]; //[UIColor darkGrayColor];
      defaultTextColor = [UIColor colorWithWhite:0.55 alpha:1];
      selectedTextColor = [UIColor whiteColor];
      
      //defaultTextColor = [UIColor clearColor];
      //selectedTextColor = [UIColor clearColor];
      
      float extra = deviceIsPad() ? 1.5 : 1;
      textFont = [UIFont fontWithName:@"HelveticaNeue" size:19 * extra];
      selectedTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:21 * extra];
      largeTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:22 * extra];
      largeSelectedTextFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:23 * extra];
      
      selectionView = [[UIView alloc] init];
      selectionView.backgroundColor = selectedBackgroundColor;
      [self addSubview:selectionView];
      
      labels = [[NSMutableArray alloc] init];
      for (int i = 0; i < SEGMENTS_N; i++) {
        //Instead of UILabel we use UITextField which has vertical alignment option. OPT: 5 times slower than UILabel
        UITextField* label = [[UITextField alloc] init];
        label.contentVerticalAlignment = UIControlContentVerticalAlignmentBottom;
        label.userInteractionEnabled = NO;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = defaultTextColor;
        label.textAlignment = NSTextAlignmentCenter; // UITextAlignmentCenter;
        label.font = textFont;
        [self addSubview:label];
        [labels addObject:label];
      }
      
      [self clear];
    }
    return self;
}

- (void) resetCurrentLabel {
  if (selectedIndex != UISegmentedControlNoSegment) {
    UILabel* previousLabel = [labels objectAtIndex:selectedIndex];
    previousLabel.textColor = defaultTextColor;
    previousLabel.font = previousLabel.font == largeSelectedTextFont ? largeTextFont : textFont;
    
    if (differentFirst && selectedIndex == 0) {
      previousLabel.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:previousLabel.font.pointSize];
    }
  }
}

- (void) clear {
  for (UIView* label in labels) {
    label.hidden = YES;
  }
  [self resetCurrentLabel];
  selectedIndex = UISegmentedControlNoSegment;
  currentSegments = 0;
}

- (void) setItems:(NSArray*) items differentFirst:(BOOL) _differentFirst large:(BOOL) _large {
  
  differentFirst = _differentFirst;
  //large = [[items objectAtIndex:0] hasPrefix:@"."];
  large = _large;
  
  float x = 0;
  int i = 0;
  for (NSString* title in items) {
    UILabel* label = [labels objectAtIndex:i];
    if ([title hasSuffix:@" "]) {
      label.tag = TAG_HAS_TRAILING_SPACE;
      label.text = [title substringToIndex:title.length-1];
    } else {
      label.tag = TAG_NO_TRAILING_SPACE;
      label.text = title;
    }
    label.textAlignment = NSTextAlignmentCenter;
    label.font = large ? largeTextFont : textFont;
    label.hidden = NO;
    
    CGSize expectedLabelSize = [label.text sizeWithFont:large ? largeSelectedTextFont : selectedTextFont 
                                      constrainedToSize:CGSizeMake(1000, 1000) 
                                          lineBreakMode:NSLineBreakByClipping]; //UILineBreakModeClip
    
    float width = expectedLabelSize.width;
    float padding = 10 + 75.0 / powf(fmax(title.length, 2), 2);
    width += padding * (deviceIsPad() ? 1.5 : 1);
    
    
    label.frame = CGRectMake(x, 0, width, self.bounds.size.height);
    
    if (differentFirst && i == 0) {
      label.font = [UIFont fontWithName:@"HelveticaNeue-Italic" size:label.font.pointSize];
    }
    
    x += width;
    i++;
  }
  
  currentSegments = [items count];
}

- (void) setSelectedIndex:(int) index {
  
  if (index < 0 || index >= SEGMENTS_N) {
    NSLog(@"warning: setSelectedIndex %d out of bounds", index);
    return;
  }
  
  [self resetCurrentLabel];
  
  UILabel* label = [labels objectAtIndex:index];
  label.textColor = selectedTextColor;
  label.font = large ? largeSelectedTextFont : selectedTextFont;
  
  if (differentFirst && index == 0) {
    label.font = [UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:label.font.pointSize];
  }
  
  double duration = selectedIndex == UISegmentedControlNoSegment ? 0 : 0.08;
  [UIView animateWithDuration:duration animations:^{selectionView.frame = label.frame;} completion:nil];
  
  self->selectedIndex = index;
}

- (int) selectedIndex {
  return self->selectedIndex;
}

- (UIView*) selectedView {
  if (selectedIndex == UISegmentedControlNoSegment) {
    return nil;
  }
  return [labels objectAtIndex:selectedIndex];
}

- (NSString*) titleForSegmentAtIndex:(int) index {
  UILabel* label = [labels objectAtIndex:index];
  return label.tag == TAG_HAS_TRAILING_SPACE ? [NSString stringWithFormat:@"%@ ", label.text] : label.text;
}

- (int) indexOfTitle:(NSString*) title {
  for (UILabel* label in labels) {
    if ([[label.text uppercaseString] hasPrefix:[title uppercaseString]]) {
      return [labels indexOfObject:label];
    }
  }
  return -1;
}

- (int) numberOfSegments {
  return currentSegments;
}

- (float) currentWidth {
  if (!currentSegments) {
    return 0;
  }
  UILabel* lastLabel = [labels objectAtIndex:currentSegments-1];
  return lastLabel.frame.origin.x + lastLabel.frame.size.width;
}

- (int) indexOfItemNearestX:(float) x {
  
  float minDistance = MAXFLOAT;
  int minIndex = -1;
  int i = 0;
  for (UITextField* label in labels) {
    float distance = fabs(label.center.x - x);
    if (distance < minDistance) {
      minDistance = distance;
      minIndex = i;
    }
    i++;
  }
  return minIndex;
}

@end
