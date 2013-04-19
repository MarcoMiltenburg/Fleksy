//
//  FLSuggestionsView.m
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FLSuggestionsView.h"
#import "FLWord.h"
#import "MathFunctions.h"
#import "FleksyUtilities.h"
#import "FLKeyboardContainerView.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "FLKeyboardContainerView.h"
#import "FLKeyboard.h"
#import "VariousUtilities.h"
#import <QuartzCore/QuartzCore.h>

#define RAW_TAG 999

//3
#define PADDING_LEFT 0

#define FULL_ALPHA 0.85

#define LOOKAHEAD_PADDING 100

@implementation FLSuggestionsView

- (void) recreateCustomSegmentedControlWithItems:(NSArray*) items differentFirst:(BOOL) differentFirst {
  
  //double startTime = CFAbsoluteTimeGetCurrent();
  
  
  [customSegmentedControl clear];
  [customSegmentedControl setItems:items differentFirst:differentFirst large:!needsSpellingFeedback];
  
  bg.contentSize = customSegmentedControl.currentSize;// customSegmentedControl.frame.size;
  
  //[segmentedControl layoutSubviews];
  
  hasBeenDismissed = NO;
  lastInteractedTime = CFAbsoluteTimeGetCurrent();
  
  //NSLog(@"recreated custom in %.6f", CFAbsoluteTimeGetCurrent() - startTime);
}


//- (float) height {
//  return segmentedControl.frame.size.height;
//}

- (void) layoutSubviews {
  
  NSLog(@"FLSuggestionsView layoutSubviews %@", NSStringFromCGRect(self.frame));
  
  bg.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
  
  if (self.vertical) {
    customSegmentedControl.frame = CGRectMake(0, 0, self.bounds.size.width, 1999);
  } else {
    customSegmentedControl.frame = CGRectMake(0, 0, 1999, self.bounds.size.height);
  }
}

- (void) reset {
  [customSegmentedControl clear];
  [self hide];
}

- (id) initWithListener:(id) _listener {
  if ( (self = [super init]) ) {
    // Initialization code
    
    self.vertical = NO;

    self->listener = _listener;
    self->capitalization = nil;
    
    [self hide];
    self.backgroundColor = [UIColor clearColor];

    bg = [[UIScrollView alloc] init];
    bg.backgroundColor = [UIColor clearColor];
    [self addSubview:bg];
    
    //allow rest of contents to be visible outside
    //our frame is smaller than width of screen so that
    //scrollRectToVisible happens before we reach the end (so we can see whats coming)
    self.clipsToBounds = YES;
    bg.clipsToBounds = NO;
    
    
    customSegmentedControl = [[CustomSegmentedControl alloc] initWithVertical:self.vertical];
    customSegmentedControl.backgroundColor = [UIColor clearColor];
    [bg addSubview:customSegmentedControl];

    self.userInteractionEnabled = NO;
    self.needsSpellingFeedback = YES;
    
  }
  return self;
}

- (int) indexOfCandidateWithLetters:(NSString*) letters inList:(NSArray*) suggestions {
  int i = 0;
  for (NSValue* value in suggestions) {
    FLResponseEntry* entry = (FLResponseEntry*) [value pointerValue];
    FLString s(entry->letters, entry->lettersN);
    NSString* string1 = FLStringToNSString(s);
    
    if ([string1 caseInsensitiveCompare:letters] == NSOrderedSame) {
      return i;
    }
    i++;
  }
  return NSNotFound;
}

- (BOOL) shouldInsertSuggestion:(NSString*) text inList:(NSArray*) suggestions {
  
  if ([text length] == 0) {
    return NO;
  }
  
  return [self indexOfCandidateWithLetters:text inList:suggestions] == NSNotFound;
}

