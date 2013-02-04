//
//  FLKeyboardContainerView.h
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "Settings.h"
#import "FLSuggestionsView.h"
#import "FleksyClient_IPC.h"
#import "FleksyClient_NOIPC.h"
#import "DiagnosticsManager.h"
#import "MyTextField.h"
#import "MultipartSpeechSynthesizer.h"


#define TAG_TRACE 123

#ifndef FLEKSY_USE_SOCKETS
#error FLEKSY_USE_SOCKETS not defined!
#endif

#if FLEKSY_USE_SOCKETS
#define FLEKSY_CLIENT_CLASS FleksyClient_IPC
#else
#define FLEKSY_CLIENT_CLASS FleksyClient_NOIPC
#endif

typedef enum {
  kAutocorrectionNone,
  kAutocorrectionSuggest,
  kAutocorrectionChangeAndSuggest,
} AutocorrectionType;


@interface FLTypingController_iOS : NSObject {
  NSTimer *timer;

  NSMutableArray *wordResultsHistory;

  NSMutableArray *points;
  NSMutableArray *pointTraces;
  UIView *traceCentroid;
  UIView *traceMedian;
  

  NSString *__weak debugText;

  double lastTapOccured;
  
  //double totalProcessingTime;
  //double maxProcessingTime;
  //int wordsProcessed;
  //BOOL lastCharIsLetter;
  
  //NSAutoreleasePool* pool;
  
  int currentDictatedWordIndex;
  int dictatedWordsCounter;
  double currentWordStartTime;
  
  
  BOOL currentWordIsPrecise;
  
  
  NSArray* shortcutPunctuationMarks;
  NSString* shortcutPunctuationCharacters;
  
  
  id<MyTextField> delegate;

  DiagnosticsManager* diagnostics;
  
  MultipartSpeechSynthesizer* speech;
  
  NSString* previousToken;
}

//- (void) refillDictatedWords;
//- (id) initWithView:(UIView *) view textLabel:(UITextView *) _textLabel dictateTextView:(UITextView*) _dictateTextView;

- (void) forceLoad;
- (void) addCharacter:(FLChar) c;
- (void) nonLetterCharInput:(FLChar) input autocorrectionType:(AutocorrectionType) autocorrectionType;
- (FLWord *) tapOccured:(CGPoint) point1 precise:(BOOL) precise rawChar:(FLChar) rawChar;
- (void) reset;
- (void) resetAndHideSuggestions;
- (void) playError;
- (void) backspace;
- (void) deleteAllPoints;
- (void) swapCaseForLastTypedCharacter;
- (void) setTextFieldDelegate:(id<MyTextField>) d;
- (void) selectedItem:(NSString*) item replaceText:(NSString*) replaceText capitalization:(NSString*) capitalization offsetWas:(int) offset;
- (void) caretPositionDidChange;

- (void) addRemoveUserWord:(NSString*) wordToAddRemove;

+ (FLTypingController_iOS*) sharedFLTypingController_iOS;

@property (readonly) UIView *traceCentroid;
@property (weak, readonly) NSString *debugText;
@property (readonly) DiagnosticsManager* diagnostics;
@property (readonly) BOOL hasPendingPoints;
@property BOOL currentWordIsPrecise;
@property (readonly) FLEKSY_CLIENT_CLASS* fleksyClient;

@end