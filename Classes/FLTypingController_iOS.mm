//
//  FLTypingController_iOS.h
//  Fleksy
//
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FLKeyboardContainerView.h"
#import "MathFunctions.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "FLKeyboardContainerView.h"
#import "FLKeyboard.h"
#import "FileManager.h"
#import "VariousUtilities.h"

#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "FleksyUtilities.h"

#import "notify.h"
#include <string>
#include <iostream>
#include <locale>

#import "SynthesizeSingleton.h"

@interface ShowSuggestionsTask : NSObject {
@public
  FLResponse* sr;
  NSString* rawText;
  NSString* systemSuggestion;
  BOOL includeFirst;
  BOOL selectRaw;
}
@end

@implementation ShowSuggestionsTask

@end

// redifining fleksyClient as readwrite. Note: (Private) gives -[FLTypingController_iOS setFleksyClient:]: unrecognized selector sent to instance
@interface FLTypingController_iOS ()
@property (readwrite) FLEKSY_CLIENT_CLASS* fleksyClient;
@end

@implementation FLTypingController_iOS

SYNTHESIZE_SINGLETON_FOR_CLASS(FLTypingController_iOS);

- (void) playBackspace {
  NSLog(@"playBackspace");
  AudioServicesPlaySystemSound(_sounds[kSoundBackspace]);
}

- (void) playError {
  AudioServicesPlaySystemSound(_sounds[kSoundError]);
}

- (NSString*) removeWordHighlight:(NSString*) word {
  word = [word stringByReplacingOccurrencesOfString:@"[" withString:@""];
  word = [word stringByReplacingOccurrencesOfString:@"]" withString:@""];
  return word;
}

/*
- (void) highlightDictatedWord:(int) wi {
  NSMutableString* result = [[NSMutableString alloc] init];
  NSArray* dictatedWords = [dictateTextView.text componentsSeparatedByString:@" "];
  for (int i = 0; i < [dictatedWords count]; i++) {
    NSString* s = [dictatedWords objectAtIndex:i];
    s = [self removeWordHighlight:s];
    if (i == wi) {
      [result appendFormat:@"[%@] ", s];
    } else {
      [result appendFormat:@"%@ ", s];
    }
  }
  dictateTextView.text = result;
  [result release];
}

- (void) refillDictatedWords {
  NSMutableString* words = [[NSMutableString alloc] init];
  for (int i = 0; i < FLEKSY_DICTATE_WORDS; i++) {
    [words appendFormat:@"%@ ", [[FleksyUtilities sharedFleksyUtilities] getRandomWord:i+2].letters];
  }
  dictateTextView.text = words;
  [words release];
  currentDictatedWordIndex = 0;
  
  [self highlightDictatedWord:0];
}*/



- (void) createClient {
  NSLog(@"createClient, FLEKSY_USE_SOCKETS: %d", FLEKSY_USE_SOCKETS);
  
  [NSThread currentThread].name = @"Client thread";
  //  NSLog(@"priority was %.3f", [NSThread currentThread].threadPriority);
  //  [NSThread currentThread].threadPriority = 1;
  //  NSLog(@"priority is now %.3f", [NSThread currentThread].threadPriority);
#if FLEKSY_USE_SOCKETS
  self.fleksyClient = [[FleksyClient_IPC alloc] initWithServerAddress:FLEKSY_SERVER_ADDRESS serverPort:FLEKSY_SERVER_PORT];
#else
  self.fleksyClient = [[FleksyClient_NOIPC alloc] init];
#endif
}

#if FLEKSY_USE_SOCKETS
- (void) loadData:(FleksyServer*) server {
  NSLog(@"FleksyServer loadData");
  [FleksyClient_NOIPC loadData:server->getSystemsIntegrator() userDictionary:nil];
}


- (void) runServerForever:(NSValue*) arg {
  FleksyServer* server = (FleksyServer*) [arg pointerValue];
  [self loadData:server];
  server->runForever();
}
#endif

- (void) forceLoad {
#if FLEKSY_USE_SOCKETS
    if (FLEKSY_RUN_SERVER) {
      FleksyServer* server = new FleksyServer(atoi(FLEKSY_SERVER_PORT.UTF8String));
      server->printDebugInfo();
      [self performSelectorInBackground:@selector(runServerForever:) withObject:[NSValue valueWithPointer:server]];
    } else {
      NSLog(@"Not running a server, will connect to server on %@:%@", FLEKSY_SERVER_ADDRESS, FLEKSY_SERVER_PORT);
      // notify loading is 100% done
      [[NSNotificationCenter defaultCenter] postNotificationName:FLEKSY_LOADING_NOTIFICATION object:[NSNumber numberWithFloat:1]];
    }
  [self createClient];
#else
  NSLog(@"warming up, client: %@, userDictionary: %@", self.fleksyClient, self.fleksyClient.userDictionary);
  NSString* preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
  [self.fleksyClient loadDataWithLanguagePack:FLEKSY_APP_SETTING_LANGUAGE_PACK];
  //[FleksyClient_NOIPC loadData:self.fleksyClient.systemsIntegrator userDictionary:self.fleksyClient.userDictionary languagePack:FLEKSY_APP_SETTING_LANGUAGE_PACK];
  FLPoint keymaps[4][KEY_MAX_VALUE];
  // hack. Should loop through the n (4) keyboards and copy individually, dont rely on internal represenation being contiguous.
  memcpy(keymaps, self.fleksyClient.systemsIntegrator->getKeymap(0), sizeof(keymaps));
  [[FLKeyboard sharedFLKeyboard] setKeymaps:keymaps];
  
  [self pushPreviousToken:@"the"];
  FLRequest* request = [self createRequest:3 platformSuggestions:NULL];
  // word "say"
  request->points[0] = FLPointMake(58.475685, 112.231873);
  request->points[1] = FLPointMake(16.655285, 109.025909);
  request->points[2] = FLPointMake(171.190826, 41.109081);
  FLResponse* response = [self.fleksyClient getCandidatesForRequest:request];
  while ([self popPreviousToken]) {}
  free(request);
  free(response);
#endif

}

//TODO: refactor!
NSString* ___getAbsolutePath(NSString* filepath, NSString* languagePack) {
  return [NSString stringWithFormat:@"%@/%@/%@", [[VariousUtilities theBundle] bundlePath], languagePack, filepath];
}

//- (id) initWithView:(UIView *) _view textLabel:(UITextView *) _textLabel dictateTextView:(UITextView*) _dictateTextView {
  