- (void) bounce:(float) bounce {
  
  float x1; //= bg.contentOffset.x + bounce;
  float x2; //= bg.contentOffset.x - bounce;
  
  float y1;
  float y2;
  
  if (bounce > 0) {
    x2 = customSegmentedControl.currentSize.width - self.bounds.size.width;
    x2 = fmax(x2, bg.contentOffset.x);
    y2 = customSegmentedControl.currentSize.height - self.bounds.size.height;
    y2 = fmax(y2, bg.contentOffset.y);
  } else {
    x2 = 0;
    y2 = 0;
  }
  
  x1 = x2 + bounce;
  y1 = y2 + bounce;
  
  if (self.vertical) {
    x1 = 0;
    x2 = 0;
  } else {
    y1 = 0;
    y2 = 0;
  }
  
  BOOL previousAnimationsState = [UIView areAnimationsEnabled];
  [UIView setAnimationsEnabled:YES];
  [UIView animateWithDuration:0.1
                        delay:0.0
                      options:0
                   animations:^{
                     [bg setContentOffset:CGPointMake(x1, y1)];
                   }
                   completion:^(BOOL finished){
                     BOOL previousAnimationsState2 = [UIView areAnimationsEnabled];
                     [UIView setAnimationsEnabled:YES];
                     [UIView animateWithDuration:0.25
                                           delay:0
                                         options:0
                                      animations:^{
                                        [bg setContentOffset:CGPointMake(x2, y2)];
                                      }
                                      completion:^(BOOL finished){
                                      }];
                     [UIView setAnimationsEnabled:previousAnimationsState2];
                   }];
  [UIView setAnimationsEnabled:previousAnimationsState];
}



- (void) speechEnded {
  self->givingSpellingFeedback = NO;
}

- (void) spellWord:(NSString*) wordString {
  
  NSLog(@"spellWord: %@", wordString);
  
  // use the user-capitalized version of the word
  NSString* capitalizedWord = [VariousUtilities capitalizeString:wordString basedOn:self.capitalization];

  // now we just need to create the NSStrings parts and pass them on to the MultipartSpeechSynthesizer
  NSMutableArray* parts = [[NSMutableArray alloc] init];
  for (int i = 0; i < capitalizedWord.length; i++) {
    unichar c = [capitalizedWord characterAtIndex:i];
    NSString* temp = [NSString stringWithCharacters:&c length:1];
    FLString s = NSStringToFLString(temp);
    [parts addObject:[VariousUtilities descriptionForCharacter:s[0]]];
  }
  
  speech = [[MultipartSpeechSynthesizer alloc] initWithParts:parts listener:self];
  [speech start];
  self->givingSpellingFeedback = YES;
  return;
}

- (void) cancelAllSpellingRequests {
  [NSObject cancelPreviousPerformRequestsWithTarget:self];// selector:@selector(spellWord:) object:nil];
  
  //only stop if we were spelling, not if speaking last word
  if (self->givingSpellingFeedback) {
    [speech stop];
  }
}

