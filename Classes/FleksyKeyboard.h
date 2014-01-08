//
//  FleksyKeyboard.h
//
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FleksyKeyboardListener
@optional
// Called when user hits the return key
- (void) enteredNewLine;
// Called between small intervals while Fleksy is loading. Progress goes from 0 to 1 (fully loaded)
- (void) loadingProgress:(float) progress;
@end

@interface FleksyKeyboard : UIView<UIGestureRecognizerDelegate>

// Will initiate the loading of the dictionary. Clients that wish to do this asynchronously (non-blocking) should use performSelectorInBackground
- (void) startLoading;

// The current height of the keyboard
@property (readonly) float activeHeight;
@property (readonly) float visualHeight;

// The auditory label for the return key. Default is "New line", can be set to anything eg. "Send"
@property (readwrite) NSString* returnKeyLabel;


// Clients should set the listener right after initWithFrame
@property (readwrite) NSObject<FleksyKeyboardListener>* listener;

// Toggle speaking of words on and off
@property (readwrite) BOOL speakWords;

// Check if Fleksy has finished loading
@property (readonly) BOOL hasFinishedLoading;

@end
