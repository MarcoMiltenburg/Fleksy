//
//  Settings.h
//  PatternRecognizer
//
//  Copyright 2011 Syntellia Inc. All rights reserved.
//

#ifndef SETTINGS_H
#define SETTINGS_H


///////////////////////////////////////////

#define DEBUG_NO_WORDS 0

//if 0 also change bundle identifier to "com.syntellia.FleksyBETA" and product name to "Fleksy Beta"
#define APP_STORE 1

#define FLEKSY_EXPIRES !APP_STORE
#if FLEKSY_EXPIRES
#define FLEKSY_EXPIRES_YEAR 2013
#define FLEKSY_EXPIRES_MONTH 3
#define FLEKSY_EXPIRES_DAY 1
#define FLEKSY_EXPIRES_HOUR 12
#define FLEKSY_EXPIRES_MINUTE 0
#endif

#if APP_STORE
#define FLEKSY_PRODUCT_NAME @"Fleksy"
#else
#define FLEKSY_PRODUCT_NAME @"Fleksy Beta"
#endif

#ifdef RELEASE
#define NSLog(fmt,...)
#else
//#define NSLog(format,...) [VariousUtilities print:[NSString stringWithFormat:format, ##__VA_ARGS__]]
//#define NSLog(fmt,...) NSLogWhite(fmt,##__VA_ARGS__)
//#define NSLog(fmt,...)
#endif 

#ifdef APP_STORE
#define TestFlightLog(fmt,...)
#else
#define TestFlightLog(fmt,...) TFLog(fmt,##__VA_ARGS__)
#endif


#define FLEKSY_USE_SOCKETS 0
#define FLEKSY_RUN_SERVER 0
#define FLEKSY_RUN_CLIENT 1


// localhost seems to cause problems for hosting both server and client on same machine,
// possibly due to the IP lookup needed, also not sure if IPv4 or IPv6?
//#define SERVER_ADDRESS "localhost"
//#define SERVER_ADDRESS "::1" // IPv6 localhost
// This works: "127.0.0.1"

#if FLEKSY_USE_SOCKETS && FLEKSY_RUN_CLIENT && FLEKSY_RUN_SERVER
#define FLEKSY_SERVER_ADDRESS @"127.0.0.1"
#else
#define FLEKSY_SERVER_ADDRESS @"10.3.103.37"
#endif

#define FLEKSY_SERVER_PORT @"4567"


#define FLEKSY_USE_CUSTOM_GESTURE_DETECTION 0

#define FLEKSY_FULLSCREEN 1

#define FLEKSY_LOG NO

#define FLEKSY_DICTATE_WORDS 9

#define FLEKSY_STATUS_BAR_HIDDEN 1

#define FLEKSY_ACTIVATE_KEYBOARD_WARNING @"Activate keyboard with a single tap before typing"

#define FLEKSY_USER_WORD_FREQUENCY 10000.0

// If 1, traces start small and grow after every user tap, resetting on the next word
#define FLEKSY_INCREASING_TRACE_SIZE 1

// If FLEKSY_INCREASING_TRACE_SIZE is 0, what the fixed trace size is in pixels
#define FLEKSY_FIXED_TRACE_SIZE 14

// The maximum number of suggestions to show on the UI
#define FLEKSY_SUGGESTIONS_LIMIT (deviceIsPad() ? 10 : 7)

#define INVISIBLE_ALPHA 0.02

#define NEWLINE_UI_CHAR @"↓"

#define MyAccessibilityPostNotification(NOTIFICATION_TYPE, ARGUMENT) { /*NSLog(@"UIAccessibilityPostNotification(%u, %@)", NOTIFICATION_TYPE, ARGUMENT);*/ UIAccessibilityPostNotification(NOTIFICATION_TYPE, ARGUMENT);}

#define FacebookBlue [UIColor colorWithRed:0.23 green:0.35 blue:0.59 alpha:1];

extern bool FLEKSY_APP_SETTING_SPEAK;
extern bool FLEKSY_APP_SETTING_KEYBOARD_CLICKS;
extern bool FLEKSY_APP_SETTING_SHOW_TRACES;
extern bool FLEKSY_APP_SETTING_KEY_SNAP; //useful for testing
extern bool FLEKSY_APP_SETTING_INVISIBLE_KEYBOARD;
extern bool FLEKSY_APP_SETTING_TOUCH_HOME;
extern bool FLEKSY_APP_SETTING_USE_SYSTEM_AUTOCORRECTION;
extern bool FLEKSY_APP_SETTING_DICTATE_MODE;
extern bool FLEKSY_APP_SETTING_SHOW_SUGGESTIONS; //TODO
extern bool FLEKSY_APP_SETTING_LIVE_SUGGESTIONS; //TODO
extern NSString* FLEKSY_APP_SETTING_HOME_BUTTON_STRING;
extern NSString* FLEKSY_APP_SETTING_SPEED_DIAL_1;
extern NSString* FLEKSY_APP_SETTING_SMS_REPLY_TO;
extern NSString* FLEKSY_APP_SETTING_EMAIL_REPLY_TO;
extern float FLEKSY_APP_SETTING_SPEAKING_RATE;
extern int  FLEKSY_APP_SETTING_LOCK_ORIENTATION;
extern bool FLEKSY_APP_SETTING_SPELL_WORDS;
extern bool FLEKSY_APP_SETTING_RAISE_TO_SPEAK;
extern NSString* FLEKSY_APP_SETTING_EMAIL_SIGNATURE;
extern bool FLEKSY_APP_SETTING_EMAIL_INCLUDE_FIRST_LINE;
extern bool FLEKSY_APP_SETTING_SPACE_BUTTON;
extern NSString* FLEKSY_APP_SETTING_LANGUAGE_PACK;

//extern bool FLEKSY_CORE_SETTING_USE_SEARCH_FILTER;

#endif