- (id) init {
  
  if (self = [super init]) {
    
    if (!FLEKSY_USE_SOCKETS) {
      [self createClient];
    }
    
    wordResultsHistory = [[NSMutableArray alloc] init];
    
    if (FLEKSY_APP_SETTING_DICTATE_MODE) {
      dictatedWordsCounter = 0;
    }
    
    NSString* keyboardFilename = ___getAbsolutePath(@"keyboards/keyboard-iPhone-ASCII.txt.xxx", FLEKSY_APP_SETTING_LANGUAGE_PACK);
    
// c/c++ locale functions dont work on the device, but work on the simulator
//    NSLog(@"available locales: %@", [NSLocale availableLocaleIdentifiers]);
//    NSLog(@"will try to set locale to %s", FLEKSY_APP_SETTING_LOCALE);
//    
//    try {
//      char* theLocale = setlocale(LC_CTYPE, FLEKSY_APP_SETTING_LOCALE);
//      locale localeObject = locale(FLEKSY_APP_SETTING_LOCALE);
//      flcout << "localeObject: " << localeObject.name().c_str() << endl;
//      FLChar c = 241; //'\361';
//      printf("locale set to %s. isalpha(%c): %d toupper(%c): %d\n", theLocale, c, isalpha(c), c, std::toupper(c));
//      
//    } catch (exception e) {
//      flcout << e.what() << endl;
//    }

    FLKeyboard *keyboard = [[FLKeyboard sharedFLKeyboard] initWithFrame:CGRectMake(0, 0, 1, 1)];
  
    points = [[NSMutableArray alloc] init];
    pointTraces = [[NSMutableArray alloc] init];
    
    traceCentroid = [[UIView alloc] initWithFrame:CGRectMake(-10, -10, 4, 4)];
    traceCentroid.backgroundColor = [UIColor redColor];
    traceCentroid.alpha = 0.5f;//0.1;
    traceCentroid.tag = TAG_TRACE;
    [[FLKeyboard sharedFLKeyboard] addSubview:traceCentroid];
    
    traceMedian = [[UIView alloc] initWithFrame:CGRectMake(-10, -10, 4, 4)];
    traceMedian.backgroundColor = [UIColor blueColor];
    traceMedian.alpha = 0.5f;//0.1;
    traceMedian.tag = TAG_TRACE;
    [[FLKeyboard sharedFLKeyboard] addSubview:traceMedian];
    
    lastTapOccured = CFAbsoluteTimeGetCurrent();
    
    //timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(timerLoop) userInfo:nil repeats:YES];
    
    //deletionsStack = [[NSMutableArray alloc] init];
    
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[FileManager URLForResource:@"Error" withExtension:@"wav" subdirectory:@"sounds"], &_sounds[kSoundError]);
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[FileManager URLForResource:@"Backspace" withExtension:@"wav" subdirectory:@"sounds"], &_sounds[kSoundBackspace]);
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[FileManager URLForResource:@"Click19" withExtension:@"wav" subdirectory:@"sounds"], &_sounds[kSoundClick]);
    for (int i = 0; i < kNumSounds; i++) {
      assert(_sounds[i]);
    }
    
    //totalProcessingTime = maxProcessingTime = 0;
    //wordsProcessed = 0;
    
    //these need to be in sync
    shortcutPunctuationMarks = [NSArray arrayWithObjects:@". ", @", ", @"? ", @"! ", @"'s ", @": ", @"; ",/* @" & ", @" (", @") ", @"@",*/ nil];
    shortcutPunctuationCharacters = @"\n .,?!:;"; //above symbols + space and newline
    
    //NSLog(@"punctuationCharacterSet: %@", punctuationCharacterSet);
    
    //diagnostics = [[DiagnosticsManager alloc] init];
    diagnostics = nil;
    
    previousTokensStack = [[NSMutableArray alloc] init];
    
    checker = new MyTextChecker();
    
    [self reset];
  }
  
  return self;
}


- (void) recalculateTracesCentroid {
  
  if (![pointTraces count]) {
    traceCentroid.center = CGPointMake(-10, -10);
    traceMedian.center = CGPointMake(-10, -10);
    return;
  }  
  
  CGPoint centroid = CGPointMake(0, 0);
  for (UIView *trace in pointTraces) {
    centroid.x += trace.center.x;
    centroid.y += trace.center.y;
  }

  centroid.x /= [pointTraces count];
  centroid.y /= [pointTraces count];

  traceCentroid.center = centroid;

  traceMedian.center = centroid;//CGPointMake(0, 0);
  int iterations = 0;
  while (YES) {
    
    CGPoint temp = CGPointMake(0, 0);
    float totalD = 0;
    for (UIView* trace in pointTraces) {
      CGPoint p = trace.center;
      float d = distanceOfPoints(p, traceMedian.center);
      if (d == 0) {
        d = 1;
      }
      p.x /= d;
      p.y /= d;
      temp = addPoints(temp, p);
      totalD += 1.0f / d;
    }
    temp.x /= totalD;
    temp.y /= totalD;
    
    double delta = distanceOfPoints(traceMedian.center, temp);
    traceMedian.center = temp;
    
    iterations++;
    
    if (delta < 1) {
      break;
    }
  }
  
  //NSLog(@"traceMedian: %.4f, %.4f [iterations: %d]", traceMedian.center.x, traceMedian.center.y, iterations);
  
  
  [[FLKeyboard sharedFLKeyboard] bringSubviewToFront:traceCentroid];
  [[FLKeyboard sharedFLKeyboard] bringSubviewToFront:traceMedian];
}

- (void) addPointTrace:(CGPoint) point color:(UIColor *) color {

#if FLEKSY_INCREASING_TRACE_SIZE
  int size = [pointTraces count] + 8;
#else
  int size = FLEKSY_FIXED_TRACE_SIZE;
#endif

  //NSLog(@"adding trace %.2f, %.2f", point.x, point.y);

  UIView *trace = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
  trace.alpha = 0.35f;
  trace.tag = TAG_TRACE;
  [pointTraces addObject:trace];
  trace.center = CGPointMake(point.x, point.y);
  trace.backgroundColor = color;
  [[FLKeyboard sharedFLKeyboard] addSubview:trace];
  [[FLKeyboard sharedFLKeyboard] bringSubviewToFront:trace];
  
  
  //if (! ([rawWordText length] % 2)) {
  //  trace.transform = CGAffineTransformMakeRotation(M_PI * 0.25);
  //}

  [self recalculateTracesCentroid];
}

- (void) clearTraces {
  for (UIView *trace in pointTraces) {
    [trace removeFromSuperview];
  }
  [pointTraces removeAllObjects];
  [self recalculateTracesCentroid];
  KeyboardImageView* kbImageView = (KeyboardImageView*) [FLKeyboard sharedFLKeyboard].activeView;
  [kbImageView unhighlightAllKeys];
}


//TODO put in delegate + make protocol
- (FLChar) peekLastCharacter {
  NSString* writtenText = [delegate textUpToCaret];
  if (!writtenText || writtenText.length == 0) {
    return 0;
  }
  unichar result = [writtenText characterAtIndex:[writtenText length] - 1];
  //NSLog(@"last char was %c (%d), space=%d", lastChar, lastChar, ' ');
  return result;
}


