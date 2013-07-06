//
//  FLKeyboardView.m
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FLKeyboardView.h"
#import "MathFunctions.h"
#import "FleksyUtilities.h"
#import "Settings.h"
#import "FLKeyboardContainerView.h"
#import "SynthesizeSingleton.h"
#import "FileManager.h"
#import "VariousUtilities.h"
#import "VariousUtilities2.h"

@implementation FLKeyboardView

SYNTHESIZE_SINGLETON_FOR_CLASS(FLKeyboardView);

- (void) setKeymaps:(FLPoint[FLKeyboardID_NUMBER_OF_KEYBOARDS][KEY_MAX_VALUE]) keymap {

  [imageViewABC      setKeys:keymap[FLKeyboardID_QWERTY_UPPER]];
  [imageViewSymbolsA setKeys:keymap[FLKeyboardID_NUMBERS]];
  [imageViewSymbolsB setKeys:keymap[FLKeyboardID_SYMBOLS]];
  
  [self disableQWERTYextraKeys];
  [self reset];
  
  loadedKeyboardFile = YES;
}


- (void)scrollViewWillBeginDragging:(UIScrollView*) scrollView {
  [super scrollViewWillBeginDragging:scrollView];
  [imageViewABC      hidePopupWithDuration:0 delay:0];
  [imageViewSymbolsA hidePopupWithDuration:0 delay:0];
  [imageViewSymbolsB hidePopupWithDuration:0 delay:0];
}

- (id) initWithFrame:(CGRect)frame {

  imageViewABC      = [[KeyboardImageView alloc] initWithImage:nil];
  imageViewSymbolsA = [[KeyboardImageView alloc] initWithImage:nil];
  imageViewSymbolsB = [[KeyboardImageView alloc] initWithImage:nil];
  
  imageViewABC.tag      = FLKeyboardID_QWERTY_UPPER;
  imageViewSymbolsA.tag = FLKeyboardID_NUMBERS;
  imageViewSymbolsB.tag = FLKeyboardID_SYMBOLS;
  
  if (self = [super initWithFrame:frame view1:imageViewABC view2A:imageViewSymbolsA view2B:imageViewSymbolsB]) {
    
    extraKeysBgView = [[UIView alloc] init];
    //TODO: Theme Vanilla
    //extraKeysBgView.backgroundColor = [UIColor blackColor];
    extraKeysBgView.backgroundColor = FLWhiteColor;
    [self addSubview:extraKeysBgView];
    [self sendSubviewToBack:extraKeysBgView];
    
    //self.userInteractionEnabled = NO;
    
    //capsLock = NO;
    //self.backgroundColor = FacebookBlue;
    //TODO: Theme Vanilla
    //self.backgroundColor = [UIColor blackColor];
    self.backgroundColor = FLWhiteColor;

    
    shortcutKeysLetters = @"@.#$(:/5";
    shortcutKeysNumbers = @"@.#$(:/,";
  }
  return self;
}

- (id) init {
  loadedKeyboardFile = NO;
  return self;
}

- (void) layoutSubviews {
  NSLog(@"FLKeyboardView layoutSubviews, frame: %@, transform: %@", NSStringFromCGRect(self.frame), NSStringFromCGAffineTransform(self.transform));
  
  imageViewABC.frame      = self.bounds;
  imageViewSymbolsA.frame = self.bounds;
  imageViewSymbolsB.frame = self.bounds;
  
  [super layoutSubviews];
  if (self.isTracking || self.isDragging || self.isDecelerating) {
    return;
  }

  //NSLog(@"FLKeyboardView layoutSubviews2 [%d], frame: %@, transform: %@", self.activeView.tag, NSStringFromCGRect(self.frame), NSStringFromCGAffineTransform(self.transform));
  
  //need to force call this because self.bounds might not have changed, but self.superview.bounds might be different
  //eg on orientation change.
  [imageViewABC setNeedsLayout];
  [imageViewSymbolsA setNeedsLayout];
  [imageViewSymbolsB setNeedsLayout];
  
  CGPoint q = [imageViewABC getKeyboardPointForChar:'Q'];
  CGPoint a = [imageViewABC getKeyboardPointForChar:'A'];
  float rowHeight = a.y - q.y;
  
  extraKeysBgView.frame = CGRectMake(0, -rowHeight, self.bounds.size.width, rowHeight);
  //NSLog(@"FLKeyboardView layoutSubviews DONE");
}

- (void) disableQWERTYextraKeys {
  [imageViewABC disableKey:'\t'];
  [imageViewABC disableKey:'\n'];
  //
  extraKeysBgView.hidden = YES;
  for (int i = 0; i < shortcutKeysLetters.length; i++) {
    [imageViewABC disableKey:[shortcutKeysLetters characterAtIndex:i]];
  }
  for (int i = 0; i < shortcutKeysNumbers.length; i++) {
    [imageViewSymbolsA disableKey:[shortcutKeysNumbers characterAtIndex:i]];
  }
}

- (void) enableQWERTYextraKeys {
  extraKeysBgView.hidden = NO;
  if (self.activeView == imageViewABC) {
    [imageViewABC enableKey:'\t'];
    [imageViewABC enableKey:'\n'];
    for (int i = 0; i < shortcutKeysLetters.length; i++) {
      [imageViewABC enableKey:[shortcutKeysLetters characterAtIndex:i]];
    }
  } else if (self.activeView == imageViewSymbolsA) {
    for (int i = 0; i < shortcutKeysNumbers.length; i++) {
      [imageViewSymbolsA enableKey:[shortcutKeysNumbers characterAtIndex:i]];
    }
  }
}

//if the pan gesture recognizer doesnt accept a touch, it will fall back
//to our view here, where we dont want to handle it at all
- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  NSLog(@"touches began keyboard! %@", touches);
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesMoved:touches withEvent:event];
  NSLog(@"touches moved keyboard! %@", touches);
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesEnded:touches withEvent:event];
  NSLog(@"touches ended keyboard! %@", touches);
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesCancelled:touches withEvent:event];
  NSLog(@"touches cancelled keyboard! %@", touches);
}

@end
