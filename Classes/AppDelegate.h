#import <UIKit/UIKit.h>
//#import "FleksyAppMainViewController.h"
#import "FleksyKeyboard.h"
#import "FleksyTextView.h"
#import "FLThemeManager.h"

@class FleksyAppMainViewController;

#define LOAD_SERVER YES

@interface AppDelegate : NSObject<UIApplicationDelegate, FleksyKeyboardListener> {
  @private
  UIWindow* window;
  FleksyAppMainViewController* fleksyAppViewController;
  FleksyTextView* textView;
  FleksyKeyboard* customInputView;
  
  NSTimer* loadingTimer;
  
  BOOL lastKnownVoiceOverState;
  
  FLThemeManager *_themeManager;
}

- (void) setProximityMonitoringEnabled:(BOOL) b;
- (void) speakCurrentText;

@property (readonly) FleksyAppMainViewController* fleksyAppViewController;
@property (strong, nonatomic) FLThemeManager *themeManager;

//@property (readonly) BOOL loading;

@end
