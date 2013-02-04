//
//  MyTextView.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/31/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "MyTextView.h"

@implementation MyTextView {

}

- (void) reloadInputViews {
  NSLog(@"MyTextView reloadInputViews called, self.isFirstResponder: %d", self.isFirstResponder);
  [super reloadInputViews];
}

//- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
//  NSLog(@"MyTextView textViewShouldEndEditing called");
//  return NO;
//}

@end
