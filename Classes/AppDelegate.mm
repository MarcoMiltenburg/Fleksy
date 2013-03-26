#import "AppDelegate.h"
#import "FleksyPack.h"

#import "Accelerate/Accelerate.h"
#import <QuartzCore/QuartzCore.h>

#include "Crashlytics/Crashlytics.h"

#include <string>

#define randf() ( rand() / (RAND_MAX + 1.0f) )

#define MYAPP_TEXTVIEW_COLOR [UIColor colorWithRed:0.929 green:0.925 blue:0.878 alpha:1]

@class UIKeyboard;

@implementation AppDelegate


float distributionFunction(float x) {
  
  float mean = 0;
  float std = 1;
  
  float power = -powf(x - mean, 2.0f) / (2.0f * std);
  float result = 1.0f / sqrtf(2.0f * M_PI * std) * expf(power);
  return result;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
  NSLog(@"openURL: %@, scheme: %@, sourceApplication: %@, annotation: %@", url, url.scheme, sourceApplication, annotation);
  
    if ([[FleksyPack sharedFleksyPack] handleOpenURL:url]) {
        return YES;
    }
    return NO;
}

- (void) applicationDidFinishLaunching:(UIApplication *) application loadServer:(BOOL) loadServer {
  
  double startTime = CFAbsoluteTimeGetCurrent();
  
#ifdef RELEASE
  printf("Fleksy RELEASE\n");
  [TestFlight takeOff:@"91f69c10-d1a3-4e7a-905d-dea51af78a82"];
#if !APP_STORE
  [TestFlight setDeviceIdentifier:[[UIDevice currentDevice] uniqueIdentifier]];
#endif
#endif

#ifdef CRASHLYTICS
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
  
  fleksyAppViewController = [[FleksyAppMainViewController alloc] initWithNibName:nil bundle:nil];      
  
  //we use bounds here and not application frame, since the view controller inside will adjust accordingly for the status bar
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  window.backgroundColor = MYAPP_TEXTVIEW_COLOR;
  window.rootViewController = fleksyAppViewController;
  // Show the window
  [window makeKeyAndVisible];
    
  [[FleksyPack sharedFleksyPack] setupViewController:fleksyAppViewController inWindow:window];
    
  NSLog(@"END of applicationDidFinishLaunching, took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
}

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
  [[FleksyPack sharedFleksyPack] applicationWillResignActive];    
}

- (void)applicationWillEnterForeground:(UIApplication*)application {
  NSLog(@"applicationWillEnterForeground");
    [[FleksyPack sharedFleksyPack] applicationWillEnterForeground];
}

- (void)applicationDidEnterForeground:(UIApplication*)application {
  NSLog(@"applicationDidEnterForeground");
    [[FleksyPack sharedFleksyPack] applicationDidEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
  NSLog(@"applicationDidBecomeActive");
    [[FleksyPack sharedFleksyPack] applicationDidBecomeActive];
}

- (void) accelerometer:(UIAccelerometer *) accelerometer didAccelerate:(UIAcceleration *) acceleration {
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication *) application {
  //TestFlightLog(@"%@", @"applicationDidReceiveMemoryWarning");
  [TestFlight passCheckpoint:@"applicationDidReceiveMemoryWarning"];
}

- (void) applicationWillTerminate:(UIApplication *) application {
  NSLog(@"%@", @"applicationWillTerminate");
  [[NSUserDefaults standardUserDefaults] synchronize];
}

@synthesize fleksyAppViewController;

@end