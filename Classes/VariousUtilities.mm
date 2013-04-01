//
//  VariousUtilities.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/3/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include "FleksyUtilities.h"
#import "VariousUtilities.h"
#import "notify.h"
#import "Settings.h"
#import "FleksyDefines.h"
#import "PatternRecognizer/MathFunctions.h"

#import <AudioToolbox/AudioToolbox.h>
#import <iostream>

#import <sys/utsname.h>

#define USE_NOTIFICATION_CENTER 1
#define USE_DISTRIBUTED_CENTER 0

#if USE_DISTRIBUTED_CENTER
#import "NSDistributedNotificationCenter.h"
#endif

#define ALPHABET_CHARS @"abcdefghijklmnñopqrstuvwxyzABCDEFGHIJKLMNÑOPQRSTUVWXYZ"

static int logs = 0;
static float totalLogTime = 0;

static NSCharacterSet* alphaSet = nil;
static NSCharacterSet* alphaInvertedSet = nil;
static NSString* emptyStopSpeakString = nil;

static id speechEngine = nil;
static NSString* talkClassName;
static NSString* talkMethodNameSimple;
static NSString* talkMethodNameWithLanguageCode;
static SEL talkMethodSelectorSimple = nil;
static SEL talkMethodSelectorWithLanguageCode = nil;

//static double lastSpeakTime = 0;

UInt32 _sounds[kNumSounds];

int pipe_lat(int size, int count, BOOL parent);
int unix_lat(int size, int count, BOOL parent);
int tcp_lat(int size, int count, BOOL parent);

@interface DummyInterface : NSObject 
- (id)setRate:(float)arg1;
- (float)rate;
- (float)minimumRate;
- (float)maximumRate;
- (id)stopSpeakingAtNextBoundary:(int)arg1;
- (BOOL)isSpeaking;
+ (BOOL)isSystemSpeaking;
//- (id)startSpeakingString:(id)arg1;
//- (id)startSpeakingString:(id)arg1 toURL:(id)arg2 withLanguageCode:(id)arg3;
@end


BOOL deviceIsPad() {
  return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
}

BOOL isRingerMuted() {
  id isRingerMuted = [[NSClassFromString(@"SBMediaController") performSelector:@selector(sharedInstance)] performSelector:@selector(isRingerMuted)];
  return isRingerMuted != nil;
}


@implementation VariousUtilities

// Load the framework resource bundle.
+ (NSBundle*) frameworkBundle {
  static NSBundle* frameworkBundle = nil;
  static dispatch_once_t predicate;
  dispatch_once(&predicate, ^{
    NSString* mainBundlePath = [[NSBundle mainBundle] resourcePath];
    NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"FleksyKeyboard.bundle"];
    frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
  });
  return frameworkBundle;
}

+ (NSBundle*) theBundle {
  BOOL sdk = ![[[NSBundle mainBundle] bundlePath] hasSuffix:[NSString stringWithFormat:@"%@.app", FLEKSY_PRODUCT_NAME]];
  if (sdk) {
    return [VariousUtilities frameworkBundle];
  } else {
    return [NSBundle mainBundle];
  }
}


+ (double) getNotificationDelay:(id) notification {
  
  if (!notification) {
    return -1;
  }
  
  if (![notification isKindOfClass:[NSNotification class]]) {
    return -2;
  }
  
  double timeSent = [[[notification userInfo] objectForKey:@"time"] doubleValue];
  double timeReceived = CFAbsoluteTimeGetCurrent();
  return timeReceived - timeSent;
}

+ (void) postNotificationName:(NSString*) aName {
 
  if (USE_NOTIFICATION_CENTER) {
    NSMutableDictionary* dictionary = [[NSMutableDictionary alloc] init];
    [dictionary setObject:[NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()] forKey:@"time"];
#if USE_DISTRIBUTED_CENTER
      //NSLogBlueBackground(@"posting notification %@ using NSDistributedNotificationCenter: %@", aName, [NSDistributedNotificationCenter defaultCenter]);
      [[NSDistributedNotificationCenter defaultCenter] postNotificationName:aName object:@"FLEKSY" userInfo:dictionary options:NSNotificationPostToAllSessions];
#else
    //NSLogBlueBackground(@"posting notification %@ using NSNotificationCenter: %@", aName, [NSNotificationCenter defaultCenter]);
    [[NSNotificationCenter defaultCenter] postNotificationName:aName object:nil userInfo:dictionary];
#endif
  } else {
    //NSLogBlueBackground(@"posting notification %@ using notify_post", aName);
    notify_post([aName cStringUsingEncoding:NSASCIIStringEncoding]);
  }
}

