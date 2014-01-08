#import "AppDelegate.h"
#import "FLKeyboardContainerView.h"
#import "FLWord.h"

#import "MathFunctions.h"
#import "Settings.h"
#import "FleksyUtilities.h"

#import "FLKeyboardView.h"

#import "Accelerate/Accelerate.h"
#import "VariousUtilities.h"

#import "FileManager.h"

#import "UIRotorRecognizer.h"
#import <QuartzCore/QuartzCore.h>
#include "Crashlytics/Crashlytics.h"

#include <string>

#import <PatternRecognizer/Platform.h>

#import "FleksyAppMainViewController.h"

// Generic itunes link on the device
#define APP_STORE_LINK @"itms-apps://itunes.apple.com/app/id793539091"

// TODO: Do AppStore Lookup and parse to inform user of update:
// http://itunes.apple.com/lookup?id=793539091
// http://charcoaldesign.co.uk/source/cocoa#iversion
// https://github.com/nicklockwood/iVersion

#define randf() ( rand() / (RAND_MAX + 1.0f) )

#define LAST_VERSION_KEY @"FleksyLastRunVersion"
#define LOADING_TIMER_STEP 4


@class UIKeyboard;

float distributionFunction(float x);

@interface AppDelegate () <UIAlertViewDelegate>

@end

@implementation AppDelegate

//@synthesize themeManager = _themeManager;

float distributionFunction(float x) {
  
  float mean = 0;
  float std = 1;
  
  float power = -powf(x - mean, 2.0f) / (2.0f * std);
  float result = 1.0f / sqrtf(2.0f * M_PI * std) * expf(power);
  return result;
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
  NSLog(@"Listener %@ progress = %f of Notification NOW on Thread = %@", self, progress, [NSThread currentThread]);
  if (progress == 1) {
    //UIKit stuff has to be done on main thread, and this will be called from the thread where
    //the notification was posted, which might not be the main thread
    [self performSelectorOnMainThread:@selector(fleksyLoaded) withObject:nil waitUntilDone:NO];
    //[self fleksyLoaded];
  }
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  NSLog(@"openURL: %@, scheme: %@, sourceApplication: %@, annotation: %@", url, url.scheme, sourceApplication, annotation);
  
  if ([url.scheme hasPrefix:@"reply"]) {
    
    NSString* string = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    NSLog(@"send to: %@", string);
    //NSLog(@"host: %@", [url host]);
    if (fleksyAppViewController.purchaseManager.fullVersion) {
      [fleksyAppViewController setReplyTo:string];
    }
    [fleksyAppViewController resetState];
      
      return YES;
    
  } else if ([url.scheme hasPrefix:@"fleksy"]) {
    
    NSString* string = [[url resourceSpecifier] stringByReplacingOccurrencesOfString:@"//" withString:@""];
    if ([string hasPrefix:@"_ADD_WORDS:"]) {
      string = [string stringByReplacingOccurrencesOfString:@"_ADD_WORDS:" withString:@""];
      int wordsAdded = 0;
      for (NSString* wordString in [string componentsSeparatedByString:@":"]) {
        NSString* wordToAddRemove = [[wordString componentsSeparatedByString:@"_"] objectAtIndex:0];
        //double frequency = [[[wordString componentsSeparatedByString:@"_"] objectAtIndex:1] doubleValue];
        
        FLAddWordResult result = [[FLTypingController_iOS sharedFLTypingController_iOS].fleksyClient addedUserWord:wordToAddRemove frequency:FLEKSY_USER_WORD_FREQUENCY];
        
        switch (result) {
            
          case FLAddWordResultAdded:
            
            NSLog(@"Added word %@ to memory", wordToAddRemove);
            if ([[FLTypingController_iOS sharedFLTypingController_iOS].fleksyClient.userDictionary addWord:wordToAddRemove frequency:FLEKSY_USER_WORD_FREQUENCY notifyListener:NO]) {
              NSLog(@"Added %@ to dictionary", wordToAddRemove);
              wordsAdded++;
            } else {
              NSLog(@"Error adding %@ to dictionary", wordToAddRemove);
            }
            break;
            
          case FLAddWordResultExists:
            NSLog(@"%@ already exists in dictionary", wordToAddRemove);
            break;
            
          case FLAddWordResultTooLong:
            NSLog(@"%@ is too long, could not add to dictionary", wordToAddRemove);
            break;
            
          case FLAddWordResultWordIsBlacklisted:
            NSLog(@"%@ is blacklisted, could not add to dictionary", wordToAddRemove);
            break;
            
          default:
            NSLog(@"Could not add word %@, some error occurred (%d)", wordToAddRemove, result);
            break;
        }
        
      }
      NSString* s = [NSString stringWithFormat:@"Added %d words to dictionary", wordsAdded];
      [VariousUtilities performAudioFeedbackFromString:s];
      NSLog(@"%@", s);
      [[[UIAlertView alloc] initWithTitle:@"Import" message:s delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil] show];

    }
    
    return YES;
  }
  return NO;
}