- (void) selectSuggestionWithOffset:(int) offset replaceText:(BOOL) replace scroll:(BOOL) scroll notifyListener:(BOOL) notifyListener {
  
  [self.layer removeAllAnimations];
  self.alpha = FULL_ALPHA;
  
  FLTypingController_iOS* typingController = (FLTypingController_iOS*) listener;
  
  if ([self isHidden]) {
    NSLog(@"WARNING, selectSuggestionWithOffset but isHidden");
  }
  
  int selectedIndexOld = customSegmentedControl.selectedIndex;
  int selectedIndexNew = selectedIndexOld + offset;
  
  //NSLog(@"selectSuggestionWithOffset: %d, old: %d, new: %d", offset, selectedIndexOld, selectedIndexNew);
  
  int numberOfSegments = customSegmentedControl.numberOfSegments;
  if (!numberOfSegments) {
    NSLog(@"!customSegmentedControl.numberOfSegments");
    return;
  }
  
  BOOL speak = YES;
  
  if (selectedIndexNew >= numberOfSegments) {
    selectedIndexNew = numberOfSegments-1;
    [VariousUtilities vibrate];
    [self bounce:10];
    [typingController playError]; //end of list
  }
  
  if (selectedIndexNew < 0) {
    selectedIndexNew = 0;
    [VariousUtilities vibrate];
    [self bounce:-10];
    
    NSString* wordToAddRemove = [customSegmentedControl titleForSegmentAtIndex:0];
    
    if (self->hasPreciseRawWord && wordToAddRemove.length > 2) {
      //NSLog(@"Should add word %@ to dictionary", wordToAdd);
      [typingController addRemoveUserWord:wordToAddRemove];
      speak = NO;
    } else {
      [typingController playError]; //end of list
    }
  }
  
  
  //new line
//  if ([[segmentedControl titleForSegmentAtIndex:selectedIndexNew] compare:NEWLINE_UI_CHAR] == NSOrderedSame && offset < 0) {
//    
//    [typingController nonLetterCharInput:'\n'];
//    
//    //now remove other suggestions, they are consusing since they would change far earlier punctuation mark
//    //since we may have multiple new lines by now
//    if (selectedIndexNew == selectedIndexOld) {
//      int segments = segmentedControl.numberOfSegments;
//      for (int i = 1; i < segments; i++) {
//        [segmentedControl removeSegmentAtIndex:1 animated:NO];
//      }
//    }
//  } else
  
  if (selectedIndexNew != selectedIndexOld) {
    id control = customSegmentedControl;
    NSString* selectedTextOld = selectedIndexOld == UISegmentedControlNoSegment ? nil : [control titleForSegmentAtIndex:selectedIndexOld];
    NSString* selectedTextNew = [control titleForSegmentAtIndex:selectedIndexNew];
    
    if (notifyListener) {
      [typingController selectedItem:selectedTextNew replaceText:selectedTextOld capitalization:self.capitalization offsetWas:offset];
    }
    
    customSegmentedControl.selectedIndex = selectedIndexNew;
    CGRect frameToUse = [customSegmentedControl selectedView].frame;
    
    if (self.vertical) {
      frameToUse = CGRectMake(frameToUse.origin.x, frameToUse.origin.y + 1 * frameToUse.size.height, frameToUse.size.width, frameToUse.size.height);
    } else {
      if (offset > 0) {
        frameToUse = CGRectMake(frameToUse.origin.x, frameToUse.origin.y, frameToUse.size.width + LOOKAHEAD_PADDING, frameToUse.size.height);
      } else {
        frameToUse = CGRectMake(fmax(0, frameToUse.origin.x - LOOKAHEAD_PADDING), frameToUse.origin.y, frameToUse.size.width + LOOKAHEAD_PADDING, frameToUse.size.height);
      }
    }
    
    [bg scrollRectToVisible:frameToUse animated:selectedIndexOld != UISegmentedControlNoSegment];
  }
  
  self->givingSpellingFeedback = NO;
  
  if (speak && notifyListener) {
    [self cancelAllSpellingRequests];
    NSString* wordString = [NSString stringWithString:[customSegmentedControl titleForSegmentAtIndex:selectedIndexNew]];
    if (self.needsSpellingFeedback && FLEKSY_APP_SETTING_SPELL_WORDS && wordString.length > 1) {
      [self performSelector:@selector(spellWord:) withObject:wordString afterDelay:1.2 + 0.1 * wordString.length];
    }
    NSString* speakString = wordString;
    if ([speakString isEqualToString:@"I"]) {
      speakString = @"i"; // so that we don't hear "Capital I"
    }
    [VariousUtilities performAudioFeedbackFromString:speakString];
  }
  
  lastInteractedTime = CFAbsoluteTimeGetCurrent();
}


- (void) selectSuggestionWithOffset:(int) offset replaceText:(BOOL) replace {
  [self selectSuggestionWithOffset:offset replaceText:replace scroll:YES notifyListener:YES];
}