+ (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName {
  
  if (USE_NOTIFICATION_CENTER) {
    //NSDistributedNotificationCenter does not seem to work on the same process so we have to choose
#if USE_DISTRIBUTED_CENTER
      //NSLogBlueBackground(@"registering for notification %@ using NSDistributedNotificationCenter: %@", aName, [NSDistributedNotificationCenter defaultCenter]);
      [[NSDistributedNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:aName object:@"FLEKSY" suspensionBehavior:NSNotificationSuspensionBehaviorDeliverImmediately];
#else
      //NSLogBlueBackground(@"registering for notification %@ using NSNotificationCenter: %@", aName, [NSNotificationCenter defaultCenter]);
      [[NSNotificationCenter defaultCenter] addObserver:observer selector:aSelector name:aName object:nil];
#endif
    
  } else {
    //NSLogBlueBackground(@"registering for notification %@ using notify_register_dispatch", aName);
    int token, status;
    status = notify_register_dispatch([aName cStringUsingEncoding:NSASCIIStringEncoding], &token, dispatch_get_main_queue(), 
                                      ^(int t) { SuppressPerformSelectorLeakWarning([observer performSelector:aSelector withObject:aName]); });
    if (status != 0) {
      NSLog(@"notify_register_dispatch for %@, PROBLEM: status: %d, token: %d", aName, status, token);
    }
  }
}


+ (void) loadSettingsAndListen:(id) target action:(SEL) action {
  //load settings here
  SuppressPerformSelectorLeakWarning([target performSelector:action withObject:nil]);
  //also look out for settings changes
  [VariousUtilities addObserver:target selector:action name:FLEKSY_NOTIFICATION_SETTINGS_CHANGED];
}


+ (id) getSettingNamed:(NSString*) setting fromSettings:(NSDictionary*) settings {
  id result = [settings objectForKey:setting];
  if (!result) {
    //NSLog(@"ERROR: attempted to access non-existent setting %@", setting);
  }
  return result;
}


+ (NSString*) descriptionForCharacter:(FLChar) c {
  
  switch (c) {
  
    // we only need this for Deleted X, so that we can construct and pass the whole 2-word sentence to the VO. Otherwise we have a delay between Deleted and X.
    // BUT: if we have all the descriptions here we will need to localize them for the languages
    
    case '.':
      return @"Period";
    case ',':
      return @"Comma";
    case ' ':
      return @"Space";
    case '?':
      return @"Question mark";
    case '"':
      return @"Quotation mark";
    case '!':
      return @"Exclamation mark";
    case ':':
      return @"Colon";
    case ';':
      return @"Semi-colon";
    case '\'':
      return @"Apostrophe";
    case '-':
      return @"Hyphen";
    case '_':
      return @"Underscore";
    case '&':
      return @"Ampersand";
    case '*':
      return @"Asterisk";
    case '(':
      return @"Left parenthesis";
    case ')':
      return @"Right parenthesis";
    case '@':
      return @"At";
    case '\n':
      return @"New line";
    case '\t':
      return @"Numbers";
    case BACK_TO_LETTERS:
      return @"Letters";
    default:
      //NSString* s = [[NSString alloc] initWithBytes:&c length:1 encoding:NSISOLatin1StringEncoding];
      NSString* s = [[NSString alloc] initWithBytes:&c length:1 encoding:NSWindowsCP1252StringEncoding];
      //NSLog(@"\naaa: <%@>\nbbb: <%@>", aaa, bbb);
      if (!FleksyUtilities::isalpha(c)) {
        NSLog(@"Warning: getCharacterDescription for character <%@> <%d>", s, c);
      }
      return s;
  }
}


+ (NSString *)obfuscate:(NSString *)string withKey:(NSString *)key {
  // Create data object from the string
  NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
  
  // Get pointer to data to obfuscate
  char *dataPtr = (char *) [data bytes];
  
  // Get pointer to key data
  char *keyData = (char *) [[key dataUsingEncoding:NSUTF8StringEncoding] bytes];
  
  // Points to each char in sequence in the key
  char *keyPtr = keyData;
  int keyIndex = 0;
  
  // For each character in data, xor with current value in key
  for (int x = 0; x < [data length]; x++) {
    // Replace current character in data with 
    // current character xor'd with current key value.
    // Bump each pointer to the next character
    *dataPtr = *dataPtr ^ *keyPtr;
    dataPtr++;
    keyPtr++;
    
    // If at end of key data, reset count and 
    // set key pointer back to start of key value
    if (++keyIndex == [key length])
      keyIndex = 0, keyPtr = keyData;
  }
  
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#define MY_KEY @"trololgdsahd"

+ (NSString*) encode:(NSString*) string {
  NSString* obfuscated = [VariousUtilities obfuscate:string withKey:MY_KEY];
  NSData* obfuscatedData = [obfuscated dataUsingEncoding:NSUTF8StringEncoding];
  NSMutableString* result = [[NSMutableString alloc] init];
  unsigned char bytes[256];
  [obfuscatedData getBytes:bytes];
  for (int i = 0; i < obfuscatedData.length; i++) {
    [result appendFormat:@"%d-", bytes[i]];
    //NSLog(@"enc bytes[%d] = %d", i, bytes[i]);
  }
  //NSLog(@"encoded %@ becomes %@", string, result);
  return result;
}



+ (NSString*) decode:(NSString*) string {
  unsigned char bytes[256];
  NSArray* components = [string componentsSeparatedByString:@"-"];
  int i = 0;
  for (NSString* component in components) {
    bytes[i++] = [component intValue];
  }
  NSString* encoded = [[NSString alloc] initWithBytes:bytes length:[components count]-1 encoding:NSUTF8StringEncoding];
  return [VariousUtilities obfuscate:encoded withKey:MY_KEY];
}


+ (void) testEncoding:(NSString*) string {
  NSString* encoded = [VariousUtilities encode:string];
  NSString* decoded = [VariousUtilities decode:encoded];
  NSLog(@"encoding %@ becomes %@, then decoding it becomes %@. ", string, encoded, decoded);
}

+ (void) recreateSpeechEngine {
  
  //@"VSSpeechSynthesizer"
  talkClassName = [VariousUtilities decode:@"34-33-60-28-10-9-4-12-32-24-6-16-28-23-28-5-21-9-21-"];
  //@"startSpeakingString:"
  talkMethodNameSimple = [VariousUtilities decode:@"7-6-14-30-27-63-23-1-18-10-1-10-19-33-27-30-6-2-0-94-"];
  //@"startSpeakingString:toURL:withLanguageCode:
  talkMethodNameWithLanguageCode = [VariousUtilities decode:@"7-6-14-30-27-63-23-1-18-10-1-10-19-33-27-30-6-2-0-94-7-14-61-54-56-72-24-5-27-4-43-5-29-6-29-5-19-23-44-3-11-9-93-"];
  talkMethodSelectorSimple = NSSelectorFromString(talkMethodNameSimple);
  talkMethodSelectorWithLanguageCode = NSSelectorFromString(talkMethodNameWithLanguageCode);
  //NSLog(@"talkClassMethod: %@/%@/%@", talkClassName, talkMethodNameSimple, talkMethodNameWithLanguageCode);

  speechEngine = [[NSClassFromString(talkClassName) alloc] init];
  
  //NSLog(@"created speechEngine: %x", speechEngine);
}



+ (NSString*) getPhoneticStringFor:(NSString*) string {
  NSLog(@"getPhoneticStringFor <%@>", string);
  if ([string isEqualToString:@"."]) {
    return @"Dot";
  } else if ([string isEqualToString:@"→ "]) {
    return @"Right arrow";
  } else if ([string isEqualToString:@"← "]) {
    return @"Left arrow";
  } else if ([string isEqualToString:@"↓ "]) {
    return @"Down arrow";
  } else if ([string isEqualToString:@"↑ "]) {
    return @"Up arrow";
  } else if (string.length == 1 || (string.length == 2 && [string hasSuffix:@" "])) {
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    FLString temp = NSStringToFLString(string);
    return [VariousUtilities descriptionForCharacter:temp[0]];
  } else if ([string hasPrefix:@"'s"]) {
    return @"Apostrophe S";
  } else {
    return string;
  }
}


+ (void) _performAudioFeedbackFromString:(NSString*) string {
  
  //https://github.com/nst/iOS-Runtime-Headers/blob/master/PrivateFrameworks/VoiceServices.framework/VSSpeechSynthesizer.h
  // Include /Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS4.3.sdk/System/Library/PrivateFrameworks/VoiceServices.framework/VoiceServices. Only works on device, not simulator
  //NSLog(@"performAudioFeedbackFromString: <%@>", string);
  
#if TARGET_IPHONE_SIMULATOR
  return;
#endif
  
  if (!FLEKSY_APP_SETTING_SPEAK) {
    return;
  }
  
  [self stopSpeaking];
  
  string = [VariousUtilities getPhoneticStringFor:string];
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
    return;
  }
  
  if (!speechEngine) {
    [self recreateSpeechEngine];
    if (!speechEngine) {
      NSLog(@"Could not create speechEngine. No network connection?");
      return;
    }
  } else {
    //we could always release previous session and create a new one to try a different bahavior
    //[self recreateSpeechEngine];
  }
  
  if (!talkMethodSelectorSimple && !talkMethodSelectorWithLanguageCode) {
    NSLog(@"_performAudioFeedbackFromString: %@ > No speech engine", string);
    return;
  }
  
  //NSLog(@" >>>A speechEngine isSpeaking: %d, isSystemSpeaking: %d, speechString: %@", 
  //      [speechEngine isSpeaking], [NSClassFromString(@"speechEngine") isSystemSpeaking], [speechEngine speechString]);
  
  

  //do we really need the pool?
  @autoreleasepool {
    BOOL wasSpeaking = [speechEngine isSpeaking];
    if (wasSpeaking) {
      [speechEngine stopSpeakingAtNextBoundary:0];
    }
    // seems to be 0.5 to 4.0
    [speechEngine setRate:FLEKSY_APP_SETTING_SPEAKING_RATE];
    //NSLog(@"speechEngine rate: in %.3f, out %.3f minmax:<%.3f, %.3f>", rate, [speechEngine rate], [speechEngine minimumRate], [speechEngine maximumRate]);
    
    
//    int i = 0;
//    for (NSString* lang in [NSLocale preferredLanguages]) {
//      NSLog(@"default preferredLanguages[%d]: %@", i++, lang);
//    }
//
//    NSLog(@"systemLocale:  %@", [[NSLocale systemLocale] localeIdentifier]);
//    NSLog(@"currentLocale: %@", [[NSLocale currentLocale] localeIdentifier]);
//    
//    NSLog(@"systemLocale  lang: %@", [[NSLocale systemLocale] objectForKey:NSLocaleLanguageCode]);
//    NSLog(@"currentLocale lang: %@", [[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]);
//   
//    NSLog(@"systemLocale  country: %@", [[NSLocale systemLocale] objectForKey:NSLocaleCountryCode]);
//    NSLog(@"currentLocale country: %@", [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode]);
//    
//    NSLog(@"systemLocale  NSLocaleVariantCode: %@", [[NSLocale systemLocale] objectForKey:NSLocaleVariantCode]);
//    NSLog(@"currentLocale NSLocaleVariantCode: %@", [[NSLocale currentLocale] objectForKey:NSLocaleVariantCode]);
    
        
    NSString* preferredLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    
//    if ([[preferredLanguage uppercaseString] isEqualToString:@"EN"]) {
//      //SuppressPerformSelectorLeakWarning([speechEngine performSelector:talkMethodSelectorSimple withObject:string]);
//      NSLog(@"INFO: preferredLanguage is %@, will force to en-US", preferredLanguage);
//      preferredLanguage = @"en-US";
//    }
    
//    NSLog(@"INFO: using preferredLanguage %@. String: <%@>", preferredLanguage, string);
//    NSLog(@"INFO: [VSSpeechSynthesizer availableLanguageCodes]: %@", [NSClassFromString(talkClassName) performSelector:@selector(availableLanguageCodes)]);
//    NSLog(@"INFO: [VSSpeechSynthesizer availableVoicesForLanguageCode:%@]: %@", preferredLanguage, [NSClassFromString(talkClassName) performSelector:@selector(availableVoicesForLanguageCode:) withObject:preferredLanguage]);
    
    
    
    SEL selector = talkMethodSelectorWithLanguageCode;
    NSInvocation* inv = [NSInvocation invocationWithMethodSignature:[speechEngine methodSignatureForSelector:selector]];
    [inv setSelector:selector];
    [inv setTarget:speechEngine];
    //@"startSpeakingString:toURL:withLanguageCode:
    //arguments 0 and 1 are self and _cmd respectively, automatically set by NSInvocation
    [inv setArgument:&string atIndex:2];
    //id nilObject = nil;
    //[inv setArgument:&nilObject atIndex:3];
    [inv setArgument:&preferredLanguage atIndex:4];
    [inv invoke];
    
    
    //NSLog(@" > speak: %@ wasSpeaking: %d", string, wasSpeaking);
  }
}

+ (void) performAudioFeedbackFromString:(NSString*) string {
  //[self performSelectorInBackground:@selector(_startSpeakingString_OLD:) withObject:string];
  [self _performAudioFeedbackFromString:string];
}

+ (void) stopSpeaking {
  
  if (UIAccessibilityIsVoiceOverRunning()) {
    
    //this hack did not seem to work in the latest iOS 6 beta (length=1. length=0 seems to work?)
    if (!emptyStopSpeakString) {
      float iosVersion = [UIDevice currentDevice].systemVersion.floatValue;
      unichar chars[1];
      chars[0] = 0;
      int length = iosVersion >= 6 ? 0 : 1;
      emptyStopSpeakString = [NSString stringWithCharacters:chars length:length];
      NSLog(@"iosVersion: %.3f, length = %d, <%@>", iosVersion, length, emptyStopSpeakString);
    }
    
    MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, emptyStopSpeakString);
  
  } else {
    //  NSSpeechImmediateBoundary =  0,
    //  NSSpeechWordBoundary,
    //  NSSpeechSentenceBoundary  
    [speechEngine stopSpeakingAtNextBoundary:0];    
  }
}

/////////////////////////////////////////


+ (BOOL) charIsAlpha:(unichar) cs {
  return [[VariousUtilities strictlyLettersSet] characterIsMember:cs];
}


+ (NSString *) capitalizeString:(NSString *) s basedOn:(NSString *) cap {
  
  NSMutableString *result = [[NSMutableString alloc] init];
  
  for (int i = 0; i < [s length]; i++) {
    NSString* cs = [s substringWithRange:NSMakeRange(i, 1)];
    
    if ([VariousUtilities charIsAlpha:[cs characterAtIndex:0]]) {
      
      int capLength = [cap length];
      int indexToUse = fmin(i, capLength - 1.0f);
      BOOL capital = indexToUse >= 0 ? [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:[cap characterAtIndex:indexToUse]] : NO;
      
      if (capital) {
        cs = [cs uppercaseString];
      } else {
        //cs = [cs lowercaseString];
      }
      
    } else {
      
      //NSLog(@"char %c is NOT alpha", cs);
    }
    
    [result appendFormat:@"%@", cs];
  }
  
  //NSLog(@"capitalize %@ based on %@ = %@", s, cap, result);
  
  return result;
}

+ (NSMutableArray*) explodeString:(NSString*) myString {
  NSMutableArray* characters = [[NSMutableArray alloc] initWithCapacity:[myString length]];
  for (int i = 0; i < [myString length]; i++) {
    NSString* ichar  = [NSString stringWithFormat:@"%C", [myString characterAtIndex:i]];
    [characters addObject:ichar];
  }
  return characters;
}

+ (BOOL) string:(NSString*) string containsChar:(unichar) c {
  if (c == 0) {
    NSLog(@"WARNING: string: %@ containsChar with ZERO char", string);
  }
  return [string rangeOfString:[NSString stringWithFormat:@"%C", c]].length > 0;
}

+ (BOOL) string:(NSString*) string containsAnyCharacterInString:(NSString*) string2 {
  for (int i = 0; i < string2.length; i++) {
    char c = [string2 characterAtIndex:i];
    if ([VariousUtilities string:string containsChar:c]) {
      return YES;
    }
  }
  return NO;
}


+ (NSString*) removeCharacters:(NSCharacterSet*) set fromString:(NSString*) string {
  string = [string decomposedStringWithCanonicalMapping]; 
  return [[string componentsSeparatedByCharactersInSet:set] componentsJoinedByString:@""];
}

+ (NSCharacterSet*) strictlyLettersSet {
  //[NSCharacterSet letterCharacterSet] has some marks too...
  if (!alphaSet) {
    alphaSet = [NSCharacterSet characterSetWithCharactersInString:ALPHABET_CHARS];
  }
  return alphaSet;
}

+ (NSString*) _onlyKeepAlphaFromString:(NSString*) string {
  if (!alphaInvertedSet) {
    alphaInvertedSet = [[VariousUtilities strictlyLettersSet] invertedSet];
  }
  return [VariousUtilities removeCharacters:alphaInvertedSet fromString:string];
}

+ (NSString*) onlyKeepAlphaFromString:(NSString*) string {
  //@autoreleasepool {
    return [VariousUtilities _onlyKeepAlphaFromString:string];
  //}
}


/////////////////////////////////////////////

+ (void) _print:(NSString*) string {
  const char* cString = [string UTF8String];
  if (cString) {
    printf("%s", cString);
    printf("\n");
  } else {
    printf("\n > > > LOG: Could not convert string %p < < < \n", string);
  }
}

+ (void) print:(NSString*) string {
  double start = CFAbsoluteTimeGetCurrent();
  // Tests run 1k times on an iPhone 5
  //NSLog(string); // 1500 usec
  //[VariousUtilities performSelectorInBackground:@selector(_print:) withObject:string]; // 1214 usec
  //[VariousUtilities _print:string]; // 88 usec
  [VariousUtilities performSelectorOnMainThread:@selector(_print:) withObject:string waitUntilDone:SYNC_LOGGING]; // 46 usec async
  double dt = CFAbsoluteTimeGetCurrent() - start;
  logs++;
  totalLogTime += dt;
  //[VariousUtilities _print:[NSString stringWithFormat:@"\nprint done in %.6f, average: %.6f out of %d times\n", dt, totalLogTime / logs, logs]];
}

+ (void) vibrate {
  notify_post("com.booleanmagic.HapticPro.pressed");
}

+ (void) playTock {
  
  //this does NOT respect the setting of the user on Sounds/Keyboard clicks
  //http://stackoverflow.com/questions/818515/iphone-how-to-make-key-click-sound-for-custom-keypad
  //but we want to respect our own setting
  if (FLEKSY_APP_SETTING_KEYBOARD_CLICKS) {
    AudioServicesPlaySystemSound(0x450);
    //AudioServicesPlaySystemSound(_sounds[kSoundClick]);
    //NSLog(@"Tock!");
  }
  
  //this respects the setting of the user on Sounds/Keyboard clicks
  //http://developer.apple.com/library/ios/#DOCUMENTATION/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/InputViews/InputViews.html
  //[[UIDevice currentDevice] playInputClick];

  //[VariousUtilities vibrate];
}

//+ (void) insertObject:(id) obj inSortedArray:(NSMutableArray *) array usingComparator:(SEL) comparator {
//  
//  int a = (int) [array indexOfObject:obj inSortedRange:NSMakeRange(0, [array count]) options:NSBinarySearchingInsertionIndex usingComparator:
//                 
//                 ^(id lhs, id rhs) {
//                   NSComparisonResult c = (NSComparisonResult)[lhs performSelector:comparator withObject:rhs];
//                   return c;
//                 }];
//  
//  //NSLog(@"insertionIndex = %d", a);
//  
//  [array insertObject:obj atIndex:a];
//}
//
//
//
//
//+ (NSArray *) getBestElements:(NSArray *) array usingSelector:(SEL) comparator elementsToReturn:(int) n {
//  
//  //double dt = CFAbsoluteTimeGetCurrent();
//  
//  int limit = fmin(n, [array count]);
//  
//  NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:limit];
//  
//  if (limit == 0) {
//    return result;
//  }
//  
//  for (int i = 0; i < limit; i++) {
//    [result addObject:[array objectAtIndex:i]];
//  }
//  
//  [result sortUsingSelector:comparator];
//  id Nth = [result lastObject];
//  
//  
//  for (int i = limit; i < [array count]; i++) {
//    id object = [array objectAtIndex:i];
//    NSComparisonResult c = (NSComparisonResult)[object performSelector:comparator withObject:Nth];
//    if (c == NSOrderedAscending) {
//      
//      [result removeLastObject];
//      
//      //[result addObject:object];
//      //[result sortUsingSelector:comparator];
//      
//      [VariousUtilities insertObject:object inSortedArray:result usingComparator:comparator];
//      
//      
//      Nth = [result lastObject];
//    }
//  }
//  
//  //NSLog(@"getBestElements done in %.4f", CFAbsoluteTimeGetCurrent() - dt);  
//  
//  return result;
//}


/*

#import <stdio.h>
#import <unistd.h>
#import <sys/socket.h>
#import <sys/un.h>
#import <string.h>

#if TARGET_IPHONE_SIMULATOR
#define SOCKET_PATH     "/Users/kostas/Desktop/SocketIPCSocket"
#else
#define SOCKET_PATH     "/test.socket"
#endif

+ (void) _listenForIncomingConnections {
  
  int serverSocket = socket(AF_UNIX, SOCK_STREAM, 0);
  if (serverSocket < 0) {
    perror("socket");
    exit(EXIT_FAILURE);
  }
  
  // Ensure that SOCKET_PATH does not exist
  unlink(SOCKET_PATH);
  
  struct sockaddr_un address;
  address.sun_family = AF_UNIX;
  strcpy(address.sun_path, SOCKET_PATH);
  socklen_t addressLength = SUN_LEN(&address);
  
  int tr=1;
  // kill "Address already in use" error message
  if (setsockopt(serverSocket, SOL_SOCKET,SO_REUSEADDR,&tr,sizeof(int)) == -1) {
    perror("setsockopt");
    exit(EXIT_FAILURE);
  }
  
  if (bind(serverSocket, (struct sockaddr *)&address, addressLength) != 0) {
    perror("bind");
    exit(EXIT_FAILURE);
  }
  
  if (listen(serverSocket, 5) != 0) {
    perror("listen");
    exit(EXIT_FAILURE);
  }
  
  NSLog(@"listening...");
  
  int connection = 0;
  while ((connection = accept(serverSocket, (struct sockaddr *)&address, &addressLength)) >= 0) {
 
    NSLog(@"connected...");
    
    while (YES) {
      NSString *message = [NSString stringWithFormat:@"%.6f", CFAbsoluteTimeGetCurrent()];
      NSMutableData *messageData = [[[message dataUsingEncoding:NSASCIIStringEncoding] mutableCopy] autorelease];
      NSLog(@"will write on %.6f", CFAbsoluteTimeGetCurrent());
      write(connection, [messageData mutableBytes], [messageData length]);
      NSLog(@"did write on %.6f", CFAbsoluteTimeGetCurrent());
      usleep(2 * 1000 * 1000);
    }
    close(connection);
  }
  close(serverSocket);
  
  // Ensure that SOCKET_PATH does not exist
  unlink(SOCKET_PATH);
}


+ (void) listenForIncomingConnections {
  [NSThread detachNewThreadSelector:@selector(_listenForIncomingConnections) toTarget:self withObject:nil];
}

 */

//SOME TESTS USING PIPES, UNIX SOCKETS AND TCP SOCKETS


#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <string.h>
#include <time.h>
#include <stdint.h>
#include <netdb.h>


int ofds[2];
int ifds[2];
int pipe_lat(int size, int count, BOOL parent)
{
  
  void *buf;
  int64_t i, delta;
  struct timeval start, stop;
  
  buf = malloc(size);
  if (buf == NULL) {
    perror("malloc");
    return 1;
  }
  
  if (!parent) {  /* child */
    
    //NSLog(@"pipe_lat CHILD begin");
    
    for (i = 0; i < count; i++) {
      
      if (read(ifds[0], buf, size) != size) {
        perror("read");
        return 1;
      }
      
      if (write(ofds[1], buf, size) != size) {
        perror("write");
        return 1;
      }
    }
    
    //NSLog(@"pipe_lat CHILD end");
    
  } else { /* parent */
    
    //NSLog(@"pipe_lat PARENT begin");
    
    gettimeofday(&start, NULL);
    
    for (i = 0; i < count; i++) {
      
      if (write(ifds[1], buf, size) != size) {
        perror("write");
        return 1;
      }
      
      if (read(ofds[0], buf, size) != size) {
        perror("read");
        return 1;
      }
      
    }
    
    gettimeofday(&stop, NULL);
    
    delta = ((stop.tv_sec - start.tv_sec) * (int64_t) 1000000 +
             stop.tv_usec - start.tv_usec);
    
    //NSLog(@"pipe_lat PARENT end, results:");
    NSLog(@"pipe_lat average latency: %lli us", delta / (count * 2));
    
  }
  
  return 0;
}


int sv[2]; /* the pair of socket descriptors */
int unix_lat(int size, int count, BOOL parent)
{
  void *buf;
  int64_t i, delta;
  struct timeval start, stop;
  
  buf = malloc(size);
  if (buf == NULL) {
    perror("malloc");
    return 1;
  }
  
  if (!parent) {  /* child */
    
    //NSLog(@"unix_lat CHILD begin");
    
    for (i = 0; i < count; i++) {
      
      if (read(sv[1], buf, size) != size) {
        perror("read");
        return 1;
      }
      
      if (write(sv[1], buf, size) != size) {
        perror("write");
        return 1;
      }
    }
    
    //NSLog(@"unix_lat CHILD end");
  
  } else { /* parent */
    
    //NSLog(@"unix_lat PARENT begin");
    
    gettimeofday(&start, NULL);
    
    for (i = 0; i < count; i++) {
      
      if (write(sv[0], buf, size) != size) {
        perror("write");
        return 1;
      }
      
      if (read(sv[0], buf, size) != size) {
        perror("read");
        return 1;
      }
      
    }
    
    gettimeofday(&stop, NULL);
    
    delta = ((stop.tv_sec - start.tv_sec) * (int64_t) 1e6 +
             stop.tv_usec - start.tv_usec);
    
    //NSLog(@"unix_lat PARENT end, results:");
    NSLog(@"unix_lat average latency: %lli us", delta / (count * 2));
    
  }
  
  return 0;
}

#define messageCount 10
#define messageSize 1024
struct timeval startedWriting[messageCount];
struct timeval didRead[messageCount];

int tcp_lat(int size, int count, BOOL parent)
{
  void *buf;
  //int64_t delta;
  //struct timeval start, stop;
  
  ssize_t len;
  size_t sofar;
  
  int yes = 1;
  int ret;
  struct sockaddr_storage their_addr;
  socklen_t addr_size;
  struct addrinfo hints;
  struct addrinfo *res;
  int sockfd, new_fd;
  
  buf = malloc(size);
  if (buf == NULL) {
    perror("malloc");
    return 1;
  }
  
  memset(&hints, 0, sizeof hints);
  hints.ai_family = AF_UNSPEC;  // use IPv4 or IPv6, whichever
  hints.ai_socktype = SOCK_STREAM;
  hints.ai_flags = AI_PASSIVE;     // fill in my IP for me
  if ((ret = getaddrinfo("127.0.0.1", "3491", &hints, &res)) != 0) {
    fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(ret));
    return 1;
  }
  
  if (!parent) {  /* child */
    
    NSLog(@"tcp_lat CHILD begin");
    
    if ((sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol)) == -1) {
      perror("socket");
      exit(1);
    }
    
    if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &yes, sizeof(int)) == -1) {
      perror("setsockopt");
      exit(1);
    } 
    
    /*if (*/bind(sockfd, res->ai_addr, res->ai_addrlen); /* == -1) {
      perror("bind");
      exit(1);
    }*/
    
    if (listen(sockfd, 1) == -1) {
      perror("listen");
      exit(1);
    } 
    
    addr_size = sizeof their_addr;
    
    if ((new_fd = accept(sockfd, (struct sockaddr *)&their_addr, &addr_size)) == -1) {
      perror("accept");
      exit(1);
    } 
    
    for (int i = 0; i < count; i++) {
      
      for (sofar = 0; sofar < size; ) {
        len = read(new_fd, buf, size - sofar);
        if (len == -1) {
          perror("read");
          return 1;
        }
        sofar += len;
      }
      
      gettimeofday(&didRead[i], NULL);
      int64_t didReadTime = didRead[i].tv_sec * (int64_t) 1e6 + didRead[i].tv_usec;
      
      timeval* f = (timeval*) buf;
      int64_t serverTime = f->tv_sec * (int64_t) 1e6 + f->tv_usec;
      NSLog(@"tcp_lat CHILD didRead[%d] @ %lli, serverTime was %lli, delay: %lli usec", i, didReadTime, serverTime, didReadTime - serverTime);
    
      if (write(new_fd, buf, size) != size) {
        perror("write");
        return 1;
      }
    }
    
    close(new_fd);
    close(sockfd);
    
    for (int i = 0; i < count; i++) {
      //int64_t t = didRead[i].tv_sec * (int64_t) 1e6 + didRead[i].tv_usec;
    }
    
    NSLog(@"tcp_lat CHILD end");
    
  } else { /* parent */
    
    NSLog(@"tcp_lat PARENT begin");
    
    sleep(1);
    
    if ((sockfd = socket(res->ai_family, res->ai_socktype, res->ai_protocol)) == -1) {
      perror("socket");
      exit(1);
    }
    
    if (connect(sockfd, res->ai_addr, res->ai_addrlen) == -1) {
      perror("connect");
      exit(1);
    }
    
    for (int i = 0; i < count; i++) {
      
      gettimeofday(&startedWriting[i], NULL);
      memcpy(buf, &startedWriting[i], sizeof(timeval));
      //gettimeofday((timeval*) buf, NULL);
      
      if (write(sockfd, buf, size) != size) {
        perror("write");
        return 1;
      }
      
      for (sofar = 0; sofar < size; ) {
        len = read(sockfd, buf, size - sofar);
        if (len == -1) {
          perror("read");
          return 1;
        }
        sofar += len;
      }
      
    }
    
    int64_t totalDelay = 0;
    for (int i = 0; i < count; i++) {
      int64_t delay = ((didRead[i].tv_sec - startedWriting[i].tv_sec) * (int64_t) 1e6 +
                         didRead[i].tv_usec - startedWriting[i].tv_usec);
      
      //NSLog("tcp_lat latency[%d]: %lli us", i, delay);
      totalDelay += delay;
      
      //int64_t t = startedWriting[i].tv_sec * (int64_t) 1e6 + startedWriting[i].tv_usec;
      //NSLog("tcp_lat PARENT startedWriting[%d] @ %lli", i, t);
    }
    
    NSLog(@"tcp_lat average latency: %lli us for messageSize %d X %d times", totalDelay / count, messageSize, messageCount);
    
    close(sockfd);
  }
  
  return 0;
}


