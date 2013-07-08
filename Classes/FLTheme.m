//
//  FLTheme.m
//  iFleksy
//
//  Created by Vince Mansel on 7/6/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLTheme.h"

@implementation FLTheme

+ (id)theme {
  return [[self alloc] init];
}

- (void)themeDidChange:(FLThemeType)changedTheme {
  
}

- (UIColor *)window_backgroundColor {
  return FLEKSY_TEXTVIEW_COLOR;
}

- (UIColor *)textView_backgroundColor {
  return FLEKSY_TEXTVIEW_COLOR;
}

- (UIColor *)textView_textColor {
  return FLBlackColor;
}

- (UIColor *)actionButton_imageView_backgroundColor {
  return FLClearColor; //FLEKSY_TEXTVIEW_COLOR;
}

- (UIColor *)extraKeysBgView_backgroundColor {
  return FLBlackColor;
}

- (UIColor *)fleksyKeyboard_backgroundColor {
  return FLBlackColor;
}

- (UIColor *)topShadowView_backgroundColor {
  return FLBlackColor;
}

- (CGColorRef)topShadowView_layer_shadowColor {
  return [FLeksyColor CGColor];
}

- (UIColor *)customSegmentedControl_selectedTextColor {
  return FLWhiteColor;
}

- (UIColor *)customSegmentedControl_selectedBackgroundColor {
  return FLClearColor; //[UIColor darkGrayColor];
}

- (UIColor *)customSegmentedControl_defaultTextColor {
  return FLSuggestionWhiteColor;
}

- (UIColor *)keyboardImageView_keyLabelColor {
  return FLWhiteColor;
}

- (UIColor *)keyboardImageView_homeStripeBackgroundColor {
  return FLDarkSideWhite;
}

- (UIColor *)keyboardImageView_label_outlineColor {
  return FLBlackColor;
}

- (CGFloat)keyboardImageView_label_outlineWidth {
  return 2.0;
}

- (UIColor *)keyboardImageView_label_textColor {
  return FLWhiteColor;
}

- (UIColor *)keyboardImageView_label_textColorForPopup {
  return FLWhiteColor;
}

- (UIColor *)keyboardImageView_touchTrace_backgroundColor {
  return FLWhiteColor;
}

- (CGFloat)keyboardImageView_touchTrace_alpha {
  return 0.2;
}


@end