//TODO put in delegate + make protocol
- (FLChar) deleteLastCharacterWithFeedback:(BOOL) feedback {
  FLChar result = [self peekLastCharacter];
  [delegate handleDelete:1];
  if (feedback) {
    [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Deleted %@", [VariousUtilities descriptionForCharacter:result]]];
  }
  return result;
}


- (FLChar) lastNonSpaceChar {
  NSString* writtenText = [delegate textUpToCaret];
  int charIndex = [writtenText length] - 1;
  FLChar lastChar;
  while (charIndex >= 0) {
    lastChar = [writtenText characterAtIndex:charIndex];
    if (lastChar != ' ') {
      return lastChar;
    }
    charIndex--;
  }
  return 0;
}

- (BOOL) needsCapital {
  
  if ([self peekLastCharacter] == '.') {
    return NO;
  }
  
  char last = [self lastNonSpaceChar];
  return (last == 0) || [VariousUtilities string:@".?!\n" containsChar:last];
}

- (BOOL) canAddPeriod {
  return ![self needsCapital] && ![VariousUtilities string:@",:" containsChar:[self lastNonSpaceChar]];
}


//TODO move this into KBView
- (void) _showSuggestions:(ShowSuggestionsTask*) task {
  
  @autoreleasepool {
    
    //////////////////////////////////////////////////////////////////
    //int nSuggestions = fmin(FLEKSY_SUGGESTIONS_LIMIT, [pwr->candidatesExact count]);
    //NSMutableArray *suggestions = [[NSMutableArray alloc] initWithArray:[pwr->candidatesExact subarrayWithRange:NSMakeRange(0, nSuggestions)]];
    
    //TODO dont send systemSuggestion if we dont have it in our dictionary, or if it's more than +/- 1 different in length, or if setting of app 
    if (!FLEKSY_APP_SETTING_USE_SYSTEM_AUTOCORRECTION) {
      if (FLEKSY_LOG) {
        NSLog(@"Ignoring system suggestion %@ [App setting]", task->systemSuggestion);
      }
      task->systemSuggestion = @"";
    } else if (([task->systemSuggestion length] > [task->rawText length] + 1) || ([task->systemSuggestion length] < [task->rawText length] - 1)) {
      if (FLEKSY_LOG) {
        NSLog(@"Ignoring system suggestion %@ [Length mismatch]", task->systemSuggestion);
      }
      task->systemSuggestion = @"";
    } /*else if (![[FleksyUtilities sharedFleksyUtilities] isWordInDictionary:task->systemSuggestion]) {
       if (FLEKSY_LOG) {
       NSLog(@"Ignoring system suggestion %@ [Not in our dictionary]", task->systemSuggestion);
       }
       task->systemSuggestion = @"";
       }*/ else {
         if (FLEKSY_LOG) {
           NSLog(@"USING system suggestion %@", task->systemSuggestion);
         }
       }
    
    float scoreLimit = MAXFLOAT; // pwr.firstSuggestion.cachedTotalDistance * 10 + 10;
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView showSuggestions:task->sr rawText:task->rawText systemSuggestion:task->systemSuggestion selectRaw:task->selectRaw];
    //////////////////////////////////////////////////////////////////
  
    //[NSThread sleepForTimeInterval:1];
  }
}

- (NSString*) lastWord {

  NSString* writtenText = [delegate textUpToCaret];
  
  if (points.count && points.count <= writtenText.length) {
    
    NSString* result = [writtenText substringFromIndex:writtenText.length - points.count];
    //NSLog(@"lastWord: <%@>", result);
    return result;
  }
  
  for (NSString* punctuationMark in shortcutPunctuationMarks) {
    if ([writtenText hasSuffix:punctuationMark]) {
      return punctuationMark;
    }
  }
  
  NSArray* words = [[delegate textUpToCaret] componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:shortcutPunctuationCharacters]];
  NSString* result = [words lastObject];
  signed int c = words.count;
  if (c && ![result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length) {
    int index = fmax(0, c-2);
    return [words objectAtIndex:index];
  }
  
//  NSLog(@"punctuation: %@", punctuationCharacterSet);
//  for (NSString* word in words) {
//    NSLog(@"word: '%@'", word);
//  }
  
  //NSLog(@"lastWord: <%@>", result);
  
  return result;
}

- (NSString*) getRawWordText {
  
  NSString* text = [delegate textUpToCaret];
  if (text && text.length) {
    int index = text.length - points.count;
    if (index >= 0) {
      return [text substringFromIndex:index];
    } else {
      NSLog(@"index < 0, points: %d, text.length: %d", points.count, text.length);
      return @"";
    }
  } else {
    NSLog(@"No text in getRawWordText");
    return nil;
  }
}

- (void) showSuggestions:(FLResponse*) sr includeFirst:(BOOL) includeFirst rawText:(NSString*) rawText systemSuggestion:(NSString*) systemSuggestion selectRaw:(BOOL) selectRaw {
  
  //if we are already displaying a word suggestion, and we want to show yet another one, the punctuation view is done
  //NSLog(@"suggestionsView isHidden: %d", [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView isHidden]);
  if (![[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView isHidden]) {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols dismiss];
  } else {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
  }
  
  ShowSuggestionsTask* task = [[ShowSuggestionsTask alloc] init];
  task->sr = sr;
  task->rawText = rawText;
  task->includeFirst = includeFirst;
  task->systemSuggestion = [systemSuggestion copy];
  task->selectRaw = selectRaw;
  
  //[self performSelectorOnMainThread:@selector(_showSuggestions:) withObject:task waitUntilDone:NO];

  //NEED TO RELEASE IN THE END!
  /////////////////////////////
  
  double dt = CFAbsoluteTimeGetCurrent();
  [self _showSuggestions:task];
  //[self performSelectorOnMainThread:@selector(_showSuggestions:) withObject:task waitUntilDone:NO];
  //NSLog(@"_showSuggestions took %.3f ms", 1000 * (CFAbsoluteTimeGetCurrent() - dt));
}


- (FLRequest*) createRequest:(int) nPoints platformSuggestions:(vector<FLString>*) platformSuggestions {
  
  FLString previousToken1;
  FLString previousToken2;

  if (previousTokensStack.count > 1) {
    previousToken1 = NSStringToFLString([previousTokensStack objectAtIndex:previousTokensStack.count-2]);
  }
  if (previousTokensStack.count > 0) {
    previousToken2 = NSStringToFLString([previousTokensStack objectAtIndex:previousTokensStack.count-1]);
  }
  
  FLRequest* result = FLRequest::FLRequestMake(nPoints, &previousToken1, &previousToken2);
  
  if (platformSuggestions && platformSuggestions->size()) {
    NSMutableString* temp = [[NSMutableString alloc] init];
    for (FLString platformSuggestion : *platformSuggestions) {
      [temp appendFormat:@"%s,", platformSuggestion.c_str()];
    }
    FLString s = NSStringToFLString(temp);
    result->setPlatformSuggestions(&s);
  }
  
  return result;
}

