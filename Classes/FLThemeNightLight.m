//
//  FLThemeNightLight.m
//  iFleksy
//
//  Created by Vince Mansel on 7/6/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLThemeNightLight.h"

@implementation FLThemeNightLight

- (UIColor *)window_backgroundColor {
  return FLBlackColor;
}

- (UIColor *)textView_backgroundColor {
  return FLBlackColor;
}

- (UIColor *)textView_textColor {
  return FLWhiteColor;
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
  return FLBlackColor;
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
  return FLBlackColor;
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