- (void) selectSuggestionNearestScreenX:(float) x {
  float viewX = [customSegmentedControl convertPoint:CGPointMake(x, 0) fromView:self].x;
  int index = [customSegmentedControl indexOfItemNearestX:viewX];
  NSLog(@"x: %.3f, viewX: %.3f, index: %d", x, viewX, index);
  NSString* newText = [customSegmentedControl titleForSegmentAtIndex:index];
#pragma unused(newText)
  int selectedIndexOld = customSegmentedControl.selectedIndex;
  int offset = index - selectedIndexOld;
  NSLog(@"selectedIndexOld: %d, offset: %d, newText: %@", selectedIndexOld, offset, newText);
  [self selectSuggestionWithOffset:offset replaceText:YES scroll:YES notifyListener:YES];
}

- (CGPoint) selectedSuggestionPosition {
  UIView* selectedView = customSegmentedControl.selectedView;
  return CGPointMake([customSegmentedControl convertPoint:selectedView.center toView:self].x, selectedView.frame.size.width);
}


- (void) showSuggestions:(NSArray*) items selectedSuggestionIndex:(int) selected capitalization:(NSString*) cap {
  @synchronized (self) {
    self.capitalization = cap;
    [self recreateCustomSegmentedControlWithItems:items differentFirst:selected == 1];
    [self showWithSelection:nil];
    [self selectSuggestionWithOffset:selected+1 replaceText:NO scroll:NO notifyListener:YES];
    
    if (self.vertical) {
      // Don't do this as we want to scroll even further inside above selectSuggestionWithOffset when vertical.
      // We dont want to show current suggestion anymore
      //[bg setContentOffset:CGPointMake(0, [customSegmentedControl selectedView].frame.origin.y)];
    } else {
      //scroll raw text out of the way
      [bg setContentOffset:CGPointMake([customSegmentedControl selectedView].frame.origin.x, 0)];
    }
  }
}

- (void) fadeout {
  
  float fadeoutThreshold = 0.26;
  
  if ([self isHidden] || self.alpha < fadeoutThreshold) {
    return;
  }
  
  float limit = 0.01;
  
  [self.layer removeAllAnimations];
  
  //NSLog(@"%d prepare animation: %.3f", self->needsSpellingFeedback, self.alpha);
  [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState
                   animations:^{
                     //NSLog(@"%d begin animation: %.3f", self->needsSpellingFeedback, self.alpha);
                     self.alpha = fmax(limit, self.alpha * self.alpha * 0.9);
                     //NSLog(@"fadeout, %.3f", self.alpha);
                   } completion:^(BOOL finished){
                     //NSLog(@"%d complete animation 1: %.3f", self->needsSpellingFeedback, self.alpha);
                     if (self.alpha && self.alpha < fadeoutThreshold) {
                       [UIView animateWithDuration:1.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
                         //NSLog(@"%d complete animation 2: %.3f", self->needsSpellingFeedback, self.alpha);
                         self.alpha = limit;
                       } completion:^(BOOL finished){
                         //NSLog(@"%d complete animation 3: %.3f", self->needsSpellingFeedback, self.alpha);
                       }];
                     }
                   }];
}

