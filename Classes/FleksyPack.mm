//
//  FleksyPack.m
//  iFleksy
//
//  Created by Vince Mansel on 3/26/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FleksyPack.h"
#import "FileManager.h"
#import "FleksyUtilities.h"
#import "FLTypingController_iOS.h"
#import "VariousUtilities.h"
#import "Settings.h"
#import "MathFunctions.h"
#import "FLKeyboardContainerView.h"

#define LOADING_TIMER_STEP 4

@interface FleksyPack ()
{
    UIWindow *window;
}
@end

@implementation FleksyPack

@synthesize fleksyAppViewController;

+ (id)sharedFleksyPack
{
    static FleksyPack *__sharedFleksyPack;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedFleksyPack = [[FleksyPack alloc] init];
    });
    
    return __sharedFleksyPack;
}

- (void) setupViewController:(FleksyAppMainViewController *)aFleksyAppViewController inWindow:aWindow
{
    fleksyAppViewController = aFleksyAppViewController;
    window = aWindow;
    [self performSelectorOnMainThread:@selector(nowLaunching) withObject:nil waitUntilDone:NO];
}

- (void)nowLaunching
{
    NSDictionary* settings = [FileManager settings];
    if (!settings) {
        NSLog(@"no settings!");
        return;
    }
    
    NSLog(@"Machine ID: %@\nModel: %@\nLocalized Model: %@", [VariousUtilities getMachineName], [[UIDevice currentDevice] model], [[UIDevice currentDevice] localizedModel]);
    NSLog(@"screen bounds: %@, application frame: %@", NSStringFromCGRect([[UIScreen mainScreen] bounds]), NSStringFromCGRect([[UIScreen mainScreen] applicationFrame]));
    NSLog(@"sizeof(FLChar): %lu", sizeof(FLChar));
    NSLog(@"FLEKSY_APP_SETTING_LANGUAGE_PACK: %@", FLEKSY_APP_SETTING_LANGUAGE_PACK);
    
    BOOL ok = [[[NSBundle mainBundle] bundlePath] hasSuffix:[NSString stringWithFormat:@"%@.app", FLEKSY_PRODUCT_NAME]];
    assert(ok);
    
    [fleksyAppViewController.purchaseManager incrementRuns];

    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"iOS build %@ (4.21/2.21)", version] forKey:@"FLEKSY_APP_SETTING_VERSION"];
    
    RANDOM_SEED();
    
    [[UIApplication sharedApplication] setStatusBarHidden:FLEKSY_STATUS_BAR_HIDDEN];
    //[[UIApplication sharedApplication] statusBarOrientation];
    
    // now create the custom keyboard view
    // this seems to always be aligned at the bottom and width is set to screen width
    // Need to create before window.rootViewController and [window makeKeyAndVisible] to make sure we already have loaded settings such as FLEKSY_APP_SETTING_LOCK_ORIENTATION
    customInputView = [[FleksyKeyboard alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [customInputView performSelector:@selector(handleSettingsChanged:) withObject:nil];
    UIInterfaceOrientation orientation = FLEKSY_APP_SETTING_LOCK_ORIENTATION ?  (UIInterfaceOrientation) FLEKSY_APP_SETTING_LOCK_ORIENTATION : (UIInterfaceOrientation) [UIDevice currentDevice].orientation; //fleksyAppViewController.interfaceOrientation
    CGRect frame = [fleksyAppViewController keyboardFrameForOrientation:orientation];
    NSLog(@"using frame %@", NSStringFromCGRect(frame));
    customInputView.frame = frame;
    customInputView.listener = self;
    
    [self finishLoadingUI];

}

- (void) finishLoadingUI {
    
    NSLog(@"START of finishLoadingUI");
    
    double startTime = CFAbsoluteTimeGetCurrent();
    
#if !DEBUG_NO_WORDS
    [fleksyAppViewController showAlerts];
#endif
    
    CGRect rect = [[UIScreen mainScreen] applicationFrame];
    NSLog(@"applicationFrame: %@, bounds: %@", NSStringFromCGRect(rect), NSStringFromCGRect([[UIScreen mainScreen] bounds]));
    
    textView = [[FleksyTextView alloc] initWithFrame:window.bounds];
    
    [textView setInputView:customInputView];
    
    
    [fleksyAppViewController.view addSubview:textView];
    fleksyAppViewController.textView = textView;
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:)  name:UIKeyboardDidShowNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:)  name:UIKeyboardDidHideNotification  object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(proximityChanged:) name:UIDeviceProximityStateDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(voiceOverStatusChanged:) name:UIAccessibilityVoiceOverStatusChanged object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textCopiedToClipboard:) name:UIPasteboardChangedNotification object:nil];
    
    [self voiceOverStatusChanged:nil];
    
    //[FleksyKeyboard enableFleksyForWebViews];
    [self startLoadingProgressTimer];
    [customInputView performSelectorInBackground:@selector(startLoading) withObject:nil];
    
    NSLog(@"END of finishLoadingUI, took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
}

