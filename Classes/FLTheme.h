//
//  FLTheme.h
//  iFleksy
//
//  Created by Vince Mansel on 7/6/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

// Main Base Class - Normal, otherwise known as DarkSide

#import <Foundation/Foundation.h>

typedef enum {
  FLThemeTypeNormal,
  FLThemeTypeVanilla,
  FLThemeTypeNightLight,
  FLThemeTypeMidnight,
  FLThemeTypeIOS7,
} FLThemeType;

@interface FLTheme : NSObject
/**
 * Initialize the theme. 
 *
 * Storage Requirement: Hold an instance in the sending object
 *
 */
+ (id)theme;

@property (        nonatomic) FLThemeType currentThemeType;

@property (strong, nonatomic) UIColor *window_backgroundColor;
@property (strong, nonatomic) UIColor *textView_backgroundColor;
@property (strong, nonatomic) UIColor *textView_textColor;
@property (strong, nonatomic) UIColor *actionButton_imageView_backgroundColor;
@property (strong, nonatomic) UIColor *extraKeysBgView_backgroundColor;
@property (strong, nonatomic) UIColor *fleksyKeyboard_backgroundColor;
@property (strong, nonatomic) UIColor *topShadowView_backgroundColor;
@property (        nonatomic) CGColorRef topShadowView_layer_shadowColor;

@property (strong, nonatomic) UIColor *customSegmentedControl_selectedTextColor;
@property (strong, nonatomic) UIColor *customSegmentedControl_selectedBackgroundColor;
@property (strong, nonatomic) UIColor *customSegmentedControl_defaultTextColor;

@property (strong, nonatomic) UIColor *keyboardImageView_keyLabelColor;
@property (strong, nonatomic) UIColor *keyboardImageView_homeStripeBackgroundColor;
@property (strong, nonatomic) UIColor *keyboardImageView_label_outlineColor;
@property (        nonatomic) CGFloat  keyboardImageView_label_outlineWidth;
@property (strong, nonatomic) UIColor *keyboardImageView_label_textColor;
@property (strong, nonatomic) UIColor *keyboardImageView_label_textColorForPopup;
@property (strong, nonatomic) UIColor *keyboardImageView_touchTrace_backgroundColor;
@property (        nonatomic) CGFloat  keyboardImageView_touchTrace_alpha;

@property (strong, nonatomic) UIColor *swipeFeedbackView_staticSubview_backgroundColor;
@end

#pragma mark - Color Definitions

// http://www.tayloredmktg.com/rgb/

//FSA15FLVars_Colour_WHITE_ = [AndroidGraphicsColor rgbWithInt:225 withInt:225 withInt:225];
#define FleksyWhiteColor [UIColor colorWithRed:(225.0/255.0) green:(225.0/255.0) blue:(225.0/255.0) alpha:1.0]

//#define FLEKSY_TEXTVIEW_COLOR [UIColor colorWithRed:0.929 green:0.925 blue:0.878 alpha:1]
#define FLEKSY_TEXTVIEW_COLOR FleksyWhiteColor
#define FacebookBlue [UIColor colorWithRed:0.23 green:0.35 blue:0.59 alpha:1]

//FSA15FLVars_Colour_FLBLACK_ = [AndroidGraphicsColor rgbWithInt:25 withInt:25 withInt:25];
#define FLBlackColor [UIColor colorWithRed:(25.0/255.0) green:(25.0/255.0) blue:(25.0/255.0) alpha:1.0]
//FSA15FLVars_Colour_FLEKSY_ = [AndroidGraphicsColor rgbWithInt:52 withInt:160 withInt:194];
#define FLeksyColor [UIColor colorWithRed:(52.0/255.0) green:(160.0/255.0) blue:(194.0/255.0) alpha:1.0]

#define FLWhiteColor [UIColor colorWithWhite:1.0 alpha:1.0]
#define FLSuggestionWhiteColor [UIColor colorWithWhite:0.55 alpha:1.0]
#define FLSwipeFeedbackWhiteColor [UIColor colorWithWhite:1 alpha:0.35]
//Light Gray	211-211-211	d3d3d3
#define FLSwipeFeedbackLightGrayColor [UIColor colorWithRed:(211.0/255.0) green:(211.0/255.0) blue:(211.0/255.0) alpha:0.35]
#define FLSwipeFeedbackGrayColor [UIColor colorWithRed:(190.0/255.0) green:(190.0/255.0) blue:(190.0/255.0) alpha:0.35]
#define FLSwipeFeedbackLightSlateGrayColor [UIColor colorWithRed:(119.0/255.0) green:(136.0/255.0) blue:(153.0/255.0) alpha:0.35]

#define FLDarkSideWhite [UIColor colorWithWhite:1 alpha:0.2]

#define FLLightGrayColor [UIColor lightGrayColor]
#define FLGrayColor [UIColor grayColor];
#define FLDarkGrayColor [UIColor darkGrayColor]
#define FLClearColor [UIColor clearColor]