- (void) startLoadingProgressTimer {
  loadingTimer = [NSTimer scheduledTimerWithTimeInterval:LOADING_TIMER_STEP target:self selector:@selector(loadingStep) userInfo:nil repeats:YES];
}

- (void) buttonPressed {
  NSLog(@"buttonPressed");
}

//- (BOOL) checkVersionOKToRun {
//  
//#ifdef APP_STORE
//  return YES;
//#endif
//
//  NSString* currentVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
//  NSString* previousVersion = [[NSUserDefaults standardUserDefaults] stringForKey:LAST_VERSION_KEY];
//  [[NSUserDefaults standardUserDefaults] setObject:currentVersion forKey:LAST_VERSION_KEY];
//  
//  int previousRuns = fleksyAppViewController.purchaseManager.previousRuns;
//  
//  NSLog(@"previousVersion: %@, currentVersion: %@, previousRuns: %d", previousVersion, currentVersion, previousRuns);
//
//  BOOL ok = previousRuns && (!previousVersion || [previousVersion isEqualToString:currentVersion]);
//  
//  return ok;
//}

- (void) applicationDidFinishLaunching:(UIApplication *) application loadServer:(BOOL) loadServer {
  
  double startTime = CFAbsoluteTimeGetCurrent();
  
  ////////////////////// MASTER SWITCHES //////////////////////
  
#ifdef FL_BUILD_FOR_DEVELOPMENT
  printf("SCHEME: FL_BUILD_FOR_DEVELOPMENT\n");
#endif
  
#ifdef FL_BUILD_FOR_BETA
    printf("SCHEME: FL_BUILD_FOR_BETA\n");
#endif
  
#ifdef FL_BUILD_FOR_TESTFLIGHT
    printf("SCHEME: FL_BUILD_FOR_TESTFLIGHT\n");
#endif
  
#ifdef FL_BUILD_FOR_APP_STORE
    //printf("SCHEME: FL_BUILD_FOR_APP_STORE\n");
#endif
  
  ///////////////////////////////////////////////////////////


#ifdef RELEASE
  //printf("Fleksy RELEASE\n");
  
  [TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                          @NO, TFOptionDisableInAppUpdates,
                          @NO, TFOptionLogToConsole,
                          @NO, TFOptionLogToSTDERR, nil]];
  
#ifdef FL_BUILD_FOR_APP_STORE
  [TestFlight takeOff:@"91f69c10-d1a3-4e7a-905d-dea51af78a82"];
#else
  printf("Fleksy TESTFLIGHT ONLY\n");