- (void) handleOpenURL:(NSURL *)url
{
    if ([url.scheme hasPrefix:@"reply"]) {
        
        NSString* string = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
        NSLog(@"send to: %@", string);
        //NSLog(@"host: %@", [url host]);
        if (fleksyAppViewController.purchaseManager.fullVersion) {
            [fleksyAppViewController setReplyTo:string];
        }
        [fleksyAppViewController resetState];
        
    } else if ([url.scheme hasPrefix:@"fleksy"]) {
        
        [self addWordsForURL:url];
    }
}

- (void) addWordsForURL:(NSURL *)url
{
    NSString* string = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    if ([string hasPrefix:@"_ADD_WORDS:"]) {
        string = [string stringByReplacingOccurrencesOfString:@"_ADD_WORDS:" withString:@""];
        int wordsAdded = 0;
        for (NSString* wordString in [string componentsSeparatedByString:@":"]) {
            NSString* word = [[wordString componentsSeparatedByString:@"_"] objectAtIndex:0];
            //double frequency = [[[wordString componentsSeparatedByString:@"_"] objectAtIndex:1] doubleValue];
            if (FLAddWordResultAdded == [[FLTypingController_iOS sharedFLTypingController_iOS].fleksyClient addedUserWord:word frequency:FLEKSY_USER_WORD_FREQUENCY]) {
                wordsAdded++;
            }
        }
        [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Added %d new words", wordsAdded]];
    }
}

- (void) loadingStep {
    textView.text = [NSString stringWithFormat:@"%@ .", textView.text];
    [VariousUtilities performAudioFeedbackFromString:@"Loading"];
}

- (void) fleksyLoaded {
    [NSTimer cancelPreviousPerformRequestsWithTarget:self selector:@selector(startLoadingProgressTimer) object:nil];
    [loadingTimer invalidate];
    loadingTimer = nil;
    
    textView.text = @"";
    [textView makeReady];
#if !DEBUG_NO_WORDS
    [VariousUtilities performAudioFeedbackFromString:@"Fleksy is ready"];
#endif
    [fleksyAppViewController applicationFinishedLoading];
    
    [VariousUtilities playTock];
}

- (void) loadingProgress:(float) progress {
    if (progress == 1) {
        //UIKit stuff has to be done on main thread, and this will be called from the thread where
        //the notification was posted, which might not be the main thread
        [self performSelectorOnMainThread:@selector(fleksyLoaded) withObject:nil waitUntilDone:NO];
    }
}

- (void) startLoadingProgressTimer {
    loadingTimer = [NSTimer scheduledTimerWithTimeInterval:LOADING_TIMER_STEP target:self selector:@selector(loadingStep) userInfo:nil repeats:YES];
}

- (void) textCopiedToClipboard:(NSNotification*) notification {
    UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
    NSLog(@"textCopiedToClipboard1: %@", pasteboard.string);
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIPasteboardChangedNotification object:nil];
    if (!fleksyAppViewController.purchaseManager.fullVersion) {
        [pasteboard setString:@"Please purchase the full version of Fleksy to copy and paste"];
    }
    NSLog(@"textCopiedToClipboard2: %@", pasteboard.string);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textCopiedToClipboard:) name:UIPasteboardChangedNotification object:nil];
}


- (void) voiceOverStatusChanged:(NSNotification*) notification {
    NSLog(@"AppDelegate voiceOverStatusChanged: %d", UIAccessibilityIsVoiceOverRunning());
}

- (void) setKeyboardState:(BOOL) hidden {
    return;
    
    NSLog(@"setKeyboardState %d", hidden);
    //MyAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    //MyAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
    textView.inputView.hidden = hidden;
    textView.inputView.isAccessibilityElement = !hidden;
    textView.inputView.multipleTouchEnabled = !hidden;
}

- (void) keyboardDidChangeFrame:(NSNotification*) notification {
    //CGRect rect1 = [[[notification userInfo] valueForKey:@"UIKeyboardFrameEndUserInfoKey"] CGRectValue];
    //NSLog(@"keyboardDidChangeFrame: %@", notification);
}

- (void) keyboardWillShow:(NSNotification*) notification {
    //NSLog(@"AppDelegate keyboardWillShow: %@", notification);
    [self setKeyboardState:NO];
    [self performSelector:@selector(removeKeyboardShadow) withObject:nil afterDelay:0.0];
}

- (void) keyboardDidShow:(NSNotification*) aNotification {
    //window.windowLevel = UIWindowLevelAlert;
    //textView.inputView.window.windowLevel = UIWindowLevelNormal - 1;
    //NSLog(@" > > keyboardDidShow, window: %@, level: %.6f, level0: %.6f", textView.inputView.window, textView.inputView.window.windowLevel, window.windowLevel);
    [self setKeyboardState:NO];
    //[window makeKeyAndVisible];
    //window.accessibilityViewIsModal = YES;
    //window.accessibilityTraits |= UIAccessibilityTraitAllowsDirectInteraction;
}