// returns TWO NSStrings
- (NSArray*) getPreviousTokens {
  
  if (previousTokensStack.count >= MAX_WORD_DEPTH) {
    return [previousTokensStack subarrayWithRange:NSMakeRange(previousTokensStack.count-MAX_WORD_DEPTH, MAX_WORD_DEPTH)];
  }
  
  if (previousTokensStack.count == 1) {
    return [NSArray arrayWithObjects:@"", [previousTokensStack lastObject], nil];
  }

  return [NSArray arrayWithObjects:@"", @"", nil];
}

- (NSString*) changePreviousToken:(NSString*) newToken {
  NSString* oldToken = [self popPreviousToken];
  [self pushPreviousToken:newToken];
  [self sendPrepareNextCandidates];
  return oldToken;
}

- (NSString*) peekPreviousToken {
  NSString* result = nil;
  //NSLog(@"peek, %@", previousTokensStack);
  if (previousTokensStack.count) {
    result = [previousTokensStack lastObject];
  }
  return result;
}

- (NSString*) popPreviousToken {
  NSString* result = nil;
  if (previousTokensStack.count) {
    result = [previousTokensStack lastObject];
    [previousTokensStack removeLastObject];
  }
  [self sendPrepareNextCandidates];
  return result;
}

- (void) pushPreviousToken:(NSString*) newToken {
  //NSLog(@"adding previousToken <%@>", newToken);
  [previousTokensStack addObject:newToken];
  while (previousTokensStack.count > 10) {
    [previousTokensStack removeObjectAtIndex:0];
  }
  [self sendPrepareNextCandidates];
}

- (void) sendPrepareNextCandidates {
  NSArray* previousTokens = [self getPreviousTokens];
  FLString previousToken1 = NSStringToFLString([previousTokens objectAtIndex:0]);
  FLString previousToken2 = NSStringToFLString([previousTokens objectAtIndex:1]);
  self.fleksyClient.systemsIntegrator->prepareContextResults(&previousToken1, &previousToken2);
}

- (void) replaceText:(NSString*) replaceText newText:(NSString *) newText capitalization:(NSString*) capitalization {
  
  if ([replaceText compare:NEWLINE_UI_CHAR] == NSOrderedSame) {
    //we dont just do a delete:1 here, the new line char might already have been deleted
    replaceText = @"\n";
    newText = @"";
  }
  
  //this case is handled on FLSuggestionsView
  
//  if ([newText compare:NEWLINE_UI_CHAR] == NSOrderedSame) {
//    [self nonLetterCharInput:'\n'];
//    return;
//  }
  
  NSString* text = [delegate textUpToCaret];
  NSRange range = [text rangeOfString:replaceText options:NSBackwardsSearch | NSCaseInsensitiveSearch];
  if (range.location != NSNotFound) {
    newText = [VariousUtilities capitalizeString:newText basedOn:capitalization];
    
    if (NO /*!UIAccessibilityIsVoiceOverRunning()*/) {
      // new method. When VO is on, this changes the VO focus :(
      // also changes the selection, firing an event that is not distinguishable from actual user tapping on the text
      NSString* oldText = [delegate handleReplaceRange:range withText:newText];
    } else {
      // old method, has flickering when near the end of line and textview scrolls
      NSString* remaining = [text substringFromIndex:range.location + range.length];
      [delegate handleDelete:text.length - range.location];
      [delegate handleStringInput:newText];
      [delegate handleStringInput:remaining];
      
      // highlight keyboard
      if (NO) {
        KeyboardImageView* kbImageView = (KeyboardImageView*) [FLKeyboard sharedFLKeyboard].activeView;
        [kbImageView unhighlightAllKeys];
        [kbImageView highlightKeysForWord:newText];
      }
    }
  } else {
    NSLog(@"Could not find text '%@' to replace with '%@'", replaceText, newText);
  }
}

