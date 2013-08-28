//
//  FleksyTextView.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/26/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FleksyTextView.h"
#import "VariousUtilities.h"
#import "Settings.h"
#import "FLThemeManager.h"

@implementation FleksyTextView

- (id) initWithFrame:(CGRect)frame {
  
  if (self = [super initWithFrame:frame]) {
    
    textView = [[MyTextView alloc] initWithFrame:self.bounds];
    
    float fontSize = [VariousUtilities deviceCanHandleLargeFont] ? 22 : 20;
    textView.font = [UIFont fontWithName:@"Arial" size:fontSize * (deviceIsPad() ? 1.5 : 1)];
    textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    textView.text = @"Loading";
    textView.editable = NO;
    textView.userInteractionEnabled = NO;
    textView.autocorrectionType = UITextAutocorrectionTypeNo;
    //this helps by ommiting a "dimmed. textfield" statement but value is still read back
    //textView.isAccessibilityElement = NO;
    //textView.textColor = [UIColor whiteColor];
    
//    id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
//    textView.backgroundColor = ((AppDelegate *)appDelegate).theme.textView_backgroundColor;
    
    //id<UIApplicationDelegate> appDelegate = [[UIApplication sharedApplication] delegate];
    //textView.backgroundColor = ((AppDelegate *)appDelegate).theme.textView_backgroundColor;
        
    textView.backgroundColor = FLEKSYTHEME.textView_backgroundColor;
    
    textView.textColor = FLEKSYTHEME.textView_textColor;
    textView.delegate = self;
    
    // dont clip, looks ugly when there is top padding and text has scrolled
    textView.clipsToBounds = NO;
    
    [self addSubview:textView];
    
    self.isAccessibilityElement = NO;
    
    if (self.isAccessibilityElement) {
      self.accessibilityTraits |= UIAccessibilityTraitAdjustable;
      self.accessibilityTraits |= UIAccessibilityTraitAllowsDirectInteraction;
      self.accessibilityLabel = @"Text area";
      self.accessibilityHint = @"Cursor is adjustable.";
    } else {
      self.accessibilityElementsHidden = YES;
      self.userInteractionEnabled = NO;
      self.accessibilityTraits = UIAccessibilityTraitNone;
      textView.isAccessibilityElement = NO;
      textView.accessibilityElementsHidden = YES;
      textView.userInteractionEnabled = NO;
      textView.accessibilityTraits = UIAccessibilityTraitNone;
    }
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    tapRecognizer.delaysTouchesBegan = YES;
    [self addGestureRecognizer:tapRecognizer];
    //
    //    cover = [[UIView alloc] initWithFrame:frame];
    //    cover.isAccessibilityElement = YES;
    //    cover.backgroundColor = [UIColor greenColor];
    //    cover.alpha = 0.2;
    //    [self addSubview:cover];
    
    cursorMoves = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged:) name:UIAccessibilityVoiceOverStatusChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeDidChange:) name:FleksyThemeDidChangeNotification object:nil];
  }
  return self;
}

#pragma mark - FLTheme Notification Handlers

- (void)handleThemeDidChange:(NSNotification *)aNote {
  NSLog(@"%s = %@", __PRETTY_FUNCTION__, aNote);
  textView.backgroundColor = FLEKSYTHEME.textView_backgroundColor;
  textView.textColor = FLEKSYTHEME.textView_textColor;
  [self setNeedsLayout];
}


- (void) setInputView:(FleksyKeyboard*) _customInputView {
  customInputView = _customInputView;
  textView.inputView = customInputView;
}

//- (CGPoint) accessibilityActivationPoint {
//  return CGPointMake(10, 10);
//}

- (void) setFrame:(CGRect)frame {
  NSLog(@"FleksyTextView setFrame %@", NSStringFromCGRect(frame));
  super.frame = frame;
}

- (void) layoutSubviews {
  NSLog(@"FleksyTextView layoutSubviews, self.bounds: %@, self.frame: %@", NSStringFromCGRect(self.bounds), NSStringFromCGRect(self.frame));
  float topPadding = deviceIsPad() ? 26 : 8;
  textView.frame = CGRectMake(0, topPadding, self.bounds.size.width, self.bounds.size.height - topPadding);
  cover.frame = textView.frame;
  //self.accessibilityActivationPoint = CGPointMake(8, 8);
}

- (void) tap:(id) object {
  NSLog(@"FleksyTextView tap!");
  if (UIAccessibilityIsVoiceOverRunning()) {
    if ([self cursorIsAtBeginningOfDocument]) {
      [self moveCursorToEndOfDocument];
    } else {
      [self moveCursorToBeginningOfDocument];
    }
    if (![textView isFirstResponder]) {
      NSLog(@"textView was not firstResponder, setting now");
      [textView becomeFirstResponder];
    }
  }
}

- (BOOL)accessibilityPerformEscape {
  NSLog(@"FleksyTextView accessibilityPerformEscape");
  return YES;
}

- (void)accessibilityIncrement {
  [self accessibilityMoveCursor:NO];
}

- (void)accessibilityDecrement {
  [self accessibilityMoveCursor:YES];
}

