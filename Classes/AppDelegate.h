#import <UIKit/UIKit.h>
#import "FleksyAppMainViewController.h"

@interface AppDelegate : NSObject<UIApplicationDelegate> {
  @private
  UIWindow* window;
  FleksyAppMainViewController* fleksyAppViewController;
}

@property (readonly) FleksyAppMainViewController* fleksyAppViewController;

@end