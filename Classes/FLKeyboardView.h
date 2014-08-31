//
//  FLKeyboardView.h
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "CustomScrollView.h"
#import "KeyboardImageView.h"
#import "FLKeyboard.h"

@interface FLKeyboardView : CustomScrollView {
  
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
  
  FLKeyboard* keyboard;
}

- (void) setKeymaps:(FLPoint[FLKeyboardID_NUMBER_OF_KEYBOARDS][KEY_MAX_VALUE]) keymap;

// Singleton class accessor
+ (FLKeyboardView*) sharedFLKeyboardView;

- (void) disableQWERTYextraKeys;
- (void) enableQWERTYextraKeys;
- (BOOL) areExtraKeysEnabled;


@end