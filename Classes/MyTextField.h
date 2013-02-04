//
//  MyTextField.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/10/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MyTextField <NSObject>

- (void) handleStringInput:(NSString*) s;
- (void) handleDelete:(int) n;
- (NSString*) handleReplaceRange:(NSRange) range withText:(NSString*) text;

//
//- (NSString *)textInRange:(UITextRange *)range;



- (NSString*) text;
- (NSString*) textUpToCaret;
//- (NSRange) moveCaret:(int) offset;
//- (NSString*) textForRange:(NSRange) range;

@end