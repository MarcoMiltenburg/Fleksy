//
//  FLThemeVanilla.m
//  iFleksy
//
//  Created by Vince Mansel on 7/6/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLThemeVanilla.h"

@implementation FLThemeVanilla

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
  return FLWhiteColor;
}

- (UIColor *)fleksyKeyboard_backgroundColor {
  return FLWhiteColor;
}

- (UIColor *)topShadowView_backgroundColor {
  return FLeksyColor;
}

- (CGColorRef)topShadowView_layer_shadowColor {
  return [FLeksyColor CGColor];
}

- (UIColor *)customSegmentedControl_selectedTextColor {
  return FLeksyColor;
}

- (UIColor *)customSegmentedControl_selectedBackgroundColor {
  return FLClearColor; //[UIColor darkGrayColor];
}

- (UIColor *)customSegmentedControl_defaultTextColor {
  return FLSuggestionWhiteColor;
}

- (UIColor *)keyboardImageView_keyLabelColor {
  //return FLBlackColor;
  return self.keyboardImageView_label_textColor;
}

- (UIColor *)keyboardImageView_homeStripeBackgroundColor {
  return FLLightGrayColor;
}

- (UIColor *)keyboardImageView_label_outlineColor {
  return FLClearColor;
}

- (CGFloat)keyboardImageView_label_outlineWidth {
  return 0.0;
}

- (UIColor *)keyboardImageView_label_textColor {
  //return FLBlackColor;
  return [UIColor colorWithWhite:0.2 alpha:1];
}

- (UIColor *)keyboardImageView_label_textColorForPopup {
  return FLBlackColor;
}

- (UIColor *)keyboardImageView_touchTrace_backgroundColor {
  return FLBlackColor;
}

- (CGFloat)keyboardImageView_touchTrace_alpha {
  return 0.2;
}

- (UIColor *)swipeFeedbackView_staticSubview_backgroundColor {
    return FLSwipeFeedbackLightSlateGrayColor;
}

@end
