//
//  FLUserDictionary.m
//  FleksyServer
//
//  Created by Kostas Eleftheriou on 7/20/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FLUserDictionary.h"
#import "Settings.h"

#define FL_WORD_PREFIX @"FL_WORD_"
#define FL_PERFORMED_INITIAL_SYNC @"FL_PERFORMED_INITIAL_SYNC"

@implementation FLUserDictionary 


- (id) initWithChangeListener:(id<FLUserDictionaryChangeListener>) _listener {
  NSLog(@"FLUserDictionary: initWithChangeListener: %@", _listener);
  if (self = [super init]) {
    self->listener = _listener;
  }
  return self;
}


//- (void) migrateFromFileToDefaultsIfNeeded {
//  
//  NSLog(@"migrateFromFileToDefaultsIfNeeded");
//
//  NSArray* lines = [[self stringContentOfFile] componentsSeparatedByString:@"\n"];
//  if (!lines) {
//    NSLog(@"No migration needed, no dictionary file found");
//    return;
//  }
//  
//  NSLog(@"lines: %@", lines);
//  NSMutableDictionary* temp = [[NSMutableDictionary alloc] init];
//  for (NSString* line in lines) {
//    NSString* trimmedLine = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//    if (!trimmedLine.length) {
//      continue;
//    }
//    NSLog(@"migrating line %@", line);
//    [self addWordFromLine:line notifyListener:NO];
//  }
//  
//  [[NSUserDefaults standardUserDefaults] synchronize];
//  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
//  
//  //finally delete file, we don't need it anymore
//  [[NSFileManager defaultManager] removeItemAtPath:[self filepath] error:nil];
//}

/*
 - (void) clearCloudDictionary {
  NSDictionary* dictionary = [[NSUbiquitousKeyValueStore defaultStore] dictionaryRepresentation];
  NSMutableArray* wordsToRemove = [[NSMutableArray alloc] init];
  for (NSString* key in [dictionary allKeys]) {
    if ([key hasPrefix:FL_WORD_PREFIX]) {
      [wordsToRemove addObject:key];
    }
  }
  for (NSString* word in wordsToRemove) {
    [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:word];
  }
  NSLog(@"deleted %d words from iCloud", wordsToRemove.count);
}

- (void) clearDefaultsDictionary {
  NSDictionary* dictionary = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  NSMutableArray* wordsToRemove = [[NSMutableArray alloc] init];
  for (NSString* key in [dictionary allKeys]) {
    if ([key hasPrefix:FL_WORD_PREFIX]) {
      [wordsToRemove addObject:key];
    }
  }
  for (NSString* word in wordsToRemove) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:word];
  }
  NSLog(@"deleted %d words from NSUserDefaults", wordsToRemove.count);
}*/

- (void) load {
  
  //[self clearCloudDictionary];
  //[self clearDefaultsDictionary];
  
  // we no longer use a file
  //[self migrateFromFileToDefaultsIfNeeded];
  
  NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
  //initial refresh
  NSLog(@"FLUserDictionary initial cloud refresh");
  for (NSString* key in [[store dictionaryRepresentation] allKeys]) {
    if ([key hasPrefix:FL_WORD_PREFIX]) {
      id value = [store objectForKey:key];
      [self addWordFromLine:value notifyListener:NO];
    }
  }
  //also monitor changes
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateKVStoreItems:) 
                                               name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification object:store];
  
  if (![store synchronize]) {
    NSLog(@"iCloud not available");
    //[NSException raise:@"iCloud Exception" format:@"synchronize returned NO"];
  }
  
  [self printCurrentStatus:@"load"];
}


- (void) printCurrentStatus:(NSString*) label {
  NSLog(@"printCurrentStatus: %@", label);
  NSLog(@"UserDefaults ALL:\n%@", [self stringContent]);
  NSLog(@"  iCloud     ALL: %@", [[NSUbiquitousKeyValueStore defaultStore] dictionaryRepresentation]);
  NSLog(@" hasPerformedInitialSync: %d", self.hasPerformedInitialSync);
}


