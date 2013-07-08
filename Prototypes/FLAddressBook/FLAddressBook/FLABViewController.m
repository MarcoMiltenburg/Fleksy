//
//  FLABViewController.m
//  FLAddressBook
//
//  Created by Vince Mansel on 6/30/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#import "FLABViewController.h"
#import "FLFavoritesTableViewController.h"

// For testing
#import "FLABAppDelegate.h"

NSMutableArray *favorites;
NSString *FLEKSY_APP_SETTING_SPEED_DIAL_1;

@interface FLABViewController ()
{
  UINavigationController *myNavCon;
}

@end

@implementation FLABViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFavoritesWillUpdate:) name:FleksyFavoritesWillUpdateNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFavoritesDidUpdate:) name:FleksyFavoritesDidUpdateNotification object:nil];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
  
  // Dispose of any resources that can be recreated.

  [[NSNotificationCenter defaultCenter] removeObserver:self];
  myNavCon = nil;
}

- (IBAction)showPicker:(id)sender {
  
  //[FLFavoritesTableViewController checkAddressBookAuthorization];
  FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain withMode:FL_FavoritesTVC_Mode_Settings];
  favTVC.propertyType = FL_PropertyType_PhoneNumber | FL_PropertyType_EmailAddress;
  [self reloadFavorites];
  favTVC.favorites = favorites;
  favTVC.favoritesDelegate = self;
  favTVC.title = @"Favorites Setup";
  
  if (myNavCon) {
    myNavCon = nil;
  }
  myNavCon = [[UINavigationController alloc] init];
  
  [myNavCon addChildViewController:favTVC];
  
  [self presentViewController:myNavCon animated:YES completion:NULL];

  //[self showPersonEmailAndPhone];
}

- (IBAction)menuSelector:(id)sender {
  //[FLFavoritesTableViewController checkAddressBookAuthorization];
  // Authorization Check not required in operational mode
  FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain];
  favTVC.propertyType = FL_PropertyType_PhoneNumber | FL_PropertyType_EmailAddress;
  [self reloadFavorites];
  favTVC.favorites = favorites;
  favTVC.favoritesDelegate = self;
  favTVC.title = @"Favorites";
  
  if (myNavCon) {
    myNavCon = nil;
  }
  myNavCon = [[UINavigationController alloc] init];
  
  [myNavCon addChildViewController:favTVC];
  
  [self presentViewController:myNavCon animated:YES completion:NULL];
}

//- (IBAction)showPickerPhone:(id)sender {
//
//  return;
//  [FLFavoritesTableViewController checkAddressBookAuthorization];
//  FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain];
//  favTVC.propertyType = FL_PropertyType_PhoneNumber;
//  [self reloadFavorites];
//  favTVC.favorites = favorites;
//  favTVC.favoritesDelegate = self;
//  favTVC.title = @"Favorites - Phone";
//
//  
//  if (!myNavCon) {
//    myNavCon = [[UINavigationController alloc] init];
//  }
//  
//  [myNavCon addChildViewController:favTVC];
//  
//  [self presentViewController:myNavCon animated:YES completion:NULL];
//}
//
//
//- (IBAction)showPickerEmail:(id)sender {
//  return;
//  [FLFavoritesTableViewController checkAddressBookAuthorization];
//  FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain];
//  favTVC.propertyType = FL_PropertyType_EmailAddress;
//  [self reloadFavorites];
//  favTVC.favorites = favorites;
//  favTVC.favoritesDelegate = self;
//  favTVC.title = @"Favorites - Email";
//  
//  if (!myNavCon) {
//    myNavCon = [[UINavigationController alloc] init];
//  }
//  
//  [myNavCon addChildViewController:favTVC];
//  
//  [self presentViewController:myNavCon animated:YES completion:NULL];
//}

#pragma mark - FLFavoritesTVCDelegateProtocol Method

- (void)dismissFavoritesTVC {
  [myNavCon dismissViewControllerAnimated:YES completion:NULL];
}

- (void)selectedFavorite:(NSString *)favoriteString {
  NSLog(@" Send text or email to: %@", favoriteString);
  
  self.emailAddress.text = favoriteString;
  self.phoneNumber.text = favoriteString;
  self.firstName.text = favoriteString;
  [self dismissFavoritesTVC];
}

#pragma mark - FLFavoritesTableViewControllerNotification Handlers

- (void)handleFavoritesWillUpdate:(NSNotification *)aNotification {
  NSLog(@" aNotification = %@", aNotification);
}

- (void)handleFavoritesDidUpdate:(NSNotification *)aNotification {
  NSLog(@" aNotification = %@", aNotification);
  
  //Serialize the Favorites Array to a comma seperated string
  
  favorites = [[(NSDictionary *)[aNotification userInfo] objectForKey:FleksyFavoritesKey] mutableCopy];
  
  FLEKSY_APP_SETTING_SPEED_DIAL_1 = [favorites componentsJoinedByString:@","];
  
  [[NSUserDefaults standardUserDefaults] setObject:FLEKSY_APP_SETTING_SPEED_DIAL_1
                                            forKey:TEST_KEY];
  
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  [[NSUserDefaults standardUserDefaults] synchronize];
  
}

/////TODO: EXISTING FLEKSY METHOD

- (void) reloadFavorites {
  [favorites removeAllObjects];
  
  if (!favorites) {
    favorites = [[NSMutableArray alloc] init];
  }
  
  FLEKSY_APP_SETTING_SPEED_DIAL_1 = [[NSUserDefaults standardUserDefaults] objectForKey:TEST_KEY];
  
  if (FLEKSY_APP_SETTING_SPEED_DIAL_1 && FLEKSY_APP_SETTING_SPEED_DIAL_1.length) {
    NSArray* components = [FLEKSY_APP_SETTING_SPEED_DIAL_1 componentsSeparatedByString:@","];
    for (NSString* favorite in components) {
      NSString* trimmed = [favorite stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (trimmed && trimmed.length) {
        [favorites addObject:trimmed];
      }
    }
  }
  //[self recreateActionMenu];
}


@end
