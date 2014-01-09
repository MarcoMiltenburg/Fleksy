//
//  VariousUtilities.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/3/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StringConversion.h"

#define FLEKSY_LOADING_NOTIFICATION @"FLEKSY_LOADING_NOTIFICATION"

#define FLEKSY_NOTIFICATION_HEADSET_BUTTON_DOWN @"com.syntellia.fleksy.VolumeControl.headsetButtonDown"
#define FLEKSY_NOTIFICATION_HEADSET_BUTTON_UP   @"com.syntellia.fleksy.VolumeControl.headsetButtonUp"
#define FLEKSY_NOTIFICATION_MENU_BUTTON_DOWN    @"com.syntellia.fleksy.VolumeControl.menuButtonDown"
#define FLEKSY_NOTIFICATION_MENU_BUTTON_UP      @"com.syntellia.fleksy.VolumeControl.menuButtonUp"
#define FLEKSY_NOTIFICATION_INCREASE_VOLUME     @"com.syntellia.fleksy.VolumeControl.increaseVolume"
#define FLEKSY_NOTIFICATION_DECREASE_VOLUME     @"com.syntellia.fleksy.VolumeControl.decreaseVolume"
#define FLEKSY_NOTIFICATION_RINGER_ON           @"com.syntellia.fleksy.VolumeControl.ringerOn"
#define FLEKSY_NOTIFICATION_RINGER_OFF          @"com.syntellia.fleksy.VolumeControl.ringerOff"

#define FLEKSY_NOTIFICATION_SETTINGS_CHANGED    NSUserDefaultsDidChangeNotification

#define FLEKSY_NOTIFICATION_MENU_BUTTON_DOWN_UNHANDLED    @"com.syntellia.fleksy.VolumeControl.menuButtonDown_UNHANDLED"
#define FLEKSY_NOTIFICATION_MENU_BUTTON_UP_UNHANDLED      @"com.syntellia.fleksy.VolumeControl.menuButtonUp_UNHANDLED"

//#define FLEKSY_NOTIFICATION_SERVER_READY @"com.syntellia.fleksy.ServerReady"

// async is faster but sync might be needed to debug order
#define SYNC_LOGGING NO

//http://stackoverflow.com/questions/7017281/performselector-may-cause-a-leak-because-its-selector-is-unknown
#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)

enum {
  kSoundBackspace = 0,
  kSoundError,
  kSoundClick,
  kNumSounds
};


extern BOOL deviceIsPad();

extern UInt32 _sounds[kNumSounds];


@interface VariousUtilities : NSObject

+ (NSBundle*) theBundle;

+ (double) getNotificationDelay:(id) notification;

+ (void) postNotificationName:(NSString*) aName;
+ (void) addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName;
//load and sets up listener for changes
+ (void) loadSettingsAndListen:(id) target action:(SEL) action;

+ (id) getSettingNamed:(NSString*) setting fromSettings:(NSDictionary*) settings;


//////////// TODO: SPLIT categories / files

+ (NSString*) getPhoneticStringFor:(NSString*) string;
+ (NSString*) descriptionForCharacter:(FLChar) c;
+ (void) performAudioFeedbackFromString:(NSString*) string;
+ (void) stopSpeaking;

////////////////////////////

+ (BOOL) charIsAlpha:(unichar) cs;
+ (BOOL) string:(NSString*) string containsChar:(unichar) c;
+ (BOOL) string:(NSString*) string containsAnyCharacterInString:(NSString*) string2;
+ (NSString *) capitalizeString:(NSString *) s basedOn:(NSString *) cap;
+ (NSMutableArray*) explodeString:(NSString*) s;
+ (NSCharacterSet*) strictlyLettersSet;
+ (NSString*) onlyKeepAlphaFromString:(NSString*) string;

////////////////////////////

+ (void) print:(NSString*) string;
+ (void) vibrate;
+ (void) playTock;

////////////////////////////

//+ (void) insertObject:(id) obj inSortedArray:(NSMutableArray *) array usingComparator:(SEL) comparator;
//+ (NSArray *) getBestElements:(NSArray *) array usingSelector:(SEL) comparator elementsToReturn:(int) n;
  
////////////////////////////

+ (void) runIPCTests;



+ (NSString*) encode:(NSString*) string;
+ (NSString*) decode:(NSString*) string;


+ (NSString*) getMachineName;
+ (BOOL) deviceCanHandleLargeFont;

@end
