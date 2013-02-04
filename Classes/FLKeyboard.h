//
//  FLKeyboard.h
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "CustomScrollView.h"
#import "KeyboardImageView.h"

#define KEYBOARD_IMAGE_TAG_ABC_LOWER 0
#define KEYBOARD_IMAGE_TAG_ABC_UPPER 1
#define KEYBOARD_IMAGE_TAG_SYMBOLS1  2
#define KEYBOARD_IMAGE_TAG_SYMBOLS2  3


@interface FLKeyboard : CustomScrollView {
  
@public
  float width;
  float height;
  KeyboardImageView* imageViewABC;
  KeyboardImageView* imageViewSymbolsA;
  KeyboardImageView* imageViewSymbolsB;
  
  UIView* extraKeysBgView;
  NSString* shortcutKeysLetters;
  NSString* shortcutKeysNumbers;
  
  BOOL loadedKeyboardFile;
}

- (id) initWithFrame:(CGRect)frame keyboardFile:(NSString*) keyboardFile;

// Singleton class accessor
+ (FLKeyboard*) sharedFLKeyboard;

- (void) disableQWERTYextraKeys;
- (void) enableQWERTYextraKeys;



@end