- (void) tryWord:(BOOL) offline autocorrectionType:(AutocorrectionType) autocorrectionType incremental:(BOOL) incremental systemSuggestion:(NSString*) systemSuggestion {
  assert(!systemSuggestion || !systemSuggestion.length);
  double startTime = CFAbsoluteTimeGetCurrent();
  
  NSString* lastWord = [self lastWord];

  //this was only for system wide (jailbreak) keyboard where we might start typing after existing text
//  //TODO OPT: this takes at least 1 msec on iPhone 4, unbounded as textUpToCaret grows
//  NSString* lastWordRawText = [self getRawWordText];
//  
//  //simulate touch points for any characters that were there before initial curson position
//  if (lastWord.length > lastWordRawText.length) {
//    NSString* prefix = [lastWord substringToIndex:lastWord.length - lastWordRawText.length];
//    BOOL prefixOK = YES;
//    for (int i = 0; i < prefix.length; i++) {
//      char c = [prefix characterAtIndex:i];
//      if (![VariousUtilities charIsAlpha:c]) {
//        prefixOK = NO;
//        lastWord = lastWordRawText;
//        break;
//      }
//    }
//    if (prefixOK) {
//      //NSLog(@"lastWord: %@, lastWordRawText: %@, prefix: %@", lastWord, lastWordRawText, prefix);
//      KeyboardImageView* kbImageView = (KeyboardImageView*) [FLKeyboard sharedFLKeyboard]->imageViewABC;
//      for (int i = 0; i < prefix.length; i++) {
//        char c = [prefix characterAtIndex:i];
//        CGPoint point = [kbImageView getKeyboardPointForChar:c];
//        [points insertObject:[NSValue valueWithCGPoint:point] atIndex:i];
//      }
//    }
//  }
  
  FLString s = NSStringToFLString(lastWord);
  vector<FLString> platfromResults;
  double startTime1 = fl_get_time();
  checker->peekResults(platfromResults, s);
  printf("got %lu platform results in %.6f\n", platfromResults.size(), fl_get_time() - startTime1);
  for (FLString z : platfromResults) {
    printf("platform result: %s\n", z.c_str());
  }
  printf("\n");
  
  FLRequest* request = [self createRequest:points.count platformSuggestions:&platfromResults];
  request->debug = FLEKSY_LOG;
  int i = 0;
  for (NSValue* value in points) {
    request->points[i++] = FLPointFromCGPoint([value CGPointValue]);
  }

  FLResponse* sr = [self.fleksyClient getCandidatesForRequest:request];
  free(request);
  
  if (!sr) {
    [self reset];
    return;
  }
  
  
  FLResponseEntry* best = sr->candidatesN ? sr->candidates : nil;
  
  //totalProcessingTime += 0;//pwr->processingTimes[0];
  //wordsProcessed++;

  //The Application Kit creates an autorelease pool on the main thread at the beginning of every cycle of the event loop,
  //and drains it at the end, thereby releasing any autoreleased objects generated while processing an event.
  //If you use the Application Kit, you therefore typically don’t have to create your own pools.
  //if (pwr.processingTime < 0.1) {
  //	double drainStartTime = CFAbsoluteTimeGetCurrent();
  //	[pool drain];
  //	NSLog(@" - - > DRAIN done in %.3f seconds", CFAbsoluteTimeGetCurrent() - drainStartTime);
  //}

  /*
     debugText = pwr.debugText;
     label.text = debugText;

     label.text = [NSString stringWithFormat:@"\nAtx:(%.1f, %.1f) Rtx:(%.1f, %.1f)\n%@",
                            lastAbsoluteTranslation.x, lastAbsoluteTranslation.y, lastRelativeTranslation.x, lastRelativeTranslation.y, label.text];
   */

  //if (!offline) {
  //	NSLog(@"Extended DEBUG text:\n%@", pwr.extendedDebugText);
  //}

  //NSLog(@" - - > 1111111 done in %.3f seconds", CFAbsoluteTimeGetCurrent() - startTime);

  int pCount = [points count];
  
  
  //NSLog(@" - - > 2222222 done in %.3f seconds", CFAbsoluteTimeGetCurrent() - startTime);

  if (best) {
    FLString test(best->letters, best->lettersN);
    NSString* lettersToUse = FLStringToNSString(test);
    
    //double startTime = CFAbsoluteTimeGetCurrent();
    NSMutableArray* suggestions = [[NSMutableArray alloc] init];
    if (self.currentWordIsPrecise) {
      [suggestions addObject:lastWord];
      TestFlightLog(@"%@", lastWord);
    } else {
      TestFlightLog(@"%@", lettersToUse);
    }
    
    for (int i = 0; i < sr->candidatesN; i++) {
      FLResponseEntry* entry = (FLResponseEntry*) sr->getCandidate(i);
      FLString test(entry->letters, entry->lettersN);
      //flcout << "sugg1: " << test << "\n";
      NSString* suggestion = FLStringToNSString(test);
      //NSLog(@"sugg2: %@", suggestion);
      [suggestions addObject:suggestion];
      if (suggestions.count > 6) {
        break;
      }
    }
    
    [diagnostics points:points suggestions:suggestions];
    //NSLog(@"diag log took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
    
    
    //TODO
    //if (pwr.firstSuggestion.printLetters) {
    //  lettersToUse = pwr.firstSuggestion.printLetters;
    //}
    
    //NSLog(@"lettersToUse %@ %@ %@", lettersToUse, [lettersToUse uppercaseString], [lettersToUse lowercaseString]);
    
    //lettersToUse = [FLKeyboardContainerView capitalizeString:lettersToUse basedOn:lastWordRawText];

    //NSLog(@"lettersToUse %@ %@ %@", lettersToUse, [lettersToUse uppercaseString], [lettersToUse lowercaseString]);

    //NSLog(@" - - > 23 done in %.3f seconds", CFAbsoluteTimeGetCurrent() - startTime);

    if (!self.currentWordIsPrecise) {
      //NSLog(@"replaceText: %@, newText: %@, capitalization: %@", lastWord, lettersToUse, lastWord);
      [self replaceText:lastWord newText:lettersToUse capitalization:lastWord];
      [self pushPreviousToken:lettersToUse];
    } else {
      [self pushPreviousToken:lastWord];
    }
  
    
    //double averageProcessing = totalProcessingTime / (double) wordsProcessed;
    //maxProcessingTime = fmax(maxProcessingTime, 888);
    
    if (FLEKSY_APP_SETTING_SHOW_SUGGESTIONS) {
      [self showSuggestions:sr includeFirst:NO rawText:lastWord systemSuggestion:systemSuggestion selectRaw:self.currentWordIsPrecise];
    }
    
    //NSLog(@"%@", best->letters);
    
  } 
  
  //NSLog(@" - - > 3333333 done in %.3f seconds", CFAbsoluteTimeGetCurrent() - startTime);

  //[wordResultsHistory addObject:pwr];

  
  //if (space) {
  //  [delegate handleStringInput:@" "];
  //}
  
  if (!incremental) {
    
    /*
    if (FLEKSY_APP_SETTING_DICTATE_MODE) {
      
      double wordTypingTime = startTime - currentWordStartTime;
      
      NSArray* dictatedWords = [dictateTextView.text componentsSeparatedByString:@" "];
      NSString* dictatedWord = [dictatedWords objectAtIndex:currentDictatedWordIndex];
      [wordTestData appendFormat:@"%d %@ ", dictatedWordsCounter, [self removeWordHighlight:dictatedWord]];
      for (NSValue* value in points) {
        CGPoint point = [value CGPointValue];
        [wordTestData appendFormat:@"%.0f,%.0f#", point.x, point.y];
      }
      [wordTestData appendFormat:@" %@ %.2f\n", lastWordRawText, wordTypingTime];
      currentDictatedWordIndex++;
      dictatedWordsCounter++;
      
      if (currentDictatedWordIndex == FLEKSY_DICTATE_WORDS) {
        [self refillDictatedWords];
      } else {
        [self highlightDictatedWord:currentDictatedWordIndex];
      }
      
      
    }*/
    
    [self reset];
  }
  
  free(sr);

  //NSLog(@" - - > TOTAL done in %.3f seconds", CFAbsoluteTimeGetCurrent() - startTime);

  /*

     FLWord* newWord = [self processHistoryWithHint:hintIsSpace];

     if (newWord) {
          for (FLInternalSuggestionsContainer* pwr in wordResultsHistory) {
                  [pwr release];
          }
          [wordResultsHistory removeAllObjects];
          //[[FleksyUtilities sharedFleksyUtilities] resetAllWordHistories];
     }

     return newWord; */
}

/*
   - (void) timerLoop {
        double dt = CFAbsoluteTimeGetCurrent() - lastTapOccured;

        if (dt > 0.6 && [points count] != lastPointsUsed && [points count] > 0) {
                [self tryWord:NO hint:NO];
                lastPointsUsed = [points count];
        }
   }*/


- (void) addCharacter:(FLChar) c {
  
  if (!c) {
    return;
  }
  
  BOOL punctuationShortcut = NO;
  
  if (c == ' ') {
      
    unichar lastChar = [self peekLastCharacter];
    if (lastChar == ' ') {
      //if ([self canAddPeriod]) {
        //NSLog(@"Double space detected, using shortcut");
        [delegate handleDelete:1];
        [delegate handleStringInput:@"."];
        punctuationShortcut = YES;
//      } else {
//        //[self playError];
//        //NSLog(@"Additional spaces after punctuation disabled for blind mode (or begining of text)");
//        return; 
//      }
    }
  }
  
  //Need to go through some hoops to support extended (>127) ascii chars.
  //See http://en.wikipedia.org/wiki/Windows-1252
  NSData* data = [NSData dataWithBytes:&c length:1];
  NSString* s = [[NSString alloc] initWithData:data encoding:NSWindowsCP1252StringEncoding];
  [delegate handleStringInput:s];
  
  //lastCharIsLetter = [[VariousUtilities strictlyLettersSet] characterIsMember:[c characterAtIndex:0]];
  
  if (punctuationShortcut && FLEKSY_APP_SETTING_SHOW_SUGGESTIONS) {
    [self pushPreviousToken:@"."];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols showSuggestions:shortcutPunctuationMarks selectedSuggestionIndex:0 capitalization:@""];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView hide];
  }
  
  //[VariousUtilities playTock];
}