//https://gist.github.com/3732403
- (void)removeKeyboardShadow {
    
    //@"UIPeripheralHostView";
    NSString* s = @"33-59-63-9-29-5-23-12-22-19-9-8-60-29-28-24-57-5-2-19-";
    for (UIWindow* w in [UIApplication sharedApplication].windows.reverseObjectEnumerator) {
        if (![w.class isEqual:[UIWindow class]]) {
            for (UIView* view in w.subviews) {
                if (strcmp([[VariousUtilities decode:s] UTF8String], object_getClassName(view)) == 0) {
                    UIView *shadowView = view.subviews[0];
                    if ([shadowView isKindOfClass:[UIImageView class]]) {
                        shadowView.hidden = YES;
                        return;
                    }
                }
            }
        }
    }
}

- (void) keyboardWillHide:(id) ddd {
    //NSLog(@"AppDelegate keyboardWillHide");
    [self setKeyboardState:YES];
}


- (void) keyboardDidHide:(id) ddd {
    [self setKeyboardState:YES];
}


+ (void) setProximityMonitoringEnabled:(BOOL) b {
    //NSLog(@"setProximityMonitoring: %d", b);
    [[UIDevice currentDevice] setProximityMonitoringEnabled:b && FLEKSY_APP_SETTING_RAISE_TO_SPEAK];
}

- (void) speakCurrentText {
    
    if (![fleksyAppViewController shouldSpeakText]) {
        return;
    }
    
    NSString* text = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!text.length) {
        text = @"There is no text";
    }
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView cancelAllSpellingRequests];
    [VariousUtilities performAudioFeedbackFromString:text];
}

- (void) proximityChanged:(id) ddd {
    
    NSLog(@"proximity changed");
    
    if (self.loading) {
        NSLog(@"Ignoring proximityChanged while loading...");
        return;
    }
    
    [VariousUtilities stopSpeaking];
    
    BOOL b = [UIDevice currentDevice].proximityState;
    //NSLog(@"proximityChanged: %d, hovering: %d", b, hovering);
    if (b) {
        [self speakCurrentText];
    }
}

- (void)applicationWillResignActive {
    //[mainViewController addSendTo:@"dssdadsasda"];
    [[NSNotificationCenter defaultCenter] removeObserver:fleksyAppViewController name:UIAccessibilityVoiceOverStatusChanged object:nil];
    lastKnownVoiceOverState = UIAccessibilityIsVoiceOverRunning();
    //NSLog(@"applicationWillResignActive, lastKnownVoiceOverState: %d", lastKnownVoiceOverState);
    [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView cancelAllSpellingRequests];
    [VariousUtilities stopSpeaking];

}

- (void)applicationWillEnterForeground {
    
    [customInputView performSelector:@selector(handleSettingsChanged:) withObject:nil];
    
    //[fleksyAppViewController.view setNeedsLayout];
}

- (void)applicationDidEnterForeground {
    
}

- (void)applicationDidBecomeActive {
    
    //[SettingsView prepareSystemKeyboard];
    
    //[customView setCurrentResponder:textView];
    
    [UIViewController attemptRotationToDeviceOrientation];
    
    [textView reloadInputViews];
    
    //  if (textView.isEditable) {
    //    //otherwise keyboard is not "connected" to textView anymore
    //    [textView reloadInputViews];
    //  }
    
    [[NSNotificationCenter defaultCenter] addObserver:fleksyAppViewController selector:@selector(voiceOverStatusChanged:) name:UIAccessibilityVoiceOverStatusChanged object:nil];
    
    if (lastKnownVoiceOverState == UIAccessibilityIsVoiceOverRunning()) {
        //NSLog(@"lastKnownVoiceOverState == UIAccessibilityIsVoiceOverRunning(), no need to call voiceOverStatusChanged:");
    } else {
        //NSLog(@"lastKnownVoiceOverState != UIAccessibilityIsVoiceOverRunning(), will force-call voiceOverStatusChanged:");
        [fleksyAppViewController voiceOverStatusChanged:nil];
    }
    
    [fleksyAppViewController startButtonAnimation];
}

- (BOOL) loading {
    return loadingTimer != nil;
}

#if FLEKSY_EXPIRES

- (NSDate*) getMagic {
    NSCalendar* gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [gregorian setLocale:[NSLocale currentLocale]];
    NSDateComponents* components = [[NSDateComponents alloc] init];
    [components setYear:FLEKSY_EXPIRES_YEAR];
    [components setMonth:FLEKSY_EXPIRES_MONTH];
    [components setDay:FLEKSY_EXPIRES_DAY];
    [components setHour:FLEKSY_EXPIRES_HOUR];
    [components setMinute:FLEKSY_EXPIRES_MINUTE];
    NSDate* result = [gregorian dateFromComponents:components];
    return result;
}

- (BOOL) magicOK {
    NSDate* now = [NSDate date];
    NSDate* magic = [self getMagic];
    NSTimeInterval interval = [now timeIntervalSinceDate:magic];
    NSLog(@"now:   %@", now);
    NSLog(@"magic: %@", magic);
    NSLog(@"interval: %6f", interval);
    return interval < 0;
}

#endif


@end
