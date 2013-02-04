//
//  FLKeyboard.m
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FLKeyboard.h"
#import "MathFunctions.h"
#import "FleksyUtilities.h"
#import "Settings.h"
#import "FLKeyboardContainerView.h"
#import "SynthesizeSingleton.h"
#import "FileManager.h"
#import "VariousUtilities.h"
#import "VariousUtilities2.h"

@implementation FLKeyboard

SYNTHESIZE_SINGLETON_FOR_CLASS(FLKeyboard);

- (void) loadDataFromFile:(NSString*) filename {
  
  NSString* myText = FLStringToNSString(VariousUtilities2::getStringFromFile(filename.UTF8String, true));
  NSArray* lines = [myText componentsSeparatedByString:@"\n"];
  
  CGPoint letterCoords[KEY_MAX_VALUE];  INIT_POINTS(letterCoords);
  CGPoint symbolCoordsA[KEY_MAX_VALUE]; INIT_POINTS(symbolCoordsA);
  CGPoint symbolCoordsB[KEY_MAX_VALUE]; INIT_POINTS(symbolCoordsB);
  
  imageViewABC      = [[KeyboardImageView alloc] initWithImage:nil];
  imageViewSymbolsA = [[KeyboardImageView alloc] initWithImage:nil];
  imageViewSymbolsB = [[KeyboardImageView alloc] initWithImage:nil];
  
  imageViewABC.tag      = KEYBOARD_IMAGE_TAG_ABC_UPPER;
  imageViewSymbolsA.tag = KEYBOARD_IMAGE_TAG_SYMBOLS1;
  imageViewSymbolsB.tag = KEYBOARD_IMAGE_TAG_SYMBOLS2;

  int nLine = 0;
  for (__strong NSString* line in lines) {
    
    line = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if ([line hasPrefix:@"//"] || [line length] == 0) {
      continue;
    }
    
    if (nLine == 0) {

      NSArray* fields = [line componentsSeparatedByString:@" "];
      width  = [((NSString*)[fields objectAtIndex:0]) floatValue];
      height = [((NSString*)[fields objectAtIndex:1]) floatValue];
      //NSLog(@"keyboard WIDTH: %.1f, HEIGHT: %.1f", width, height);
      
    } else {
      int type = VariousUtilities2::getCharacterLineType(NSStringToFLString(line));
      if (type == KEYBOARD_IMAGE_TAG_ABC_UPPER) {
        VariousUtilities2::readCharacterLine(NSStringToFLString(line), letterCoords, NULL);
      }
      if (type == KEYBOARD_IMAGE_TAG_SYMBOLS1) {
        VariousUtilities2::readCharacterLine(NSStringToFLString(line), symbolCoordsA, NULL);
      }
      if (type == KEYBOARD_IMAGE_TAG_SYMBOLS2) {
        VariousUtilities2::readCharacterLine(NSStringToFLString(line), symbolCoordsB, NULL);
      }
    }
    nLine++;
  }
  
  [imageViewABC      setKeys:letterCoords];
  [imageViewSymbolsA setKeys:symbolCoordsA];
  [imageViewSymbolsB setKeys:symbolCoordsB];
}


- (void)scrollViewWillBeginDragging:(UIScrollView*) scrollView {
  [super scrollViewWillBeginDragging:scrollView];
  [imageViewABC      hidePopupWithDuration:0 delay:0];
  [imageViewSymbolsA hidePopupWithDuration:0 delay:0];
  [imageViewSymbolsB hidePopupWithDuration:0 delay:0];
}

- (id) initWithFrame:(CGRect)frame keyboardFile:(NSString*) keyboardFile {

  [self loadDataFromFile:keyboardFile];
  loadedKeyboardFile = YES;
  
  if (self = [super initWithFrame:frame view1:imageViewABC view2A:imageViewSymbolsA view2B:imageViewSymbolsB]) {
    
    extraKeysBgView = [[UIView alloc] init];
    //extraKeysBgView.backgroundColor = [UIColor blackColor];
    extraKeysBgView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
    [self addSubview:extraKeysBgView];
    [self sendSubviewToBack:extraKeysBgView];
    
    //self.userInteractionEnabled = NO;
    
    //capsLock = NO;
    //self.backgroundColor = FacebookBlue;
    self.backgroundColor = [UIColor blackColor];
    
    shortcutKeysLetters = @"@.#$(:/5";
    shortcutKeysNumbers = @"@.#$(:/,";
    
    [self disableQWERTYextraKeys];
    [self reset];
  }
  return self;
}

- (id) init {
  loadedKeyboardFile = NO;
  return self;
}

- (void) layoutSubviews {
  //NSLog(@"FLKeyboard layoutSubviews, frame: %@, transform: %@", NSStringFromCGRect(self.frame), NSStringFromCGAffineTransform(self.transform));
  
  imageViewABC.frame      = self.bounds;
  imageViewSymbolsA.frame = self.bounds;
  imageViewSymbolsB.frame = self.bounds;
  
  [super layoutSubviews];
  if (self.isTracking || self.isDragging || self.isDecelerating) {
    return;
  }

  //NSLog(@"FLKeyboard layoutSubviews2 [%d], frame: %@, transform: %@", self.activeView.tag, NSStringFromCGRect(self.frame), NSStringFromCGAffineTransform(self.transform));
  
  //need to force call this because self.bounds might not have changed, but self.superview.bounds might be different
  //eg on orientation change.
  [imageViewABC setNeedsLayout];
  [imageViewSymbolsA setNeedsLayout];
  [imageViewSymbolsB setNeedsLayout];
  
  CGPoint q = [imageViewABC getKeyboardPointForChar:'Q'];
  CGPoint a = [imageViewABC getKeyboardPointForChar:'A'];
  float rowHeight = a.y - q.y;
  
  extraKeysBgView.frame = CGRectMake(0, -rowHeight, self.bounds.size.width, rowHeight);
  //NSLog(@"FLKeyboard layoutSubviews DONE");
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