- (void) hideAllSuggestions {
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView hide];
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
}


- (BOOL) autocorrectWord:(AutocorrectionType) autocorrectionType {
  
#if DEBUG_NO_WORDS
  [self reset];
  return;
#endif
  
  if ([points count]) {
    @autoreleasepool {
      //vibrate first to increase perceived responsiveness
      [VariousUtilities vibrate];
      //[self hideAllSuggestions];
      [self tryWord:NO autocorrectionType:autocorrectionType incremental:NO systemSuggestion:nil];
    }
    return YES;
  } else {
    //NSLog(@"no points to autocorrect!");
    return NO;
  }
}

//- (void) autocorrectWord {
//  [self performSelectorInBackground:@selector(_autocorrectWord) withObject:nil];
//}


- (FLWord *) tapOccured:(CGPoint) point1 precise:(BOOL) precise rawChar:(FLChar) rawChar {
  
  if (!precise) {
    self.currentWordIsPrecise = NO;
  }
  
  BOOL shift = [self needsCapital]; // || [[delegate textUpToCaret] length] == 0;
  
  //NSLog(@"tapOccured atPoint: KB (%.0f, %.0f)", point1.x, point1.y);
  
  if (![points count]) {
    currentWordStartTime = CFAbsoluteTimeGetCurrent();
    //[[FleksyUtilities sharedFleksyUtilities] resetIncremental];
    [self clearTraces];
  }
  
  //we might want to hide these later when we want to do autocomplete
  //of current word for example. For now we leave them showing to indicate 
  //that the last typed word can still be changed even while typing the next word
  //[self hideAllSuggestions];
  
  
  lastTapOccured = CFAbsoluteTimeGetCurrent();

  //NSLog(@"tapOccured: %d, tolower: %d, toupper: %d", rawChar, FleksyUtilities::tolower(rawChar), FleksyUtilities::toupper(rawChar));
  
  if (shift) {
    rawChar = FleksyUtilities::toupper(rawChar);
  } else {
    rawChar = FleksyUtilities::tolower(rawChar);
  }
  
  if (FLEKSY_APP_SETTING_KEY_SNAP) {
    KeyboardImageView* kbImageView = (KeyboardImageView*) [FLKeyboard sharedFLKeyboard].activeView;
    point1 = [kbImageView getKeyboardPointForChar:rawChar];
  }
  
  if (!FleksyUtilities::isalpha(rawChar)) { // [VariousUtilities charIsAlpha:rawChar]) {

    [self nonLetterCharInput:rawChar autocorrectionType:kAutocorrectionNone];
    
  } else {
    //NSLog(@"tapOccured KB: (%.0f, %.0f)", kbPoint.x, kbPoint.y);
    [self addCharacter:rawChar];
    [points addObject:[NSValue valueWithCGPoint:point1]];
    
    [self prepareSpellChecker];
    
    if (FLEKSY_APP_SETTING_SHOW_TRACES) {
      UIColor* color = [pointTraces count] % 2 ? [UIColor redColor] : [UIColor blueColor];
      [self addPointTrace:point1 color:color];
    }
  }
  
  return nil;      // [self tryWord:offline hint:hintIsSpace];
}

- (void) prepareSpellChecker {
  //////
  NSString* lastWord = [self lastWord];
  FLString s = NSStringToFLString(lastWord);
  checker->prepareResultsAsync(s);
  //////
}

- (void) replaceTextWithSuggestion:(NSArray*) items {
  NSString* replace = [items objectAtIndex:0];
  NSString* suggestion = [items objectAtIndex:1];
  NSString* capitalization = [items objectAtIndex:2];
  [self replaceText:replace newText:suggestion capitalization:capitalization];
  [self changePreviousToken:suggestion];
}



- (void) nonLetterCharInput:(FLChar) input autocorrectionType:(AutocorrectionType) autocorrectionType {
  
  double startTime  = CFAbsoluteTimeGetCurrent();
  
  //NSLog(@"autocorrectionType: %d", autocorrectionType);
  
  if (autocorrectionType == kAutocorrectionSuggest || autocorrectionType == kAutocorrectionChangeAndSuggest /*input == 0 || [VariousUtilities string:shortcutPunctuationCharacters containsChar:input]*/) {
    [self autocorrectWord:autocorrectionType];
  } else {
    NSMutableArray* suggestions = [[NSMutableArray alloc] init];
    int selectedSuggestion = 0;
    switch (input) {
      case '@':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        if (FLEKSY_APP_SETTING_EMAIL_REPLY_TO && FLEKSY_APP_SETTING_EMAIL_REPLY_TO.length) {
          [suggestions addObject:FLEKSY_APP_SETTING_EMAIL_REPLY_TO];
        }
        [suggestions addObject:@"@gmail.com "];
        [suggestions addObject:@"@yahoo.com "];
        [suggestions addObject:@"@hotmail.com "];
        break;
      
      case '#':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        if (FLEKSY_APP_SETTING_SMS_REPLY_TO && FLEKSY_APP_SETTING_SMS_REPLY_TO.length) {
          [suggestions addObject:FLEKSY_APP_SETTING_SMS_REPLY_TO];
        }
        break;
        
      case '0':
      case '1':
      case '2':
      case '3':
      case '4':
      case '5':
      case '6':
      case '7':
      case '8':
      case '9':
        [suggestions addObject:@"12"];
        [suggestions addObject:@"11"];
        [suggestions addObject:@"10"];
        [suggestions addObject:@"9"];
        [suggestions addObject:@"8"];
        [suggestions addObject:@"7"];
        [suggestions addObject:@"6"];
        [suggestions addObject:@"5"];
        [suggestions addObject:@"4"];
        [suggestions addObject:@"3"];
        [suggestions addObject:@"2"];
        [suggestions addObject:@"1"];
        [suggestions addObject:@"0"];
        selectedSuggestion = '9' - input + 3;
        NSLog(@"selectedSuggestion: %d", selectedSuggestion);
        break;
      
      case '.':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        [suggestions addObject:@".com "];
        [suggestions addObject:@".org "];
        [suggestions addObject:@".edu "];
        [suggestions addObject:@".gov "];
        [suggestions addObject:@".net "];
        //[suggestions addObject:@".co.uk "];
        break;
        
      case '(':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        [suggestions addObject:@")"];
        [suggestions addObject:@"["];
        [suggestions addObject:@"]"];
        [suggestions addObject:@"{"];
        [suggestions addObject:@"}"];
        [suggestions addObject:@"<"];
        [suggestions addObject:@">"];
        break;
        
      case '$':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        [suggestions addObject:@"€"];
        [suggestions addObject:@"£"];
        [suggestions addObject:@"¥"];
        break;
        
      case ' ':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        [suggestions addObject:@"."];
        [suggestions addObject:@","];
        [suggestions addObject:@"+"];
        [suggestions addObject:@"-"];
        [suggestions addObject:@":"];
        [suggestions addObject:@"/"];
        break;
        
      case ':':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        [suggestions addObject:@";"];
        [suggestions addObject:@"\""];
        [suggestions addObject:@"'"];
        [suggestions addObject:@"&"];
        [suggestions addObject:@"_"];
        break;
        
      case '/':
        [suggestions addObject:[NSString stringWithFormat:@"%c", input]];
        [suggestions addObject:@"-"];
        [suggestions addObject:@"+"];
        [suggestions addObject:@"*"];
        [suggestions addObject:@"%"];
        [suggestions addObject:@"="];
        break;
        
      default:
        break;
    }
    
    if (suggestions.count) {
      [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols showSuggestions:suggestions selectedSuggestionIndex:selectedSuggestion capitalization:@""];
      [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView hide];
    } else {
      [self hideAllSuggestions];
    }
    //[VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"%C", input]];
    [self reset];
  }
  
  
  [self addCharacter:input];
  
  
  //[Keyboard sharedKeyboard].shiftIsOn = NO;
  
  //NSLog(@"nonLetterCharInput <%c> done in %.6f", input, CFAbsoluteTimeGetCurrent() - startTime);
}

