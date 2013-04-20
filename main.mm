#import <UIKit/UIKit.h>

#import "Settings.h"

//http://stackoverflow.com/questions/5427396/whats-the-correct-way-to-configure-xcode-4-workspaces-to-build-dependencies-whe
int main(int argc, char* argv[]) {
  
  NSLog(@"starting with %d arguments", argc);
  for (int i = 0; i < argc; i++) {
    NSLog(@"arg%d='%s'", i, argv[i]);
  }
  
  @autoreleasepool {
    NSLog(@"FLEKSY_RUN_SERVER: %d, FLEKSY_RUN_CLIENT: %d", FLEKSY_RUN_SERVER, FLEKSY_RUN_CLIENT);
    NSLog(@"Running as standalone app");
    return UIApplicationMain(argc, argv, nil, @"AppDelegate");
  }
} 