+ (void) runPipeTestWithParent:(BOOL) parent {
  pipe_lat(messageSize, messageCount, parent);
}

+ (void) runUnixTestWithParent:(BOOL) parent {
  unix_lat(messageSize, messageCount, parent);
}

+ (void) runTCPTestWithParent:(BOOL) parent {
  tcp_lat(messageSize, messageCount, parent);
}


+ (void) runTCPTest {
  [NSThread detachNewThreadSelector:@selector(runTCPTestWithParent:) toTarget:self withObject:nil];
  [VariousUtilities runTCPTestWithParent:YES];
}

+ (void) runUnixTest {
  if (socketpair(AF_UNIX, SOCK_STREAM, 0, sv) == -1) {
    perror("socketpair");
    exit(1);
  }
  [NSThread detachNewThreadSelector:@selector(runUnixTestWithParent:) toTarget:self withObject:nil];
  [VariousUtilities runUnixTestWithParent:YES];
  close(sv[0]);
  close(sv[1]);
}

+ (void) runPipeTest {
  if (pipe(ofds) == -1) {
    perror("pipe");
    return;
  }
  
  if (pipe(ifds) == -1) {
    perror("pipe");
    return;
  }
  [NSThread detachNewThreadSelector:@selector(runPipeTestWithParent:) toTarget:self withObject:nil];
  [VariousUtilities runPipeTestWithParent:YES];
  close(ofds[0]);
  close(ofds[1]);
  close(ifds[0]);
  close(ifds[1]);
}

+ (void) runIPCTests {
  NSLog(@"Runing tests...");
  //[VariousUtilities runPipeTest];
  //[VariousUtilities runUnixTest];
  [VariousUtilities runTCPTest];
  //NSLog(@"Runing tests...DONE");
}

+ (NSString*) getMachineName {
  struct utsname systemInfo;
  uname(&systemInfo);
  return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
}

+ (BOOL) deviceCanHandleLargeFont {
  NSString* machineName = [VariousUtilities getMachineName];
  return [machineName hasPrefix:@"iPad"] || [machineName hasPrefix:@"iPhone5"];
}


@end