/*
- (void) showLastInteractedSuggestionView {
  
  if (![self peekLastCharacter]) {
    return;
  }
  
  if ([FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols.lastInteractedTime > [FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView.lastInteractedTime) {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols showWithSelection:nil];
  } else {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView showWithSelection:nil];
  }
}*/

- (void) reshowAppropriateSuggestionView {
  
  FLChar c = [self lastNonSpaceChar];
  if (!c) {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView dismiss];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
    return;
  }
  
  if (FleksyUtilities::isalpha(c)) {
    //[[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols dismiss];
    NSString* word = [self lastWord];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView showWithSelection:word];
  } else {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView hide];
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols showWithSelection:[NSString stringWithFormat:@"%c", c]];
  }
}

- (void) singleBackspaceWithFeedback:(BOOL) feedback {
  
  //NSLog(@"singleBackspaceWithFeedback: %d", feedback);
  
  char c = [self deleteLastCharacterWithFeedback:feedback];
  
  UIView* lastTrace = [pointTraces lastObject];
  [lastTrace removeFromSuperview];
  if ([points count]) {
    
    [points removeLastObject];
    [self prepareSpellChecker];
    
    if (![points count]) {
      //was the last point from current word
      //[self showLastInteractedSuggestionView];
      [self reshowAppropriateSuggestionView];
      [self reset];
    }                                                                                      
  }
  
  if ([pointTraces count]) {
    //if (![writtenText hasSuffix:@" "]) {
      [pointTraces removeLastObject];
      [self recalculateTracesCentroid];
    //}
  }
  
  //[VariousUtilities playTock];
}

- (void) deleteAllPoints {
  if (![points count]) {
    return;
  }
  [self playBackspace];
  [delegate handleDelete:[points count]];
  [points removeAllObjects];
  
  [self clearTraces];
  [self reset];
}

- (void) deleteLastWordWithFeedback:(BOOL) feedback {
  
  if ([delegate textUpToCaret].length == 0) {
    return;
  }
  
  NSString* lastWord = [self lastWord];
  
  int n = lastWord.length;
  if (!n) {
    return;
  }
  
  // TODO UNDO before deleting last word
  //[[NSNotificationCenter defaultCenter] postNotificationName:@"set_undo_checkpoint" object:nil];
  
  [delegate handleDelete:n];
  
  if (feedback) {
    //TODO queue up "last word is 'last_word'" 1 second after "Deleted X"
    [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Deleted %@", lastWord]];
  }
  //[self playBackspace];
  
  if ([points count]) {
    //[self showLastInteractedSuggestionView];
  } else {
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView dismiss];
  }
  
  [self reset];
  //[Keyboard sharedKeyboard].shiftIsOn = [self needsCapital];
}

- (BOOL) stringEndsWithLetter:(NSString*) string {
  if (!string || !string.length) {
    return NO;
  }
  char c = [string characterAtIndex:string.length-1];
  return [[VariousUtilities strictlyLettersSet] characterIsMember:c];
}

- (BOOL) stringEndsWithSpace:(NSString*) string {
  if (!string || !string.length) {
    return NO;
  }
  return [string hasSuffix:@" "];
}


