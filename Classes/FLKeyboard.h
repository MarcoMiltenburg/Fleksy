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

- (void) setLowercaseKeys:(FLPoint[KEY_MAX_VALUE]) lowercase uppercaseKeys:(FLPoint[KEY_MAX_VALUE]) uppercase symbolsKeys1:(FLPoint[KEY_MAX_VALUE]) symbols1 symbolsKeys2:(FLPoint[KEY_MAX_VALUE]) symbols2;

// Singleton class accessor
+ (FLKeyboard*) sharedFLKeyboard;

- (void) disableQWERTYextraKeys;
- (void) enableQWERTYextraKeys;



@end