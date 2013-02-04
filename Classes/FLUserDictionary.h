//
//  FLUserDictionary.h
//  FleksyServer
//
//  Created by Kostas Eleftheriou on 7/20/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FleksyUtilities.h"

//#define FLEKSY_USER_DICTIONARY_FILE @"wordlist-user.txt"

@protocol FLUserDictionaryChangeListener

- (FLAddWordResult) addedUserWord:(NSString*) word frequency:(float) frequency;
- (bool) removedUserWord:(NSString*) word;

@end

@interface FLUserDictionary : NSObject {
  //NSMutableDictionary* dictionary;
  id<FLUserDictionaryChangeListener> listener;
}

- (id) initWithChangeListener:(id<FLUserDictionaryChangeListener>) listener;
- (void) load;

- (BOOL) containsWord:(NSString*) word;
- (BOOL) addWord:(NSString*) word frequency:(float) frequency notifyListener:(BOOL) notifyListener;
- (BOOL) removeWord:(NSString*) word notifyListener:(BOOL) notifyListener;

/////
//- (NSString*) stringContentOfFile;
- (NSString*) stringContent;

@property BOOL hasPerformedInitialSync;

@end