- (void) updateKVStoreItems:(NSNotification*) notification {
  NSLog(@"updateKVStoreItems: %@", notification);
  // Get the list of keys that changed.
  NSDictionary* userInfo = [notification userInfo];
  NSNumber* reasonForChange = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangeReasonKey];
  NSInteger reason = -1;
  
  // If a reason could not be determined, do not update anything.
  if (!reasonForChange) {
    return;
  }
  
  // Update only for changes from the server.
  reason = [reasonForChange integerValue];
  
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  if ((reason == NSUbiquitousKeyValueStoreServerChange) ||
      (reason == NSUbiquitousKeyValueStoreInitialSyncChange)) {
    // If something is changing externally, get the changes
    // and update the corresponding keys locally.
    NSArray* changedKeys = [userInfo objectForKey:NSUbiquitousKeyValueStoreChangedKeysKey];
    NSUbiquitousKeyValueStore* store = [NSUbiquitousKeyValueStore defaultStore];
    
    // This loop assumes we are using the same key names in both
    // the user defaults database and the iCloud key-value store
    for (NSString* key in changedKeys) {
      id value = [store objectForKey:key];
      id oldObject = [userDefaults objectForKey:key];
      
      if ([key hasPrefix:FL_WORD_PREFIX]) {
        if (value) {
          [self addWordFromLine:value notifyListener:YES];
        } else {
          [self removeWord:[key stringByReplacingOccurrencesOfString:FL_WORD_PREFIX withString:@""] notifyListener:YES];
        }
      } else {
        [userDefaults setObject:value forKey:key];
      }
    }
  }
  
  if (reason == NSUbiquitousKeyValueStoreInitialSyncChange) {
    self.hasPerformedInitialSync = YES;
  }
  
  [self printCurrentStatus:@"after updateKVStoreItems"];
}


- (NSString*) keyForWord:(NSString*) word {
  return [NSString stringWithFormat:@"%@%@", FL_WORD_PREFIX, word];
}

- (BOOL) addWord:(NSString*) word frequency:(float) frequency notifyListener:(BOOL) notifyListener {
  
  if ([self containsWord:word]) {
    NSLog(@"WARNING: will not ADD duplicate user word %@", word);
    return NO;
  }
  
  NSString* line = [NSString stringWithFormat:@"%@\t%.1f", word, frequency];
  [[NSUserDefaults standardUserDefaults]    setObject:line forKey:[self keyForWord:word]];
  [[NSUbiquitousKeyValueStore defaultStore] setString:line forKey:[self keyForWord:word]];
  NSLog(@"Added word %@ to user dictionary, line: %@", word, line);
  if (notifyListener) {
    [listener addedUserWord:word frequency:frequency];
  }
  return YES;
}

- (BOOL) removeWord:(NSString*) word notifyListener:(BOOL) notifyListener {
  if (![self containsWord:word]) {
    NSLog(@"WARNING: could not REMOVE user word %@, not found", word);
    return NO;
  }
  
  [[NSUserDefaults standardUserDefaults]    removeObjectForKey:[self keyForWord:word]];
  [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:[self keyForWord:word]];
  if (notifyListener) {
    [listener removedUserWord:word];
  }
  NSLog(@"Removed word %@ from user dictionary", word);
  return YES;
}

// Prior: signature returned BOOL
- (void) addWordFromLine:(NSString*) line notifyListener:(BOOL) notifyListener {
  NSArray* components = [line componentsSeparatedByString:@"\t"];
  NSString* word = [components objectAtIndex:0];
  float frequency = components.count > 1 ? [[components objectAtIndex:1] floatValue] : FLEKSY_USER_WORD_FREQUENCY;
  [self addWord:word frequency:frequency notifyListener:notifyListener];
}


- (BOOL) containsWord:(NSString*) word {
  return [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@%@", FL_WORD_PREFIX, word]] != nil;
}


////////////////////

- (BOOL) hasPerformedInitialSync {
  BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:FL_PERFORMED_INITIAL_SYNC];
  if (!result) {
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  }
  return result;
}

- (void) setHasPerformedInitialSync:(BOOL)hasPerformedInitialSync {
  [[NSUserDefaults standardUserDefaults] setBool:hasPerformedInitialSync forKey:FL_PERFORMED_INITIAL_SYNC];
}

////////////////////


//- (NSString*) filepath {
//  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//  NSString* documentsDirectory = [paths objectAtIndex:0];
//  NSString* filepath = [documentsDirectory stringByAppendingPathComponent:FLEKSY_USER_DICTIONARY_FILE];
//  return filepath;
//}

- (NSString*) stringContent {
  NSMutableString* result = [[NSMutableString alloc] init];
  
  NSDictionary* defaults = [[NSUserDefaults standardUserDefaults] dictionaryRepresentation];
  for (NSString* key in [defaults allKeys]) {
    if ([key hasPrefix:FL_WORD_PREFIX]) {
      [result appendString:[defaults objectForKey:key]];
      [result appendString:@"\n"];
    }
  }

  NSLog(@"stringContent of user dictionary:\n%@", result);
  return result;
}

//- (NSString*) stringContentOfFile {
//  NSError* error;
//  NSString* result = [NSString stringWithContentsOfFile:[self filepath] encoding:NSUTF8StringEncoding error:&error];
//  if (error) {
//    NSLog(@"user dictionary error: %@", error);
//  } else {
//    NSLog(@"user dictionary contents:\n%@", result);
//  }
//  return result;
//}

@end