- (void) backspace {
  
  if (![self peekLastCharacter]) {
    [self playError];
    [VariousUtilities performAudioFeedbackFromString:@"No more text to delete"];
    return;
  }
  
  //special case (mostly for blind) where we just swiped a word and we want to delete it: delete the space AND the last word
  //make sure though the suggestions have not been hidden and then shown by typing more chars for next word and then deleting
  //NOTE: it would be a bit safer/less agressive to only do if there has also been some cycling of suggestions
  //NOTE: could do even when deleting previous words and showing suggestions: if the user
  //cycles the suggestions and then backswipes, we could assume they were not happy with the suggestions.
  //FLSuggestionsView* suggestions = [FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView;
  // && ![suggestions isHidden] && !suggestions.hasBeenPreviouslyHidden) {
  
  
  if ([points count]) {
    
    if (self.currentWordIsPrecise || !UIAccessibilityIsVoiceOverRunning()) {
      [self singleBackspaceWithFeedback:YES];
      [self playBackspace];
      return;
      
    } else {
      [delegate handleDelete:[points count]];
    }
    
  } else {    
    
    NSString* writtenText = [delegate textUpToCaret];
    BOOL endedWithPunctuationMark = NO;
    for (NSString* punctuationMark in shortcutPunctuationMarks) {
      if ([writtenText hasSuffix:punctuationMark]) {
        [delegate handleDelete:punctuationMark.length];
        NSString* trimmed = [punctuationMark stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        NSMutableString* description = [[NSMutableString alloc] init];
        for (int i = 0; i < trimmed.length; i++) {
          [description appendString:[VariousUtilities descriptionForCharacter:[trimmed characterAtIndex:i]]];
          if (i < trimmed.length - 1) {
            [description appendString:@" "];
          }
        }
        
        // this caused a delay between "Deleted" and the description
        //speech = [[MultipartSpeechSynthesizer alloc] initWithParts:[NSArray arrayWithObjects:@"Deleted ", description, nil] listener:nil];
        //[speech start];
        [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Deleted %@", description]];
        
        [self addCharacter:' ']; //since shortcut punctuation always has space after
        endedWithPunctuationMark = YES;
        [self reshowAppropriateSuggestionView];
        break;
      }
    }
    
    if (!endedWithPunctuationMark) {
      NSMutableArray* marksToUse = [NSMutableArray arrayWithObjects:@"→ ", @"← ", @"↓ ", @"↑ ", nil];
      for (NSString* mark in marksToUse) {
        if ([writtenText hasSuffix:mark]) {
          NSLog(@"has mark! <%@>", mark);
          [delegate handleDelete:mark.length];
          NSString* description = [VariousUtilities getPhoneticStringFor:mark];
          [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Deleted %@", description]];
          endedWithPunctuationMark = YES;
        }
      }
    }
    
    if ([writtenText hasSuffix:@"\n"]) {
      [self singleBackspaceWithFeedback:YES];
    } else if (!endedWithPunctuationMark) {
      
      //we want to delete individual letters if its a symbol or number from non-abc keyboard
      BOOL endsWithLetterOrSpace = [self stringEndsWithLetter:writtenText] || [self stringEndsWithSpace:writtenText];
      //NSLog(@"endsWithLetterOrSpace: %d", endsWithLetterOrSpace);
      if (!endsWithLetterOrSpace) {
        [self singleBackspaceWithFeedback:YES];
      } else {
        if ([self stringEndsWithSpace:writtenText]) {
          [self singleBackspaceWithFeedback:NO];
        }
        [self deleteLastWordWithFeedback:YES];
        [self reshowAppropriateSuggestionView];
      }
    }
    
    [self popPreviousToken];
    
    NSString* lastWord = [[self lastWord] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* compare = [self peekPreviousToken];
    
    NSLog(@"lastWord: %@, compare: %@", lastWord, compare);
    //assert((!lastWord.length && !compare) || [lastWord isEqualToString:compare]);
  }
  
  [self playBackspace];
  [self reset];
  [self clearTraces];
  
  //for blind we dont delete individual letters
  return;
  
//  char lastChar = [self peekLastCharacter];
//  if ([points count] || ![VariousUtilities charIsAlpha:lastChar]) {
//    [self singleBackspaceWithFeedback:YES];
//    if (![[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols isHidden]) {
//      //NSLog(@"suggShortcut selected: %@. lastChar: %c", [FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols.selectedTitle, lastChar);
//      if (lastChar == [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols.selectedTitle characterAtIndex:0]) {
//        [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
//        [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView show];
//      }
//    }    
//  } else {
//    [self deleteLastWordWithFeedback:YES];
//  }
  
}



- (void) swapCaseForLastTypedCharacter {
  
  //ONLY during typing
  //TODO allow arbitraty cursor positions too for editing? See "- (void) moveCaret:(int) offset"
  if ([points count]) {
    
    unichar lastChar = [self peekLastCharacter];
    unichar newChar;
    BOOL wasLower = FleksyUtilities::islower(lastChar);
    
    if (wasLower) {
      newChar = FleksyUtilities::toupper(lastChar);
    } else {
      newChar = FleksyUtilities::tolower(lastChar);
    }
    
    if (newChar != lastChar) {
      [self deleteLastCharacterWithFeedback:NO];
      [self addCharacter:newChar];
      
      //TODO: do this as suggestions instead, so sighted users know how to use it
      NSString* speakString = [NSString stringWithFormat:@"%@%c", FleksyUtilities::isupper(newChar) ? @"Capital " : @"", FleksyUtilities::tolower(newChar)];
      [VariousUtilities performAudioFeedbackFromString:speakString];
    }
  }
}

- (void) caretPositionDidChange {
  NSLog(@"caretPositionDidChange: %@", @"TODO: location parameter");
  [self resetAndHideSuggestions];
}

- (void) resetAndHideSuggestions {
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView hide];
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsViewSymbols hide];
  [self reset];
}

- (void) selectedItem:(NSString*) item replaceText:(NSString*) replaceText capitalization:(NSString*) capitalization offsetWas:(int) offset {
  
  //NSLog(@" > selectedItem: %@, replaceText: %@, capitalization: %@", item, replaceText, capitalization);
  
  //[VariousUtilities performAudioFeedbackFromString:item];
  
  if (replaceText) {
    
    if ([item compare:replaceText] == NSOrderedSame) {
      //NSLog(@"No need to replace '%@' with '%@'", item, replaceText);
      return;
    }
    
    NSMutableArray* items = [[NSMutableArray alloc] initWithCapacity:2];
    [items addObject:replaceText];
    [items addObject:item];
    [items addObject:capitalization];
    //[self replaceTextWithSuggestion:items];
    //textfield deletes and new chars must be done on main thread
    [self performSelectorOnMainThread:@selector(replaceTextWithSuggestion:) withObject:items waitUntilDone:NO];
    
    NSString* logString = [NSString stringWithFormat:@"selected_%@: %@", offset < 0 ? @"UP" : @"DN", item];
    [diagnostics append:logString];
    TestFlightLog(@"%@", logString);
  }
}



- (void) setTextFieldDelegate:(id<MyTextField>) d {
  delegate = d;
}


- (void) reset {

  debugText = @"";
  //we dont remove traces until next word so we can examine visually
  //if (!FLEKSY_KEEP_TRACES) {
  //  [self clearTraces];
  //}
  [points removeAllObjects];
  
  //[wordResultsHistory removeAllObjects];
  self.currentWordIsPrecise = YES;
}

- (BOOL) hasPendingPoints {
  return points.count != 0;
}


- (void) addRemoveUserWord:(NSString*) wordToAddRemove {
  
  assert(self.fleksyClient.userDictionary);
  
  if ([self.fleksyClient.userDictionary containsWord:wordToAddRemove]) {
    
    if ([self.fleksyClient removedUserWord:wordToAddRemove]) {
      [self.fleksyClient.userDictionary removeWord:wordToAddRemove notifyListener:NO];
      [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Removed %@ from dictionary", wordToAddRemove]];
    } else {
      [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Error removing %@ from dictionary", wordToAddRemove]];
    }
  } else {
    
    FLAddWordResult result = [self.fleksyClient addedUserWord:wordToAddRemove frequency:FLEKSY_USER_WORD_FREQUENCY];
    
    switch (result) {
        
      case FLAddWordResultAdded:
        NSLog(@"Added word %@ to memory", wordToAddRemove);
        if ([self.fleksyClient.userDictionary addWord:wordToAddRemove frequency:FLEKSY_USER_WORD_FREQUENCY notifyListener:NO]) {
          [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Added %@ to dictionary", wordToAddRemove]];
        } else {
          [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Error adding %@ to dictionary", wordToAddRemove]];
        }
        break;
        
      case FLAddWordResultExists:
        [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"%@ already exists in dictionary", wordToAddRemove]];
        break;
      
      case FLAddWordResultTooLong:
        [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"%@ is too long, could not add to dictionary", wordToAddRemove]];
        break;
        
      case FLAddWordResultWordIsBlacklisted:
        [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"%@ is blacklisted, could not add to dictionary", wordToAddRemove]];
        break;
        
      default:
        NSString* s = [NSString stringWithFormat:@"Could not add word %@, some error occurred (%d)", wordToAddRemove, result];
        NSLog(@"%@", s);
        [VariousUtilities performAudioFeedbackFromString:s];
        break;
    }
  }
  
  // we need to re-send this, as the token IDs might have changed
  [self sendPrepareNextCandidates];
}

@synthesize traceCentroid, debugText, diagnostics, currentWordIsPrecise, fleksyClient;

@end