- (double) _showSuggestions:(NSMutableArray*) suggestions rawText:(NSString *) rawText systemSuggestion:(NSString*) systemSuggestion selectRaw:(BOOL) selectRaw {
  
  self->hasPreciseRawWord = selectRaw;
  
  //NSLog(@"_showSuggestions: %@, raw: %@, capitalization: %@", suggestions, rawText, self.capitalization);
  //double startTime = CFAbsoluteTimeGetCurrent();
  
  BOOL needToAddRaw    = [self shouldInsertSuggestion:rawText          inList:suggestions];
#ifndef __clang_analyzer__    
    // Code not to be analyzed
    BOOL needToAddSystem = [self shouldInsertSuggestion:systemSuggestion inList:suggestions];
#endif
  
  
  //needToAddRaw = YES;
  needToAddSystem = NO;
  
  if ([[rawText lowercaseString] isEqualToString:[systemSuggestion lowercaseString]]) {
    needToAddSystem = NO;
  }
  
  //UPDATE we show so that we can see based on the color if it came from apple or fleksy or both
  //dont show first, it has been chosen already
  //if ([suggestions count] && !includeFirst) {
  //  [suggestions removeObjectAtIndex:0];
  //}
  
  BOOL selectedSuggestionIndex = 0;
  
  if (needToAddSystem) {
    NSLog(@"needToAddSystem NOT NEEDED ANYMORE");
    //[suggestions insertObject:systemSuggestion atIndex:0];
  }
  
  FLResponseEntry* rawEntry = NULL;
  
  if (needToAddRaw) {
    FLString s = NSStringToFLString(rawText);
    rawEntry = FLResponseEntry::FLResponseEntryMake(&s);
    rawEntry->platform = NO;
    rawEntry->fleksy = NO;
    [suggestions insertObject:[NSValue valueWithPointer:rawEntry] atIndex:0];
    
    //TODO do precise IF, will pronounce OF sometimes. If select raw it should not be zero, rawWord might be in different index (rappos)
    selectedSuggestionIndex = selectRaw ? 0 : 1;
  } else {
    //raw and *some* suggestion are the same, dont assume it is the first.
    //we need to move that suggestion to first place and we need to capitalize
    //the first suggestion appropriately because it will be used as a 
    //template for capitalization later
    
//    if ([suggestions count]) {
//      int sameIndex = [self indexOfCandidateWithLetters:rawText inList:suggestions];
//      CandidateEntry* same = [suggestions objectAtIndex:sameIndex];
//      NSString* newString = [VariousUtilities capitalizeString:same->letters basedOn:rawText]; 
//      [same->letters release];
//      same->letters = [newString retain];
//      [suggestions removeObject:same];
//      [suggestions insertObject:same atIndex:0];
//      if (sameIndex > 0) {
//        selectedSuggestionIndex = 1;
//      }
//    }
  }

  if (![suggestions count]) {
    //dont show here, the one suggestion we had is same as raw, so we got it in the dictionary
    return 0;
  }

  NSMutableArray* items = [[NSMutableArray alloc] init];
  
  for (NSValue* value in suggestions) {
    FLResponseEntry* entry = (FLResponseEntry*) [value pointerValue];
    FLString test(entry->letters, entry->lettersN);
    [items addObject:FLStringToNSString(test)];
  }
  
  double startTime = CFAbsoluteTimeGetCurrent();
  
  [self showSuggestions:items selectedSuggestionIndex:selectedSuggestionIndex capitalization:rawText];
  
  double dt = CFAbsoluteTimeGetCurrent() - startTime;

  [items removeAllObjects];
  
  //bg.frame = CGRectMake(0, 0, currentX, bg.frame.size.height);

  //NSLog(@"showSuggestions done in %.4f seconds", CFAbsoluteTimeGetCurrent() - startTime);
  
  // we need to free this here, it's not part of the input vector so it won't be freed later
  free(rawEntry);
  
  return dt;
}

