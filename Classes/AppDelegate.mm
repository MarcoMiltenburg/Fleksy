#import "AppDelegate.h"
#import "FLKeyboardContainerView.h"
#import "FLWord.h"

#import "MathFunctions.h"
#import "Settings.h"
#import "FleksyUtilities.h"

#import "FLKeyboard.h"

#import "Accelerate/Accelerate.h"
#import "VariousUtilities.h"

#import "FileManager.h"

#import "HookingUtilities.h"

#import "UIRotorRecognizer.h"
#import <QuartzCore/QuartzCore.h>
#include "Crashlytics/Crashlytics.h"

#include <string>

#define randf() ( rand() / (RAND_MAX + 1.0f) )

#define LAST_VERSION_KEY @"FleksyLastRunVersion"
#define LOADING_TIMER_STEP 4


@class UIKeyboard;

float distributionFunction(float x);


@implementation AppDelegate


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
        NSString* word = [[wordString componentsSeparatedByString:@"_"] objectAtIndex:0];
        //double frequency = [[[wordString componentsSeparatedByString:@"_"] objectAtIndex:1] doubleValue];
        if (FLAddWordResultAdded == [[FLTypingController_iOS sharedFLTypingController_iOS].fleksyClient addedUserWord:word frequency:FLEKSY_USER_WORD_FREQUENCY]) {
          wordsAdded++;
        }
      }
      [VariousUtilities performAudioFeedbackFromString:[NSString stringWithFormat:@"Added %d new words", wordsAdded]];
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

#ifdef RELEASE
  printf("Fleksy RELEASE\n");
  
  [TestFlight setOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                          @NO, TFOptionLogToConsole,
                          @NO, TFOptionLogToSTDERR, nil]];
  
#if APP_STORE
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
    printf("Fleksy CRASHLYTICS\n");
    [Crashlytics startWithAPIKey:@"8437e63c5dcbeca15784fa67dd5fab1275a867a5"];
#endif

#ifdef DEBUG
  printf("Fleksy DEBUG\n");
#endif

#if APP_STORE
  printf("Fleksy APP_STORE\n");
#else
  printf("Fleksy NOT app_store\n");
#endif
  
  
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
  
  
  [[NSUbiquitousKeyValueStore defaultStore] synchronize]; 
  [[NSUserDefaults standardUserDefaults] synchronize];
  
  NSString* version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
  NSString* versionShort = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
  [[NSUserDefaults standardUserDefaults] setObject:[NSString stringWithFormat:@"%@-%@ (4.33/2.33)", versionShort, version] forKey:@"FLEKSY_APP_SETTING_VERSION"];

  NSLog(@"CFBundleShortVersionString: %@", versionShort);
  RANDOM_SEED();
  
  [[UIApplication sharedApplication] setStatusBarHidden:FLEKSY_STATUS_BAR_HIDDEN];
  //[[UIApplication sharedApplication] statusBarOrientation];

  
  //we use bounds here and not application frame, since the view controller inside will adjust accordingly for the status bar
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  window.backgroundColor = FLEKSY_TEXTVIEW_COLOR;
  window.rootViewController = fleksyAppViewController;
  // Show the window
  [window makeKeyAndVisible];
  
  
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
  
  [self performSelectorOnMainThread:@selector(finishLoadingUI) withObject:nil waitUntilDone:NO];
  //[self finishLoadingUI];
  
  NSLog(@"END of applicationDidFinishLaunching, took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
#pragma unused(startTime)
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
  
  //[FleksyKeyboard enableFleksyForWebViews];
  [self startLoadingProgressTimer];
  //[customInputView performSelectorInBackground:@selector(startLoading) withObject:nil];
  
  // Require load on mainThread, i.e. UIKit objects.
  
  [customInputView startLoading];
  //textView.text = @"Loading";
  
  
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

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  exit(0);
}

- (void) applicationDidFinishLaunching:(UIApplication *) application {
  
#if FLEKSY_EXPIRES
  if (![self magicOK]) {
    [[[UIAlertView alloc] initWithTitle:@"Beta expired" message:@"Your beta of Fleksy has expired!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    return;
  }
#endif
  
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
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
  NSLog(@"applicationWillEnterForeground");
  [customInputView performSelector:@selector(handleSettingsChanged:) withObject:nil];
  
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



- (void) accelerometer:(UIAccelerometer *) accelerometer didAccelerate:(UIAcceleration *) acceleration {
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication *) application {
  TestFlightLog(@"%@", @"applicationDidReceiveMemoryWarning");
  [TestFlight passCheckpoint:@"applicationDidReceiveMemoryWarning"];
}

- (void) applicationWillTerminate:(UIApplication *) application {
  NSLog(@"%@", @"applicationWillTerminate");
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) loading {
  return loadingTimer != nil;
}

@synthesize fleksyAppViewController;

@end