//
//  MyTextView.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/31/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "MyTextView.h"
#import "Settings.h"

@implementation MyTextView {

}

- (void) reloadInputViews {
  NSLog(@"MyTextView reloadInputViews called, self.isFirstResponder: %d", self.isFirstResponder);
  [super reloadInputViews]; // 'NSGenericException', reason: '*** Collection <CALayerArray: 0xf060c10> was mutated while being enumerated.'
  //[super performSelectorOnMainThread:@selector(reloadInputViews) withObject:nil waitUntilDone:NO]; // infinite recursion
}

//- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
//  NSLog(@"MyTextView textViewShouldEndEditing called");
//  return NO;
//}

@end