- (void) showSuggestions:(FLResponse*) sr rawText:(NSString*) rawText systemSuggestion:(NSString*) systemSuggestion selectRaw:(BOOL) selectRaw {
  
  int nSuggestions0 = MIN(FLEKSY_SUGGESTIONS_LIMIT, sr->candidatesN);
  NSMutableArray* suggestions0 = [[NSMutableArray alloc] init];
  for (int i = 0; i < nSuggestions0; i++) {
    FLResponseEntry* entry = sr->getCandidate(i);
    [suggestions0 addObject:[NSValue valueWithPointer:entry]];
  }
  @synchronized (self) {
    //NSLog(@"BEGIN @synchronized");
    //double startTime = CFAbsoluteTimeGetCurrent();
    //double dt2 = [self _showSuggestions:suggestions0 rawText:rawText systemSuggestion:systemSuggestion selectRaw:selectRaw];
    [self _showSuggestions:suggestions0 rawText:rawText systemSuggestion:systemSuggestion selectRaw:selectRaw];
    
    //NSLog(@"END @synchronized in %.8f (%.8f)", CFAbsoluteTimeGetCurrent() - startTime, dt2);
    //[NSThread sleepForTimeInterval:1];
  }
  
  
  /*
  if (FLEKSY_CORE_SETTING_SEARCH_MINUS_EXTRA) {
  
    int nSuggestions1 = fmin(FLEKSY_SUGGESTIONS_LIMIT, [pwr->candidatesExtra count]);
    NSMutableArray *suggestions1 = [[NSMutableArray alloc] initWithArray:[pwr->candidatesExtra subarrayWithRange:NSMakeRange(0, nSuggestions1)]];
    [self _showSuggestions:suggestions1 rawText:@"" systemSuggestion:@"" includeFirst:YES scoreLimit:scoreLimit rowIndex:2];
  
    int nSuggestions2 = fmin(FLEKSY_SUGGESTIONS_LIMIT, [pwr->candidatesMinus count]);
    NSMutableArray *suggestions2 = [[NSMutableArray alloc] initWithArray:[pwr->candidatesMinus subarrayWithRange:NSMakeRange(0, nSuggestions2)]];
    [self _showSuggestions:suggestions2 rawText:@"" systemSuggestion:@"" includeFirst:YES scoreLimit:scoreLimit rowIndex:0];
  }*/
  
}

- (BOOL) showWithSelection:(NSString*) selection {
  
  //[self print:[NSString stringWithFormat:@"showWithSelection: %@, hasBeenDismissed: %d", selection, hasBeenDismissed]];

  
  //[self cancelAllSpellingRequests];
  if (hasBeenDismissed) {
    //NSLog(@"hasBeenDismissed!!!!");
    return NO;
  }
  
  //we only do this for symbols now
  if (!self->needsSpellingFeedback && selection) {
    int selectedIndexNew = [customSegmentedControl indexOfTitle:selection];
    int selectedIndexOld = customSegmentedControl.selectedIndex;
    int offset = selectedIndexNew - selectedIndexOld;
    NSLog(@"selectedIndexNew: %d, selectedIndexOld: %d, offset: %d", selectedIndexNew, selectedIndexOld, offset);
    if (selectedIndexNew >= 0) {
      [self selectSuggestionWithOffset:offset replaceText:nil scroll:YES notifyListener:NO];
    } else {
      //TODO: might be some character or symbol from another keyboard...
      [self hide];
      return NO;
    }
  }
    
  self.alpha = FULL_ALPHA;
  //[self.superview bringSubviewToFront:self];
  return YES;
}

//- (void) print:(NSString*) string {
//  NSLog(@"%@ <%@>", needsSpellingFeedback ? @"suggestionsWords  " : @"suggestionsSymbols", string);
//}

- (void) hide {
  //[self print:@"hide"];
  //return;
  
//  BOOL previousAnimationsState = [UIView areAnimationsEnabled];
//  [UIView setAnimationsEnabled:YES];
//  [UIView beginAnimations:nil context:NULL];
//  [UIView setAnimationDuration:0.12];
  //NSLog(@"%d hide", self->needsSpellingFeedback);
  [self.layer removeAllAnimations];
  self.alpha = 0;
//  [UIView commitAnimations];
//  [UIView setAnimationsEnabled:previousAnimationsState];
}

- (void) dismiss {
  //[self print:@"dismiss"];
  
  [self hide];
  hasBeenDismissed = YES;
}

- (BOOL) isHidden {
  //NSLog(@"%d isHidden: %.3f", self->needsSpellingFeedback, self.alpha);
  return self.alpha == 0;
}

- (NSString*) selectedTitle {
  return [customSegmentedControl titleForSegmentAtIndex:customSegmentedControl.selectedIndex];
}


/*
   // Only override drawRect: if you perform custom drawing.
   // An empty implementation adversely affects performance during animation.
   - (void)drawRect:(CGRect)rect {
    // Drawing code
   }
 */


@synthesize hasBeenDismissed, capitalization, lastInteractedTime, needsSpellingFeedback;

@end