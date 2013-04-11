//
//  FLSuggestionsView.h
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLInternalSuggestionsContainer.h"
#import "SystemsIntegrator.h"
#import "CustomSegmentedControl.h"
#import "MultipartSpeechSynthesizer.h"

@interface FLSuggestionsView : UIView<MultipartSpeechSynthesizerListener> {
  id listener;
  UIScrollView* bg;
  MultipartSpeechSynthesizer* speech;
  CustomSegmentedControl* customSegmentedControl;
  BOOL hasBeenDismissed;
  NSString* capitalization;
  double lastInteractedTime;
  BOOL hasPreciseRawWord;
  BOOL needsSpellingFeedback;
  BOOL givingSpellingFeedback;
}

- (id) initWithListener:(id) _listener;
//this is used for punctation
- (void) showSuggestions:(NSArray*) items selectedSuggestionIndex:(int) selected capitalization:(NSString*) cap;
- (void) showSuggestions:(FLResponse*) suggestions rawText:(NSString *) rawText
        systemSuggestion:(NSString*) systemSuggestion selectRaw:(BOOL) selectRaw;
- (void) selectSuggestionWithOffset:(int) offset replaceText:(BOOL) replace;
//returns NO iff view has been previously dismissed
- (BOOL) showWithSelection:(NSString*) selection;
- (void) hide;
- (void) dismiss;
- (BOOL) isHidden;
- (void) reset;
- (void) cancelAllSpellingRequests;
- (void) fadeout;
- (void) selectSuggestionNearestScreenX:(float) x;

// x = center, y = width
- (CGPoint) selectedSuggestionPosition;

@property (readonly) BOOL hasBeenDismissed;
@property (readonly) double lastInteractedTime;
@property (weak, readonly) NSString* selectedTitle;
@property (readwrite, copy) NSString* capitalization;
@property BOOL needsSpellingFeedback;
@property BOOL vertical;

@end