//http://blog.goosoftware.co.uk/2012/04/18/unique-identifier-no-warnings/
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
  [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#pragma clang diagnostic pop
  [TestFlight takeOff:@"c71a4345-0f62-4435-bf92-fb68f1c20d3a"]; 
#endif
#endif

#if CRASHLYTICS
#ifndef FL_BUILD_FOR_APP_STORE
    printf("Fleksy CRASHLYTICS\n");
#endif
    [Crashlytics startWithAPIKey:@"8437e63c5dcbeca15784fa67dd5fab1275a867a5"];
#endif

#ifdef DEBUG
  printf("%s DEBUG\n", FLEKSY_PRODUCT_NAME.UTF8String);
#endif

#ifdef FL_BUILD_FOR_APP_STORE
  //printf("Fleksy APP_STORE\n");
#else
  printf("Fleksy NOT app_store\n");
#endif
  
//  self.theme = [FLTheme theme];
//  self.theme.currentThemeType = FLThemeTypeNormal; //
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeDidChange:) name:FleksyThemeDidChangeNotification object:nil];
  
  self.themeManager = [FLThemeManager sharedManager];
  
  NSDictionary* settings = [FileManager settings];
  if (!settings) {
    NSLog(@"no settings!");
    return;
  }
  FLEKSY_APP_SETTING_LANGUAGE_PACK = [VariousUtilities getSettingNamed:@"FLEKSY_APP_SETTING_LANGUAGE_PACK" fromSettings:settings];

  
  NSLog(@"Machine ID: %@\nModel: %@\nLocalized Model: %@", [VariousUtilities getMachineName], [[UIDevice currentDevice] model], [[UIDevice currentDevice] localizedModel]);
  NSLog(@"screen bounds: %@, application frame: %@", NSStringFromCGRect([[UIScreen mainScreen] bounds]), NSStringFromCGRect([[UIScreen mainScreen] applicationFrame]));  
  NSLog(@"sizeof(FLChar): %lu", sizeof(FLChar));
  NSLog(@"FLEKSY_APP_SETTING_LANGUAGE_PACK: %@", FLEKSY_APP_SETTING_LANGUAGE_PACK);
  NSLog(@"FLEKSY_PRODUCT_NAME: %@ : BundlePath: %@", FLEKSY_PRODUCT_NAME, [[NSBundle mainBundle] bundlePath]);
  
  BOOL ok = [[[NSBundle mainBundle] bundlePath] hasSuffix:[NSString stringWithFormat:@"%@.app", FLEKSY_PRODUCT_NAME]];
  assert(ok);
#pragma unused(ok)
  fleksyAppViewController = [[FleksyAppMainViewController alloc] initWithNibName:nil bundle:nil];
  
//  if ([self checkVersionOKToRun]) {
    [fleksyAppViewController.purchaseManager incrementRuns];
//  } else {
//    [[[UIAlertView alloc] initWithTitle:@"Cannot run this version of Fleksy"
//                               message:@"Please follow these four steps:\n1. Delete Fleksy\n2. Download the latest Fleksy from the App Store.\n3. You must run the App Store version at least once.\n4. Try updating with this version again" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
//    return;
//  }
  
  RANDOM_SEED();
  
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
  
  [[UIApplication sharedApplication] setStatusBarHidden:FLEKSY_STATUS_BAR_HIDDEN];
  //[[UIApplication sharedApplication] statusBarOrientation];
  
  //we use bounds here and not application frame, since the view controller inside will adjust accordingly for the status bar
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  window.backgroundColor = FLEKSYTHEME.window_backgroundColor;
  window.rootViewController = fleksyAppViewController;
  // Show the window
  [window makeKeyAndVisible];

  [self performSelectorOnMainThread:@selector(finishLoadingUI) withObject:nil waitUntilDone:NO];
  
  NSString* apiVersionShort = [self parseApiVersion:[[NSUserDefaults standardUserDefaults] objectForKey:FLEKSY_APP_API_VERSION_KEY]];
  NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  NSString* versionShort = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@-%@ (%@)", versionShort, version, apiVersionShort] forKey:@"FLEKSY_APP_SETTING_VERSION"];
  
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  [[NSUserDefaults standardUserDefaults] synchronize];
                               
  NSLog(@"TotalVersionString: %@", [NSString stringWithFormat:@"%@-%@ (%@)", versionShort, version, apiVersionShort]);

  NSLog(@"END of applicationDidFinishLaunching, took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
#pragma unused(startTime)
}

#pragma mark - FLTheme Notification Handlers

- (void)handleThemeDidChange:(NSNotification *)aNote {
  NSLog(@"%s = %@", __PRETTY_FUNCTION__, aNote);
  window.backgroundColor = FLEKSYTHEME.window_backgroundColor;
  // TODO: This does not appear to have an effect...
  [window makeKeyAndVisible];
  //[window setNeedsLayout];
}

                               
- (NSString *)parseApiVersion:(NSString *)apiVersion
{
//  API v.0.2 (77909ce0d9cf279e2818a831d7982a5f1b481288-kostas @ Thu Apr 18 00:09:22 UTC 2013)
//  SystemsIntegrator v2.50
//  TypingController v135
// Just use the v.0.2 (the 2nd token)
  
  return [[apiVersion componentsSeparatedByString:@" "] objectAtIndex:1];
}


