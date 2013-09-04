//
//  FLPeoplePickerNavigationController.m
//  iFleksy
//
//  Created by Vince Mansel on 9/4/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLPeoplePickerNavigationController.h"
#import "VariousUtilities.h"
#import "Settings.h"

@interface FLPeoplePickerNavigationController ()

@end

@implementation FLPeoplePickerNavigationController

- (BOOL) shouldAutorotate {
  
  BOOL result = YES;
  NSLog(@"1231235 shouldAutorotate, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d, result: %d", FLEKSY_APP_SETTING_LOCK_ORIENTATION, result);
  return result;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
  UIInterfaceOrientationMask result;
  if (deviceIsPad()) {
    result = UIInterfaceOrientationMaskAll;
  } else {
    switch (FLEKSY_APP_SETTING_LOCK_ORIENTATION) {
      case UIInterfaceOrientationLandscapeLeft:
        result = UIInterfaceOrientationMaskLandscapeLeft;
        break;
      case UIInterfaceOrientationLandscapeRight:
        result = UIInterfaceOrientationMaskLandscapeRight;
        break;
      default:
        result = UIInterfaceOrientationMaskAllButUpsideDown;
        break;
    }
  }
  NSLog(@"1231235 supportedInterfaceOrientations, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d, result: %d", FLEKSY_APP_SETTING_LOCK_ORIENTATION, result);
  return result;
}

// for iOS 5.0 compatibility
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return [self shouldAutorotate];
}


@end
