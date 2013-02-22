//
//  FLKeyboard.h
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "CustomScrollView.h"
#import "KeyboardImageView.h"

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

- (void) setKeymaps:(FLPoint[4][KEY_MAX_VALUE]) keymap;

// Singleton class accessor
+ (FLKeyboard*) sharedFLKeyboard;

- (void) disableQWERTYextraKeys;
- (void) enableQWERTYextraKeys;



@end