- (void) finishLoadingUI {

  NSLog(@"START of finishLoadingUI");

  double startTime = CFAbsoluteTimeGetCurrent();
#pragma unused(startTime)
  
#if !DEBUG_NO_WORDS
  [fleksyAppViewController showAlerts];
#endif


  CGRect rect = [[UIScreen mainScreen] applicationFrame];
//http://stackoverflow.com/questions/5451123/how-can-i-get-rid-of-an-unused-variable-warning-in-xcode
#pragma unused(rect)
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
  
  [self startLoadingProgressTimer];
  
  // Require load on mainThread, i.e. UIKit objects.
  [customInputView startLoading];
    
  NSLog(@"END of finishLoadingUI, took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
}


//[[HookingUtilities sharedHookingUtilities] swapMethodNamed:@"_slideSheetOut:" inClassNamed:@"UIActionSheetAccessibility" withSameMethodInClassNamed:@"AppDelegate"];
//- (void) _slideSheetOut:(BOOL) c {
//  NSLog(@"_slideSheetOut: %d", c);
//  IMP orgIMP = [[HookingUtilities sharedHookingUtilities] originalMethodNamed:@"_slideSheetOut:" inClass:[self class]];
//  orgIMP(self, nil, c);
//}


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


- (void) setProximityMonitoringEnabled:(BOOL) b {
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

//- (void) playError {
//  AudioServicesPlaySystemSound(_sounds[kSoundError]);
//}


//- (void) applicationLoadClientOnly:(UIApplication *) application {
  //dont do this, just notify/signal lock
  //[self applicationDidFinishLaunching:application loadServer:NO];
//}


- (void) applicationDidFinishLaunching:(UIApplication *) application {
  [self applicationDidFinishLaunching:application loadServer:LOAD_SERVER];
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  // Do whatever you need to do here
  NSLog(@"observeValueForKeyPath: %@ ofObject: %@ change: %@ context: %@", keyPath, object, change, context);
}


/*
- (void) setBackgroundColor:(UIColor*) color {
  
  IMP orgIMP = [[HookingUtilities sharedHookingUtilities] originalMethodNamed:@"setBackgroundColor:" inClass:[self class]];
  NSLog(@"%@ color %@", self, color);
  //color = [UIColor blueColor];
 
  [self addObserver:[UIApplication sharedApplication].delegate forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:[UIApplication sharedApplication].delegate forKeyPath:@"center" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:[UIApplication sharedApplication].delegate forKeyPath:@"bounds" options:NSKeyValueObservingOptionNew context:nil];
  [self addObserver:[UIApplication sharedApplication].delegate forKeyPath:@"transform" options:NSKeyValueObservingOptionNew context:nil];
  
  
  orgIMP(self, nil, color);
}*/

- (void)applicationWillResignActive:(UIApplication *)application {
  [[NSUserDefaults standardUserDefaults] synchronize];
  //[mainViewController addSendTo:@"dssdadsasda"];
  [[NSNotificationCenter defaultCenter] removeObserver:fleksyAppViewController name:UIAccessibilityVoiceOverStatusChanged object:nil];
  lastKnownVoiceOverState = UIAccessibilityIsVoiceOverRunning();
  //NSLog(@"applicationWillResignActive, lastKnownVoiceOverState: %d", lastKnownVoiceOverState);
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView cancelAllSpellingRequests];
  [VariousUtilities stopSpeaking];
  
  if (FLEKSY_APP_SETTING_COPY_ON_EXIT && ![textView.text isEqualToString:@""]) {
    [fleksyAppViewController copyText];
    [fleksyAppViewController resetState];
  }
  
  if (FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER) {
    [fleksyAppViewController saveText];
  }
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
  NSLog(@"applicationWillEnterForeground");
  [customInputView performSelector:@selector(handleSettingsChanged:) withObject:nil];
  
//  if ([self checkForFleksyLibraryExpiration]) {
//    return;
//  }
  
  //[fleksyAppViewController.view setNeedsLayout];
}

- (void)applicationDidEnterForeground:(UIApplication*)application {
  NSLog(@"applicationDidEnterForeground");
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"applicationDidBecomeActive");
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


- (void) applicationDidReceiveMemoryWarning:(UIApplication *) application {
  TestFlightLog(@"%@", @"applicationDidReceiveMemoryWarning");
  [TestFlight passCheckpoint:@"applicationDidReceiveMemoryWarning"];
}

- (void) applicationWillTerminate:(UIApplication *) application {
  NSLog(@"%@", @"applicationWillTerminate");
  
  if (FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER) {
    [fleksyAppViewController saveText];
  }
  
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) loading {
  return loadingTimer != nil;
}

@synthesize fleksyAppViewController;

@end