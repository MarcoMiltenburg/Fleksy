//
//  FLThemeMidnight.m
//  iFleksy
//
//  Created by Vince Mansel on 7/7/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLThemeMidnight.h"

@implementation FLThemeMidnight


- (UIColor *)window_backgroundColor {
  return FLBlackColor;
}

- (UIColor *)textView_backgroundColor {
  return FLBlackColor;
}

- (UIColor *)textView_textColor {
  return FLeksyColor;
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
  return FLeksyColor;
}

- (UIColor *)customSegmentedControl_selectedBackgroundColor {
  return FLClearColor; //[UIColor darkGrayColor];
}

- (UIColor *)customSegmentedControl_defaultTextColor {
  return FLSuggestionWhiteColor;
}

- (UIColor *)keyboardImageView_keyLabelColor {
  //return FLWhiteColor;
  return FLeksyColor;
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
  //return FLWhiteColor;
  return FLeksyColor;
}

- (UIColor *)keyboardImageView_label_textColorForPopup {
//  return FLWhiteColor;
  return FLeksyColor;
}

- (UIColor *)keyboardImageView_touchTrace_backgroundColor {
  return FLWhiteColor;
}

- (CGFloat)keyboardImageView_touchTrace_alpha {
  return 0.2;
}

- (UIColor *)swipeFeedbackView_staticSubview_backgroundColor {
  return FLSwipeFeedbackWhiteColor;
}

@end
