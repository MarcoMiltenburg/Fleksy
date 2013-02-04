#import <UIKit/UIKit.h>
#import "FleksyAppMainViewController.h"
#import "FleksyKeyboard.h"
#import "FleksyTextView.h"
#import "FLUserDictionary.h"

#define LOAD_SERVER YES

@interface AppDelegate : NSObject<UIApplicationDelegate, FleksyKeyboardListener> {
  @private
  UIWindow* window;
  FleksyAppMainViewController* fleksyAppViewController;
  FleksyTextView* textView;
  FleksyKeyboard* customInputView;
  
  NSTimer* loadingTimer;
  
  BOOL lastKnownVoiceOverState;
  
  //@public
  //FleksyServer* server;
}

- (void) setProximityMonitoringEnabled:(BOOL) b;
- (void) speakCurrentText;

@property (readonly) FleksyAppMainViewController* fleksyAppViewController;
//@property (readonly) BOOL loading;


@end