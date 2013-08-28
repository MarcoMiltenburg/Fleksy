//
//  FleksyTextView.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/26/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FleksyKeyboard.h"
#import "MyTextView.h"

/// [UIColor colorWithRed:1 green:1 blue:0.7 alpha:1];

@protocol FleksyTextViewDelegate <NSObject>

- (void) textViewDidBeginEditing:(UITextView *)aTextView;

@end

@interface FleksyTextView : UIView <UITextViewDelegate> {
  FleksyKeyboard* customInputView;
  MyTextView* textView;
  UIView* cover;
  UITapGestureRecognizer* tapRecognizer;
  int cursorMoves;
}

- (void) makeReady;
- (void) reloadInputViews;
- (void) scrollRangeToVisible:(NSRange)range;
- (void) setInputView:(FleksyKeyboard*) customInputView;

@property (nonatomic,copy) NSString *text;
@property (nonatomic, assign) id<FleksyTextViewDelegate> fleksyTextViewDelegate;

@end