- (void)accessibilityMoveCursor:(BOOL) backward {
  UITextRange* range = [textView selectedTextRange];
  UITextPosition* newCursorPosition = [textView.tokenizer positionFromPosition:range.start toBoundary:UITextGranularityWord inDirection:backward ? UITextStorageDirectionForward : UITextStorageDirectionBackward];
  if (!newCursorPosition) {
    NSLog(@"FleksyTextView accessibilityMoveCursor no newCursorPosition1");
    return;
  }
  UITextRange* newRange = [textView textRangeFromPosition:newCursorPosition toPosition:newCursorPosition];
  if (!newRange) {
    NSLog(@"FleksyTextView accessibilityMoveCursor no new range");
    return;
  }
  
  [self setSelectedRange:newRange];
  
  UITextRange* changeRange = [textView textRangeFromPosition:range.start toPosition:newRange.start];
  NSString* value = [textView textInRange:changeRange];
  
//  if ([value isEqualToString:self.accessibilityValue]) {
    BOOL moved = ![range.start isEqual:newRange.start];
    NSLog(@"FleksyTextView range equality: %d", !moved);
#pragma unused(moved)
//  }
  
  self.accessibilityValue = value;
  
  //[VariousUtilities playTock];
  
  NSLog(@"FleksyTextView value: <%@>", self.accessibilityValue);
  
  //NSLog(@"selectedTextRange: %@", newRange);
}

- (void) setSelectedRange:(UITextRange*) range {
  textView.selectedTextRange = range;
  [textView scrollRangeToVisible:textView.selectedRange];
}

- (void) moveCursorToEndOfDocument {
  [self setSelectedRange:[textView textRangeFromPosition:textView.endOfDocument toPosition:textView.endOfDocument]];
  MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Insertion point at end");
}

- (void) moveCursorToBeginningOfDocument {
  [self setSelectedRange:[textView textRangeFromPosition:textView.beginningOfDocument toPosition:textView.beginningOfDocument]];
  MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Insertion point at start");
}

- (BOOL) cursorIsAtBeginningOfDocument {
  return textView.selectedRange.location == 0;
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  NSLog(@"FleksyTextView accessibilityScroll: %d", direction);
  // not used for now, beginning and end of document is done with double tap
  return YES;
  
  //UIAccessibilityPageScrolledNotification doesn't work when UITextView is in container view and not focused?
  switch (direction) {
    case UIAccessibilityScrollDirectionDown:
      [self moveCursorToBeginningOfDocument];
      MyAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, @"Insertion point at start");
      return YES;
      break;
      
    case UIAccessibilityScrollDirectionUp:
      [self moveCursorToEndOfDocument];
      MyAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, @"Insertion point at end");
      return YES;
      break;
      
    default:
      break;
  }

  return NO;
}

- (void) reloadInputViews {
  NSLog(@"FleksyTextView reloadInputViews");
  [textView reloadInputViews];
}

- (UIView*) inputView {
  return customInputView;
}

- (void) accessibilityElementDidBecomeFocused {
  NSLog(@"FleksyTextView accessibilityElementDidBecomeFocused, textView.isFirstResponder: %d", textView.isFirstResponder);
  self.accessibilityValue = textView.text;
  //[textView reloadInputViews];
}

- (void) makeReady {
  NSLog(@"%s",__PRETTY_FUNCTION__);
  textView.editable = YES;
  [self voiceOverStatusChanged:nil];
  [textView becomeFirstResponder];
}

- (void) voiceOverStatusChanged:(NSNotification*) notification {
  textView.userInteractionEnabled = NO; //!UIAccessibilityIsVoiceOverRunning();
}

- (NSString*) text {
  return textView.text;
}

- (void) setText:(NSString *)text {
  textView.text = text;
  self.accessibilityValue = text;
  MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, text);
}

- (void)scrollRangeToVisible:(NSRange)range {
  //NSLog(@"scroll %@", NSStringFromRange(range));
  [textView scrollRangeToVisible:range];
}


- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  NSLog(@"touches began FleksyTextView! %@", touches);
  for (UITouch* touch in touches) {
    CGPoint point = [touch locationInView:self];
    NSLog(@"point: %.3f %.3f", point.x, point.y);
    if (point.x == 1 && point.y == 1) {
      [VariousUtilities performAudioFeedbackFromString:@"Keyboard not active, single tap anywhere to activate"];
    }
  }
}


- (BOOL) textViewShouldBeginEditing:(UITextView *)textView {
  NSLog(@"textViewShouldBeginEditing");
  return YES;
}

- (BOOL) textViewShouldEndEditing:(UITextView *)textView {
  NSLog(@"textViewShouldEndEditing");
  return YES;
}

- (void) textViewDidBeginEditing:(UITextView *)aTextView {
  NSLog(@"[FleksyTextView textViewDidBeginEditing");
  // Forward this delegation to the client of the FleksyTextView that owns the external interface to the textView
  [self.fleksyTextViewDelegate textViewDidBeginEditing:aTextView];
}

- (void) textViewDidEndEditing:(UITextView *)textView {
  NSLog(@"textViewDidEndEditing");
}

- (BOOL) textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  NSLog(@"shouldChangeTextInRange");
  return YES;
}

- (void) textViewDidChange:(UITextView *)_textView {
  NSLog(@"textViewDidChange");
}

- (void) textViewDidChangeSelection:(UITextView *) _textView {
  NSLog(@"textViewDidChangeSelection: %@", NSStringFromRange(_textView.selectedRange));
}




- (BOOL)becomeFirstResponder {
  //BOOL result = [super becomeFirstResponder];
  return [textView becomeFirstResponder];
}


- (BOOL)resignFirstResponder {
  [textView resignFirstResponder];
  return [super resignFirstResponder];
}


@end
