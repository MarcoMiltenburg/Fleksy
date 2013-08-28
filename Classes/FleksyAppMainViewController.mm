//
//  MainViewController.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/9/11.
//  Copyright 2011 Syntellia Inc. All rights reserved.
//

#import "FleksyAppMainViewController.h"
#import "Settings.h"
#import "FLKeyboardContainerView.h"
#import "DiagnosticsManager.h"
#import "FleksyUtilities.h"
#import "AppDelegate.h"
#import "VariousUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import "IASKAppSettingsViewController.h"
#import "IASKSettingsReader.h"
#import "FLThemeManager.h"
#import "FLColdWar.h"

//#define APP_STORE_LINK @"http://itunes.apple.com/us/app/fleksy/id520337246?mt=8&uo=4"
#define IOS_DEVICE_REVIEW_LINK @"itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=520337246"

#define IOS_LIMITATIONS_LINK @"http://fleksy.com/iOS-integration"

#define APPLE_EMAIL_SUBJECT @"Integration of Fleksy in iOS"
#define APPLE_EMAIL_TEXT @"Dear Apple,\n\nI understand that due to current limitations on iOS, developers and users cannot change the standard keyboard.\n\nI have been using the new Fleksy keyboard on my iDevice and I wanted to voice my desire to have it as an available keyboard for system-wide usage.\n\nFleksy makes typing easy, fast and forgiving, without requiring the user to learn a new way of typing. I think it would make a great addition to iOS and would make using my device an even more fun, productive and satisfying experience. Here's the <a href=\"http://fleksy.com/?apple\">website</a>.\n\nI hope you will take this into consideration and bring Happy Typing to your devices!\n\nSincerely,\nHappy Fleksy user"

#define APP_STORE_LINK_TWITTER  @""
#define APP_STORE_LINK_SMS      @""

#define BUTTON_TITLE_POST_TO_TWITTER @"Tweet"
#define BUTTON_TITLE_POST_TO_FACEBOOK @"Facebook"
#define BUTTON_TITLE_POST_TO_WEIBO @"Weibo"

#define INITIAL_MENU_TITLE @"Welcome to Fleksy. Happy typing!"

#define ACTION_MENU_TITLE @""
//@"Triple click home to resume typing, or swipe right for more options"

#define UPGRADE_FULL_VERSION_TITLE @"Upgrade to full version"
#define RESTORE_FULL_VERSION_TITLE @"Restore purchased version"

#define INSTRUCTIONS_BUTTON_HEIGHT 42

#define TAG_RESHOW_AFTER_ROTATION 1

#define WALL_STREET_JOURNAL_LINK @"http://projects.wsj.com/soty/rankings?standalone=1"

@protocol FleksyUserQuestionaireListener

- (void)showNormalFlow;

@end

@interface FleksyUserQuestionaire : NSObject

@property (nonatomic, assign) id<FleksyUserQuestionaireListener> questioniareListener;
@end


@implementation FleksyUserQuestionaire

/*
 This seems to now be serving the mobile version:
 http://projects.wsj.com/soty/rankings?standalone=1
 
 Versus the normal one:
 http://projects.wsj.com/soty/rankings
 */

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
#if FLEKSY_POP_WALL_STREET_JOURNAL
  if (buttonIndex == 1) {
    [TestFlight passCheckpoint:@"showWallStreetJournal"];
    printf("Sending user to Wall Street Journal Rankings Site.\n\n");
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:WALL_STREET_JOURNAL_LINK]];
  }
  else {
    [self.questioniareListener showNormalFlow];
  }
#endif
}

@end


@interface FleksyAppMainViewController () <IASKSettingsDelegate, UIPopoverControllerDelegate, FleksyUserQuestionaireListener>
{
  IASKAppSettingsViewController *appSettingsViewController;
  UINavigationController *favoritesNavigationController;
  UINavigationController *signatureNavigationController;
  BOOL isExecutedWithFavorites;
  FleksyUserQuestionaire *handleQuestionaireLink;
  BOOL _userHasVisitedQuestionaireLink;
}

@property (nonatomic, retain) IASKAppSettingsViewController *appSettingsViewController;
@property (nonatomic) UIPopoverController* currentPopoverController;

@end

@implementation FleksyAppMainViewController

@synthesize appSettingsViewController;

#pragma mark - Settings

- (IASKAppSettingsViewController*)appSettingsViewController {
	if (!appSettingsViewController) {
		appSettingsViewController = [[IASKAppSettingsViewController alloc] init];
		appSettingsViewController.delegate = self;
//		BOOL enabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoConnect"];
//		appSettingsViewController.hiddenKeys = enabled ? nil : [NSSet setWithObjects:@"AutoConnectLogin", @"AutoConnectPassword", nil];
	}
	return appSettingsViewController;
}

#pragma mark IASKAppSettingsViewControllerDelegate protocol

- (void)settingsViewController:(IASKAppSettingsViewController*)sender buttonTappedForSpecifier:(IASKSpecifier*)specifier {
  
  NSString *specifierKey = [specifier key];
  NSLog(@" Launching Favorites Setup with specifier key %@ :: %s", specifierKey, __PRETTY_FUNCTION__);
  //FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain withMode:FL_FavoritesTVC_Mode_Settings];
  
  if ([specifierKey isEqualToString:@"FLEKSY_APP_SETTING_SPEED_DIAL_1"]) {
    
    [TestFlight passCheckpoint:@"setupFavorites"];

    [self handleFavoritesForSettingsViewController:sender];
  }
  else if ([specifierKey isEqualToString:@"FLEKSY_APP_SETTING_EMAIL_SIGNATURE"]) {
    
    [TestFlight passCheckpoint:@"editSignature"];

    [self handleSignatureForSettingsViewController:sender];
  }
}

- (void)handleFavoritesForSettingsViewController:(IASKAppSettingsViewController*)sender {
  NSLog(@"Favorites BEFORE = %@", favorites);
  [self reloadFavorites];
  NSLog(@"Favorites AFTER = %@", favorites);
  
  float featureVersion = 6.0;
  if ([[[UIDevice currentDevice] systemVersion] floatValue] < featureVersion)
  {
    NSLog(@"Not Running in IOS-6: Cannot use Address Book Frameworks.");
    return;
  }
  
  favorites = [FLFavoritesTableViewController automaticReplenisherForFavorites:[favorites mutableCopy]];
  [self updateFavoriteStorage:favorites];
  
  FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain withMode:FL_FavoritesTVC_Mode_Settings withFavorites:favorites];
  favTVC.propertyType = (FL_PropertyType)(FL_PropertyType_PhoneNumber | FL_PropertyType_EmailAddress);
  favTVC.favoritesDelegate = self;
  favTVC.title = @"Setup Favorites";
  
  //[FLFavoritesTableViewController automaticReplenisherForFavorites:favorites];
  
  if (favoritesNavigationController) {
    favoritesNavigationController = nil;
  }
  //  else {
  //    // Only replinish after a re-launch, just in case
  //    favorites = [FLFavoritesTableViewController automaticReplenisherForFavorites:favorites];
  //  }
  
  //favTVC.favorites = favorites;
  
  favoritesNavigationController = [[UINavigationController alloc] init];
  
  [favoritesNavigationController addChildViewController:favTVC];
  
  [sender presentViewController:favoritesNavigationController animated:YES completion:NULL];
}

- (void)handleSignatureForSettingsViewController:(IASKAppSettingsViewController*)sender {
  NSLog(@"Signature BEFORE = %@", FLEKSY_APP_SETTING_EMAIL_SIGNATURE);
  
  FLSignatureViewController *sigTVC = [[FLSignatureViewController alloc] initWithSignature:FLEKSY_APP_SETTING_EMAIL_SIGNATURE];
  sigTVC.signatureDelegate = self;
  sigTVC.title = @"Edit Signature";
    
  if (signatureNavigationController) {
    signatureNavigationController = nil;
  }
  
  signatureNavigationController = [[UINavigationController alloc] init];
  [signatureNavigationController addChildViewController:sigTVC];
  
  [sender presentViewController:signatureNavigationController animated:YES completion:NULL];
}

- (void)settingsViewControllerDidEnd:(IASKAppSettingsViewController*)sender {
	
	// your code here to reconfigure the app for changed settings
    
  NSLog(@"%s: sender = %@", __PRETTY_FUNCTION__, sender);
    
  [textView.inputView performSelector:@selector(handleSettingsChanged:) withObject:nil];
  [self dismissModalViewControllerAnimated:YES];
}

//optional

- (CGFloat)settingsViewController:(id<IASKViewController>)settingsViewController
                        tableView:(UITableView *)tableView
        heightForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewController.settingsReader keyForSection:section];
	if ([key isEqualToString:@"FleksyLogo"]) {
		return [UIImage imageNamed:@"IconRounded.png"].size.height + 25;
	}
	return 0;
}

- (UIView *)settingsViewController:(id<IASKViewController>)settingsViewController
                         tableView:(UITableView *)tableView
           viewForHeaderForSection:(NSInteger)section {
    NSString* key = [settingsViewController.settingsReader keyForSection:section];
	if ([key isEqualToString:@"FleksyLogo"]) {
		UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"IconRounded.png"]];
		imageView.contentMode = UIViewContentModeCenter;
		return imageView;
	}
	return nil;
}

#pragma mark - User Voting

- (void)showVoting:(BOOL)goDirect {
  if (!handleQuestionaireLink) {
    handleQuestionaireLink = [[FleksyUserQuestionaire alloc] init];
    handleQuestionaireLink.questioniareListener = self;
  }
  
  if (goDirect) {
    [TestFlight passCheckpoint:@"showWallStreetJournalDirectly"];
    printf("Sending user to Wall Street Journal Rankings Site directly.\n\n");
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:WALL_STREET_JOURNAL_LINK]];
  }
  else {
    [[[UIAlertView alloc] initWithTitle:@"Vote YES for Syntellia" message:@"We need your help. We are featured by the Wall Street Journal Startup of the Year. Click View All and Vote Yes for Syntellia!" delegate:handleQuestionaireLink cancelButtonTitle:@"Later" otherButtonTitles:@"OK", nil] show];
    [FLColdWar yay];
  }
  _userHasVisitedQuestionaireLink = YES;
  FLEKSY_APP_CACHE_WSJ_QUESTIONAIRE = _userHasVisitedQuestionaireLink;
  [[NSUserDefaults standardUserDefaults] setBool:FLEKSY_APP_CACHE_WSJ_QUESTIONAIRE
                                            forKey:@"FLEKSY_APP_CACHE_WSJ_QUESTIONAIRE"];
  
  [[NSUserDefaults standardUserDefaults] synchronize];}

#pragma mark - FleksyUserQuestionaireListener

- (void)showNormalFlow {
  [self showSettings];
}

#pragma mark - Settings Handling


- (void) showSettings {
  
    [TestFlight passCheckpoint:@"showSettings"];

#if FLEKSY_POP_WALL_STREET_JOURNAL
  if (!_userHasVisitedQuestionaireLink) {
    [self showVoting:NO];
  }
  else {
    [self showSettingsModal:nil];
  }
#else
  [self showSettingsModal:nil];
#endif
}

- (void)showSettingsPush:(id)sender {
	[self.appSettingsViewController setShowCreditsFooter:NO];   // Uncomment to not display InAppSettingsKit credits for creators.
	self.appSettingsViewController.showDoneButton = NO;
	[self.navigationController pushViewController:self.appSettingsViewController animated:YES];
}

- (void)showSettingsModal:(id)sender {
  UINavigationController *aNavController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController];
  [self.appSettingsViewController setShowCreditsFooter:NO];   // Uncomment to not display InAppSettingsKit credits for creators.
  self.appSettingsViewController.showDoneButton = YES;  
  [self presentViewController:aNavController animated:YES completion:nil];
}

- (void)showSettingsPopover:(id)sender {
    
    // Popovers cannot be presented from a view which does not have a window.
	if(self.currentPopoverController) {
        [self dismissCurrentPopover];
		return;
	}
    
	self.appSettingsViewController.showDoneButton = NO;
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:self.appSettingsViewController] ;
	UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navController];
	popover.delegate = self;
	[popover presentPopoverFromBarButtonItem:sender permittedArrowDirections:UIPopoverArrowDirectionUp animated:NO];
	self.currentPopoverController = popover;
}

- (void) dismissCurrentPopover {
	[self.currentPopoverController dismissPopoverAnimated:YES];
	self.currentPopoverController = nil;
}

#pragma mark - Twitter Support

////////////////////////////////////////////////////////////////////////////
//http://code.shabz.co/post/36796928905/follow-a-username-on-twitter-ios-5
////////////////////////////////////////////////////////////////////////////

- (void) follow:(NSString *) username {
  
  BOOL twitterSupport = NO;
  if (NSClassFromString(@"SLComposeViewController")) {
      twitterSupport = YES;
  } else if (NSClassFromString(@"TWTweetComposeViewController")) {
    twitterSupport = YES;
  }
  
  if (twitterSupport) {
    // Create account store, followed by a twitter account identifier
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType *type = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    [accountStore requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
      if (granted) {
        NSArray* tempAccountsArray = [accountStore accountsWithAccountType:type];
        
        //don't use a Fleksy twitter account, if present. (for easier internal testing)
        NSMutableArray* accountsArray = [[NSMutableArray alloc] init];
        for (ACAccount* account in tempAccountsArray) {
          if (![[account.username uppercaseString] isEqualToString:@"FLEKSY"]) {
            [accountsArray addObject:account];
          }
        }
        // Sanity check
        if ([accountsArray count] > 0) {
          //Create dictionary to pass to followWithAccountInfo: method
          NSMutableDictionary *dict = [NSMutableDictionary dictionary];
          [dict setObject:username forKey:@"usernameToFollow"];
          //Follow the username with your first logged in account
          ACAccount* account = [accountsArray objectAtIndex:0];
          NSLog(@"using twitter account: %@", account);
          [dict setObject:account forKey:@"account"];
          [self performSelectorOnMainThread:@selector(followWithAccountInfo:) withObject:dict waitUntilDone:NO];
        } else {
          [self performSelectorOnMainThread:@selector(showTwitterSupportError:) withObject:@"No accounts available" waitUntilDone:NO];
        }
      } else {
        [self performSelectorOnMainThread:@selector(showTwitterSupportError:) withObject:@"Could not access twitter account" waitUntilDone:NO];
      }
    }];
  } else {
    NSLog(@"No Twitter support!");
  }
}

- (void) followWithAccountInfo:(NSDictionary *) dictionary {
  ACAccount *acct = [dictionary objectForKey:@"account"];
  NSString *username = [dictionary objectForKey:@"usernameToFollow"];
  // Build a twitter request for following the username specified
  TWRequest *postRequest = [[TWRequest alloc] initWithURL:
                            [NSURL URLWithString:@"http://api.twitter.com/1.1/friendships/create.json"]
                                               parameters:[NSDictionary dictionaryWithObjectsAndKeys:username, @"screen_name", @"true", @"follow", nil] requestMethod:SLRequestMethodPOST];
  // Post the request
  [postRequest setAccount:acct];
  // Block handler to manage the response
  [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error)
   {
     NSLog(@"followWithAccountInfo: %d", urlResponse.statusCode);
     if (urlResponse.statusCode == 200) {
       [self performSelectorOnMainThread:@selector(showFollowConfirmation) withObject:nil waitUntilDone:NO];
     } else {
       [self performSelectorOnMainThread:@selector(showFollowError:) withObject:[NSNumber numberWithInt:urlResponse.statusCode] waitUntilDone:NO];
     }
   }];
}

- (void) showTwitterSupportError:(NSString*) message {
  [[[UIAlertView alloc] initWithTitle:@"Twitter error" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void) showFollowConfirmation {
  [[[UIAlertView alloc] initWithTitle:@"@Fleksy" message:@"Thanks for following us!\nWe promise to keep it interesting :)" delegate:nil cancelButtonTitle:@"Cool!" otherButtonTitles: nil] show];
}

- (void) showFollowError:(NSNumber*) statusCode {
  [[[UIAlertView alloc] initWithTitle:@"Couldn't follow @Fleksy :(" message:[NSString stringWithFormat:@"Whoops! Some error occured, and it's called error #%d", statusCode.intValue] delegate:nil cancelButtonTitle:@"Not cool!" otherButtonTitles: nil] show];
}

////////////////////////////////////////////////////////////////////////////
/////////////////////  END OF TWITTER FOLLOW  //////////////////////////////
////////////////////////////////////////////////////////////////////////////


#pragma mark - Keyboard Support Methods

- (void) hideKeyboard {
  
  //we now (DIRECT_TOUCH) avoid resigning the keyboard, otherwise we always need 1 initial tap to "activate" it...
  //problem still exists at the very beginning of app launch
  
  //MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
  
  //return;
  
  NSLog(@"hideKeyboard");
  [textView resignFirstResponder];
}

- (void) showKeyboard {
  
  NSLog(@"controller showKeyboard, textView was responder: %d", textView.isFirstResponder);
  //return;
  
  if (!textView.isFirstResponder) {
    [textView becomeFirstResponder];
  } else {
    [textView reloadInputViews];
  }
  
}

#pragma mark - Email and Messaging Support

- (NSString*) getMessageFooter {
  if (FLEKSY_APP_SETTING_SMS_REPLY_TO && FLEKSY_APP_SETTING_SMS_REPLY_TO.length) {
    return [NSString stringWithFormat:@"%@reply://%@", APP_STORE_LINK_SMS, FLEKSY_APP_SETTING_SMS_REPLY_TO];
  } else {
    return APP_STORE_LINK_SMS;
  }
}

- (NSString*) fleksyAppLink {
  return [NSString stringWithFormat:@"<a href=\"%@\">Fleksy</a>", @"http://fleksy.com/app"];
}

- (NSString*) makeFleksyLinksForText:(NSString*) text evenLowercase:(BOOL) evenLowercase {
  NSString* result = text;
  if (evenLowercase) {
    result = [result stringByReplacingOccurrencesOfString:@"fleksy" withString:@"Fleksy"];
  }
  result = [result stringByReplacingOccurrencesOfString:@"Fleksy" withString:[self fleksyAppLink]];
  return result;
}

- (NSString*) emailSignature {
  NSString* result = FLEKSY_APP_SETTING_EMAIL_SIGNATURE;
  if (!result) {
    result = @"";
  }
 return [self makeFleksyLinksForText:result evenLowercase:YES];
}

- (NSString*) getEmailFooter {
  NSMutableString* result = [[NSMutableString alloc] init];
  [result appendString:[self emailSignature]];
  if (FLEKSY_APP_SETTING_EMAIL_REPLY_TO && FLEKSY_APP_SETTING_EMAIL_REPLY_TO.length) {
    [result appendFormat:@"</br>reply://%@", FLEKSY_APP_SETTING_EMAIL_REPLY_TO];
  }
  return result;
}

#pragma mark - Local Utility Methods

- (void) resetState {
  textView.text = @"";
  [[FLTypingController_iOS sharedFLTypingController_iOS] sendPrepareNextCandidates];
  [[FLKeyboardContainerView sharedFLKeyboardContainerView] reset];
}

- (void) copyText {
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:@"ACTION_COPY"];
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setString:textView.text];
}

#pragma mark - Public Utility Methods

- (NSString *) saveText {
  
  NSLog(@" Saving Text = %@", textView.text);
  [[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER_KEY"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  // Do not save to iCloud
  
  return textView.text;
}

- (void) unSaveText {
  
  [[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER_KEY"];
  [[NSUserDefaults standardUserDefaults] synchronize];
  // Do not save to iCloud
}

#pragma mark - Menus

- (void) dismissInitialMainMenu {
  [initialMainMenu dismissWithClickedButtonIndex:100 animated:!deviceIsPad()];
  [self showKeyboard];
}

- (void) _showInitialMainMenu {
  //[self hideKeyboard];
  initialMainMenu.title = INITIAL_MENU_TITLE;
  
  if (deviceIsPad()) {
    CGRect rect = [self.view convertRect:actionButton.imageView.frame fromView:actionButton];
    [initialMainMenu showFromRect:rect inView:textView.inputView.window animated:YES];
  } else {
    [initialMainMenu showInView:self.view];
  }
  
  lastShowedInitMenu = CFAbsoluteTimeGetCurrent();
  //[textView reloadInputViews];
}

- (void) showInitialMainMenu {
  [self performSelectorOnMainThread:@selector(_showInitialMainMenu) withObject:nil waitUntilDone:NO];
}

- (void) _showActionMainMenu {
  //[self hideKeyboard];
  if (UIAccessibilityIsVoiceOverRunning()) {
    actionMainMenu.title = [NSString stringWithFormat:@"%@", textView.text];
  }
  else {
    actionMainMenu.title =[NSString string];
  }
  
  if (deviceIsPad()) {
    // on the iPad, if title.length > X we get menuception bug. Recreate to solve
    // TODO: create FLActionSheet class?
    [self recreateActionMenu];
    CGRect rect = [self.view convertRect:actionButton.imageView.frame fromView:actionButton];
    [actionMainMenu showFromRect:rect inView:textView.inputView.window animated:YES];
  } else {
    [actionMainMenu showInView:self.view];
  }
  
  lastShowedActionMenu = CFAbsoluteTimeGetCurrent();
}

- (void) showActionMainMenu {
  
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].suggestionsView cancelAllSpellingRequests];
  [VariousUtilities stopSpeaking];
  
  //[self _showActionMainMenu];
  [self performSelectorOnMainThread:@selector(_showActionMainMenu) withObject:nil waitUntilDone:NO];
}

- (void) showLastShownMenu {
  NSLog(@"showLastShownMenu");
  if (lastShowedInitMenu > lastShowedActionMenu) {
    [self showInitialMainMenu];
  } else {
    [self showActionMainMenu];
  }
}

- (void) dismissActionMainMenu {
  [actionMainMenu dismissWithClickedButtonIndex:100 animated:!deviceIsPad()];
  //[self showKeyboard];
}

+ (NSString*) friendlyServiceNameForServiceType:(NSString*) serviceType {
  // serviceType string will be nil if the Social framework is not found and will be used to indicate Twitter
  if (!serviceType || [serviceType isEqualToString:SLServiceTypeTwitter]) {
    return @"Twitter";
  }
  if ([serviceType isEqualToString:SLServiceTypeFacebook]) {
    return @"Facebook";
  }
  if ([serviceType isEqualToString:SLServiceTypeSinaWeibo]) {
    return @"Weibo";
  }
  return @"UnknownService";
}

- (void) postToSocialService:(NSString*) serviceType text:(NSString*) text {

  [TestFlight passCheckpoint:[NSString stringWithFormat:@"ACTION_%@", serviceType]];
  //[[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:];

  //NSLog(@"postToSocialService: %@", serviceType);
  
  if (!purchaseManager.fullVersion) {
    NSLog(@"%@ unavailable in trial version", serviceType);
    return;
  }
  
  // serviceType string will be nil if the Social framework is not found and will be used to indicate Twitter
  if (!serviceType || [serviceType isEqualToString:SLServiceTypeTwitter] || [serviceType isEqualToString:SLServiceTypeSinaWeibo]) {
    if (text.length > 140) {
      UIAlertView* tmp = [[UIAlertView alloc] initWithTitle:@"Text is too long" message:
                          [NSString stringWithFormat:@"Your text is %d characters longer than the 140 character limit for %@",
                           text.length - 140, [FleksyAppMainViewController friendlyServiceNameForServiceType:serviceType]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
      [tmp show];
      return;
    }
  }
  
  UIViewController* viewController;
  
  SLComposeViewControllerCompletionHandler completionHandler = ^(SLComposeViewControllerResult result) {
    if (result == SLComposeViewControllerResultDone) {
      [self resetState];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
    [textView makeReady];
  };

  
  if (NSClassFromString(@"SLComposeViewController")) {
    if ([SLComposeViewController isAvailableForServiceType:serviceType]) {
      viewController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
    }
  } else if (NSClassFromString(@"TWTweetComposeViewController")) {
    //if ([TWTweetComposeViewController canSendTweet]) {
    viewController = [[TWTweetComposeViewController alloc] init];
  } else {
    NSLog(@"No framework found to post to Twitter");
  }
  
  if (viewController) {
    [viewController performSelector:@selector(setInitialText:) withObject:text];
    [viewController performSelector:@selector(setCompletionHandler:) withObject:completionHandler];
    [self presentViewController:viewController animated:YES completion:nil];
  } else {
    [[[UIAlertView alloc] initWithTitle:@"Connection error" message:@"Please ensure an account is set up" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
  }
}

- (void) voiceOverStatusChangedWithDelay:(float) delay {
  [self performSelector:@selector(voiceOverStatusChanged:) withObject:nil afterDelay:delay];
}

- (BOOL) doSMSbugWorkaround {
  BOOL result = [[[UIDevice currentDevice] systemVersion] floatValue] < 6;
  NSLog(@"doSMSbugWorkaround: %d", result);
  return result;
}

-(void) sendInAppSMS:(NSString*) recipient text:(NSString*) text {
  
  [TestFlight passCheckpoint:@"sendInAppSMS"];
  
  //[[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:@"ACTION_SMS"];
  
  //Note: no sim card installed popup is visually "under" our menu (bug)
  
  if (![MFMessageComposeViewController canSendText]) {
    NSLog(@"![MFMessageComposeViewController canSendText]");
    //[self voiceOverSpeak:@"Could not send message"];
    //[self voiceOverStatusChangedWithDelay:2];
    return;
  }
  
  if (!purchaseManager.fullVersion) {
    NSLog(@"Cannot send SMS in trial version");
    return;
  }
  
  //if we dont do this there is a bug (<6.0?), where the status bar WILL be displayed, and overlap with the top navigation bar of the controller
  //this only happens with MFMessageComposeViewController and not MFMailComposeViewController for some reason.
  //after dismissal we want to hide the status bar again
  //http://stackoverflow.com/questions/9927337/mfmessagecomposeviewcontroller-not-properly-displayed
  if ([self doSMSbugWorkaround]) {
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
  }
  
  MFMessageComposeViewController* smsController = [[MFMessageComposeViewController alloc] init];
  //smsController.modalPresentationStyle = UIModalPresentationFormSheet; //UIModalPresentationPageSheet;
  NSLog(@"smsController.modalPresentationStyle: %d", smsController.modalPresentationStyle);
  smsController.messageComposeDelegate = self;
  smsController.body = [NSString stringWithFormat:@"%@\n%@", text, [self getMessageFooter]];
  smsController.recipients = [NSArray arrayWithObjects:recipient, nil];
  
  if (isExecutedWithFavorites) {
    [favoritesNavigationController presentViewController:smsController animated:YES completion:nil];
    isExecutedWithFavorites = NO;
  }
  else {
    [self presentViewController:smsController animated:YES completion:nil];
  }
  //[self presentModalViewController:smsController animated:NO];
}

- (void) messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
  
  NSLog(@"messageComposeViewController didFinishWithResult: %d", result);
  
  if (result == MessageComposeResultSent) {
    //[self voiceOverSpeak:@"Message sent"];
    [self resetState];
  }
  
  [self dismissViewControllerAnimated:YES completion:^{[self showKeyboard];}];
  //[self dismissModalViewControllerAnimated:NO];

  //see bug above. http://stackoverflow.com/questions/9927337/mfmessagecomposeviewcontroller-not-properly-displayed
  if ([self doSMSbugWorkaround]) {
    [[UIApplication sharedApplication] setStatusBarHidden:FLEKSY_STATUS_BAR_HIDDEN withAnimation:UIStatusBarAnimationNone];
    self.view.frame = [[UIScreen mainScreen] applicationFrame];
  }
}


- (void) sendInAppMailTo:(NSArray*) recipients cc:(NSArray*) cc text:(NSString*) text subject:(NSString*) subject signature:(BOOL) signature {
  
  [TestFlight passCheckpoint:@"sendInAppMail"];
  //[[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:@"ACTION_MAIL"];
  
	if (![MFMailComposeViewController canSendMail]) {
    [VariousUtilities performAudioFeedbackFromString:@"Could not send mail"];
    //[self voiceOverStatusChangedWithDelay:2];
    return;
  }
  
  if (!purchaseManager.fullVersion) {
    NSLog(@"Cannot send mail in trial version");
    return;
  }
  
  MFMailComposeViewController* mailController = [[MFMailComposeViewController alloc] init];
  //mailController.modalPresentationStyle = UIModalPresentationFormSheet;
  //mailController.wantsFullScreenLayout = YES;
  NSLog(@"mailController.modalPresentationStyle: %d", mailController.modalPresentationStyle);
  mailController.mailComposeDelegate = self;
  [mailController setSubject:subject];
  [mailController setToRecipients:recipients];
  [mailController setCcRecipients:cc];
  
  BOOL html = YES;
  if (html) {
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"</br>"];
  }
  
  if (signature) {
    text = [NSString stringWithFormat:@"%@</br></br>%@", text, [self getEmailFooter]];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"</br>"];
  }
  
  [mailController setMessageBody:text isHTML:html];
  
  if (isExecutedWithFavorites) {
    [favoritesNavigationController presentViewController:mailController animated:YES completion:nil];
    isExecutedWithFavorites = NO;
  }
  else {
    [self presentViewController:mailController animated:YES completion:nil];
  }
}

- (void) sendInAppMailTo:(NSString*) recipient useText:(NSString*) useText subjectPrefix:(NSString*) subjectPrefix {
  NSString* subject = [self subjectFromText:useText];
  NSString* text = useText;
  if (!FLEKSY_APP_SETTING_EMAIL_INCLUDE_FIRST_LINE) {
    // we dont want to just replace the subject, might have "..." or other characters appended to it
    NSString* commonPrefix = [text commonPrefixWithString:subject options:NSLiteralSearch];
    NSLog(@"commonPrefix: %@", commonPrefix);
    text = [text stringByReplacingOccurrencesOfString:commonPrefix withString:@""];
  }
  [self sendInAppMailTo:recipient text:text subject:[NSString stringWithFormat:@"%@%@", subjectPrefix, subject] signature:YES];
}

- (void) sendInAppMailTo:(NSString*) recipient text:(NSString*) text subject:(NSString*) subject signature:(BOOL) signature {
  [self sendInAppMailTo:[NSArray arrayWithObjects:recipient, nil] cc:nil text:text subject:subject signature:signature];
}

- (void) sendInAppMailTo:(NSString*) recipient useText:(NSString*) useText {
  [self sendInAppMailTo:recipient useText:useText subjectPrefix:@""];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
  
  if (result == MFMailComposeResultSent || result == MFMailComposeResultSaved) {
    [self resetState];
  }
  
  //has to be animated: http://stackoverflow.com/questions/7821617/dismissmodalviewcontrolleranimated-and-dismissviewcontrolleranimated-crashing
  [self dismissViewControllerAnimated:YES completion:^{[self showKeyboard];}];
}


- (void) menu_fleksy_twitter {
  [self follow:@"fleksy"];
  //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/fleksy"]];
}

- (void) menu_fleksy_web {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://fleksy.com"]];  
}

#pragma mark - FLFavoritesTVCDelegateProtocol Method

- (void)dismissFavoritesTVC {
  NSLog(@"dismissFavoritesTVC");
  isExecutedWithFavorites = NO;
  [favoritesNavigationController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)selectedFavorite:(NSString *)favoriteString {
  NSLog(@" Send text or email to: %@", favoriteString);
  
  [self sendTo:favoriteString];
  
  //[self dismissFavoritesTVC];
  //favoritesNavigationController = nil;
}

#pragma mark - FLFavoritesTableViewController Notification Handlers

- (void)handleFavoritesWillUpdate:(NSNotification *)aNotification {
  NSLog(@" aNotification = %@", aNotification);
}

- (void)handleFavoritesDidUpdate:(NSNotification *)aNotification {
  NSLog(@" aNotification = %@", aNotification);
  
  favorites = [[(NSDictionary *)[aNotification userInfo] objectForKey:FleksyFavoritesKey] mutableCopy];
  
  [self updateFavoriteStorage:favorites];
}

- (void)updateFavoriteStorage:(NSMutableArray *)myFavorites {
  
  //Serialize the Favorites Array to a comma seperated string

  NSString *localSpeedDialCache = [myFavorites componentsJoinedByString:@","];
  
  // TODO: handleSettingsChange keeps same list in place because it is out of sync until final Done of Settings.
  // So favorites and FLEKSY_APP_SETTING_SPEED_DIAL_1 both are changed in other classes and methods, so keep local cache
  //  to reflect changes while user is still in the Settings.
  
  [[NSUserDefaults standardUserDefaults] setObject:localSpeedDialCache
                                            forKey:@"FLEKSY_APP_SETTING_SPEED_DIAL_1"];
  
  FLEKSY_APP_SETTING_SPEED_DIAL_1 = localSpeedDialCache;
  
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - FLSignatureVCDelegateProtocol Method

- (void)dismissSignatureVC {
  NSLog(@"dismissSignatureVC");
  [signatureNavigationController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - FLSignatureViewController Notification Handlers

- (void)handleSignatureWillUpdate:(NSNotification *)aNotification {
  NSLog(@" aNotification = %@", aNotification);
}

- (void)handleSignatureDidUpdate:(NSNotification *)aNotification {
  NSLog(@" aNotification = %@", aNotification);
  
  NSString *signature = [[(NSDictionary *)[aNotification userInfo] objectForKey:FleksySignatureKey] mutableCopy];
  
  [self updateSignatureStorage:signature];
}

- (void)updateSignatureStorage:(NSString *)mySignature {
  
  // TODO: handleSettingsChange keeps same list in place because it is out of sync until final Done of Settings.
  // So favorites and FLEKSY_APP_SETTING_SPEED_DIAL_1 both are changed in other classes and methods, so keep local cache
  //  to reflect changes while user is still in the Settings.
  
  [[NSUserDefaults standardUserDefaults] setObject:mySignature
                                            forKey:@"FLEKSY_APP_SETTING_EMAIL_SIGNATURE"];
  
  FLEKSY_APP_SETTING_EMAIL_SIGNATURE = mySignature;
  
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - FLTheme Notification Handlers

- (void)handleThemeDidChange:(NSNotification *)aNote {
  NSLog(@"%s = %@", __PRETTY_FUNCTION__, aNote);
  actionButton.imageView.backgroundColor = FLEKSYTHEME.actionButton_imageView_backgroundColor;
  [self.view setNeedsLayout];
}

#pragma mark kIASKAppSettingChanged Notification Handler

- (void)handle_kIASKAppSettingChanged:aNote {
  NSLog(@"handle_kIASKAppSettingChanged = %@", aNote);
  
  NSDictionary *userInfo = [aNote userInfo];
  
  if ([[[userInfo allKeys] lastObject] isEqualToString:@"FLEKSY_APP_SETTING_THEME"]) {
    FLThemeType themeType = (FLThemeType)[[userInfo objectForKey:@"FLEKSY_APP_SETTING_THEME"] intValue];
    
    NSLog(@" themeType = %d", themeType);
    
    [[NSUserDefaults standardUserDefaults] setObject:@(themeType) forKey:@"FLEKSY_APP_SETTING_THEME"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSUbiquitousKeyValueStore defaultStore] synchronize];
    
    
    [self dismissModalViewControllerAnimated:YES];
  }
}


#pragma mark - Menu Instructions

- (void) showDetailedInstructions:(BOOL) fromAlert {
  
  [TestFlight passCheckpoint:[NSString stringWithFormat:@"showDetailedInstructions.%@", UIAccessibilityIsVoiceOverRunning() ? @"VO" : @"non-VO"]];

  // create the close button
  int padding = 3;
  int width = 70;
  
  UIButton* closeButton = [[UIButton alloc] initWithFrame:CGRectMake(padding, padding, width, INSTRUCTIONS_BUTTON_HEIGHT - 2 * padding)];
  [closeButton setTitle:@"Back" forState:UIControlStateNormal];
  [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  closeButton.showsTouchWhenHighlighted = YES;
  closeButton.backgroundColor = [UIColor darkGrayColor];
  [closeButton addTarget:self action:@selector(dismissInstructions) forControlEvents:UIControlEventTouchUpInside];
  
  UIButton* topButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.bounds.size.width - width - padding, padding, width, INSTRUCTIONS_BUTTON_HEIGHT - 2 * padding)];
  [topButton setTitle:@"Top" forState:UIControlStateNormal];
  [topButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  topButton.showsTouchWhenHighlighted = YES;
  topButton.backgroundColor = [UIColor darkGrayColor];
  [topButton addTarget:self action:@selector(topInstructions) forControlEvents:UIControlEventTouchDown];
  
  
  UIButton* titleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, INSTRUCTIONS_BUTTON_HEIGHT)];
  [titleButton setTitle:@"Instructions" forState:UIControlStateNormal];
  [titleButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
  titleButton.showsTouchWhenHighlighted = YES;
  titleButton.backgroundColor = [UIColor blackColor];
  [titleButton addTarget:self action:@selector(topInstructions) forControlEvents:UIControlEventTouchDown];
  
  UITapGestureRecognizer* tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(askClearDefaults)];
  tapRecognizer.numberOfTapsRequired = 5;
  [titleButton addGestureRecognizer:tapRecognizer];
  
  // create the webview
  instructionsWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, INSTRUCTIONS_BUTTON_HEIGHT, self.view.bounds.size.width, self.view.bounds.size.height - INSTRUCTIONS_BUTTON_HEIGHT)];
  instructionsWebView.delegate = self;
  
  // create the view controller that will present the webview
  instructionsController = [[UIViewController alloc] initWithNibName:nil bundle:nil];
  // add the elements to display
  [instructionsController.view addSubview:instructionsWebView];
  [instructionsController.view addSubview:titleButton];
  [instructionsController.view addSubview:closeButton];
  [instructionsController.view addSubview:topButton];
  
  // mark so that if from alert, on dismissal we will show the basic popup again
  instructionsController.view.tag = fromAlert ? 10 : 20;
  
  //create and load the web request, that will eventually trigger webViewDidFinishLoad
  NSString* filename = UIAccessibilityIsVoiceOverRunning() ? @"index-voiceover" : @"index-sighted";
  NSURL* url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"html" subdirectory:@"instructions"];
  assert(url);
  
//  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
//    if ([[UIDevice currentDevice].model isEqualToString:@"iPod Touch"]) {
//      url = [NSURL URLWithString:@"http://www.apple.com/feedback/ipodtouch.html"];
//    } else {
//      url = [NSURL URLWithString:@"http://www.apple.com/feedback/iphone.html"];
//    }
//  } else {
//    url = [NSURL URLWithString:@"http://www.apple.com/feedback/ipad.html"];
//  }
  
  NSURLRequest* requestObj = [NSURLRequest requestWithURL:url];
  [instructionsWebView loadRequest:requestObj];
}

- (NSString*) defaultsDescription {
  return [NSString stringWithFormat:@"Defaults:\n%@", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation]];
}


- (NSString*) iCloudDescription {
  return [NSString stringWithFormat:@"iCloud:\n%@", [[NSUbiquitousKeyValueStore defaultStore] dictionaryRepresentation]];
}


- (void) clearDefaultsAndCloud {
  
  NSLog(@"BEGIN clearDefaultsAndCloud");
  
  NSLog(@"defaults: %@", [self defaultsDescription]);
  NSLog(@"iCloud: %@", [self iCloudDescription]);
  
  NSArray* defaultKeys = [[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys];
  for (NSString* key in defaultKeys) {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
  }
  NSArray* iCloudKeys = [[[NSUbiquitousKeyValueStore defaultStore] dictionaryRepresentation] allKeys];
  for (NSString* key in iCloudKeys) {
    [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:key];
  }

  NSLog(@"END clearDefaultsAndCloud. Defaults:\n%@\niCloud:\n%@\n", [[NSUserDefaults standardUserDefaults] dictionaryRepresentation], [[NSUbiquitousKeyValueStore defaultStore] dictionaryRepresentation]);
  [[NSUserDefaults standardUserDefaults] synchronize];
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
  
  purchaseManager.fullVersion = NO;
  // this will actually switch to whatever state purchase.fullVersion is
  [self switchToFullVersion];
  
  [purchaseManager resetRuns];
    
    // Clear the inApp setting view so it will agree with defaults
    self.appSettingsViewController = nil;
}

- (void) askClearDefaults {
  askClearDefaultsAlert = [[UIAlertView alloc] initWithTitle:@"This will clear all settings, including iCloud data and dictionary. Are you sure?" message:[self iCloudDescription]
                                                    delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"DELETE", nil];
  [askClearDefaultsAlert show];
}

- (void) notifyVoiceOverLayoutChanged {
  NSLog(@"notifyVoiceOverLayoutChanged");
  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  //UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  NSLog(@"shouldStartLoadWithRequest %@, navigationType: %d", request, navigationType);
  
  if (navigationType == UIWebViewNavigationTypeLinkClicked) {
    [self performSelector:@selector(notifyVoiceOverLayoutChanged) withObject:nil afterDelay:0.3];
  }
  
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  NSLog(@"webViewDidStartLoad %@", webView);
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  NSLog(@"didFailLoadWithError %@", error);
}

- (void) webViewDidFinishLoad:(UIWebView *)webView {
  NSLog(@"webViewDidFinishLoad %@", webView);
  if (!instructionsController.presentingViewController) {
    [self presentViewController:instructionsController animated:YES completion:nil];
  } else {
    NSLog(@"instructionsController already presented");
  }
}

/*
- (void) alterFeedbackForm {
  
  //document.getElementsByName(\"machine_config\")[0].parentElement.parentElement.removeChild(document.getElementsByName(\"machine_config\")[0].parentElement);\
  
  NSString* _js = @"\
  document.getElementById(\"subject\").value='test subject';\
  document.getElementById(\"feedback_comment\").rows=20;\
  document.getElementById(\"feedback_comment\").parentElement.style.cssText+='margin-bottom: 0px';\
  document.getElementById(\"feedback_comment\").style.cssText+='height: 99%% !important; width: 95%% !important; font-size: 12pt';\
  document.getElementById(\"feedback_comment\").value=\"%@\";\
  document.getElementById(\"anonymous_element_1\").selectedIndex=1;\
  document.getElementById(\"customer_name\").value='Happy Fleksy user';\
  document.getElementById(\"customer_email\").value='%@';\
  document.getElementsByName(\"os_version\")[0].parentElement.parentElement.removeChild(document.getElementsByName(\"os_version\")[0].parentElement);\
  document.getElementsByName(\"submit\")[0].style.float=\"none\";\
  document.getElementsByClassName(\"inputs\")[0].style.cssText+='margin-bottom: 5px; padding-bottom: 0px;';\
  document.getElementsByClassName(\"formwrap\")[0].setAttribute('class', '');\
  document.getElementsByClassName(\"formwrap\")[0].setAttribute('class', '');\
  document.getElementsByClassName(\"formwrap\")[0].setAttribute('class', '');\
  document.getElementsByClassName(\"formwrap\")[0].setAttribute('class', '');\
  document.getElementsByClassName(\"dropdown\")[0].setAttribute('class', '');";

  NSString* feedback_comment = [NSString stringWithFormat:APPLE_EMAIL_TEXT, APPLE_EMAIL_FLEKSY_LINK_NON_HTML];
  feedback_comment = [feedback_comment stringByReplacingOccurrencesOfString:@"\n" withString:@"\" + \"\\n\" + \""];
  feedback_comment = [feedback_comment stringByReplacingOccurrencesOfString:@"iDevice" withString:[UIDevice currentDevice].model];
  
  NSString* js = [NSString stringWithFormat:_js, feedback_comment, FLEKSY_APP_SETTING_EMAIL_REPLY_TO ? FLEKSY_APP_SETTING_EMAIL_REPLY_TO : @"integrate@fleksy.com"];
  
  NSString* output = [instructionsWebView stringByEvaluatingJavaScriptFromString:js];
  NSLog(@"run %@\ngot %@", js, output);
  
  //keyboardDisplayRequiresUserAction
  //scalesPageToFit

  //instructionsWebView.scrollView.maximumZoomScale = 0.2;
  //instructionsWebView.scrollView.minimumZoomScale = 1.5;
  
  //instructionsWebView.scrollView.zoomScale = 10;
  //[instructionsWebView.scrollView zoomToRect:CGRectMake(20, 120, 140, 240) animated:YES];

  if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
    instructionsWebView.scrollView.transform = CGAffineTransformMakeScale(0.7, 0.7);
    [instructionsWebView.scrollView setContentOffset:CGPointMake(80, 230) animated:YES];
  }
  
  NSLog(@"contentSize: %@", NSStringFromCGSize(instructionsWebView.scrollView.contentSize));
  NSLog(@"contentOffset: %@", NSStringFromCGPoint(instructionsWebView.scrollView.contentOffset));
  
  NSLog(@"scalesPageToFit: %d", instructionsWebView.scalesPageToFit);
  NSLog(@"keyboardDisplayRequiresUserAction: %d", instructionsWebView.keyboardDisplayRequiresUserAction);
  
  //instructionsWebView.scrollView.scrollEnabled = NO;
}*/

- (void) dismissInstructions {
  BOOL showBasicAlert = instructionsController.view.tag == 10;
  [self dismissViewControllerAnimated:YES completion:^{
    if (showBasicAlert) {
      [self showBasicInstructions];
    }
  }];
  instructionsController = nil;
}


- (BOOL) shouldSpeakText {
  return !instructionsController;
}


- (void) topInstructions {
  [instructionsWebView.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
}


- (NSString*) subjectFromText:(NSString*) text {
  int maxChars = 50;
  NSMutableString* result = [[NSMutableString alloc] init];
  NSRange range = [text rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n.?!"]];
  if (range.length > 0 && range.location <= maxChars) {
    [result appendString:[text substringToIndex:range.location+1]];
  } else {
    NSArray* components = [text componentsSeparatedByString:@" "];
    for (NSString* component in components) {
      if (result.length + component.length + 1 > maxChars) {
        [result appendString:@"..."];
        break;
      }
      [result appendString:component];
      [result appendString:@" "];
    }
  }
  return result;
}

///////////////////////////////////////////////////


- (void) switchToFullVersion {
  [self recreatePlainMenus];
  [self reloadFavorites];
}


// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  //NSLog(@"clicked button index: %d", buttonIndex);
  
  if (alertView == self->basicInstructions) {
    if (buttonIndex == 1) {
      [self showDetailedInstructions:YES];
    }
  } else if (alertView == self->askClearDefaultsAlert) {
    if (buttonIndex == 1) {
      [self clearDefaultsAndCloud];
    }
  } else if (alertView == self->fleksyInOtherApps) {
    if (buttonIndex == 1) {
      [self writeAppStoreReview];
    } else if (buttonIndex == 2) {
      //[self sendEmailToApple];
      [self readMoreAboutLimitations];
    } else {
      NSLog(@"button %u", buttonIndex);
    }
  }
}

// Called when we cancel a view (eg. the user clicks the Home button). This is not called when the user clicks the cancel button.
// If not defined in the delegate, we simulate a click in the cancel button
- (void)alertViewCancel:(UIAlertView *)alertView {
  
  if (alertView == self->basicInstructions) {
    return;
  }
  
  NSLog(@"alertViewCancel");
}

//- (void)willPresentAlertView:(UIAlertView *)alertView;  // before animation and showing view
//- (void)didPresentAlertView:(UIAlertView *)alertView;  // after animation
//- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex; // before animation and hiding view
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {  // after animation
  if (alertView == self->basicInstructions) {
    self->basicInstructions = nil;
    [self voiceOverStatusChanged:nil];
  }
}

- (void) readMoreAboutLimitations {
  
  [TestFlight passCheckpoint:@"readMoreAboutLimitations"];
  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:IOS_LIMITATIONS_LINK]];
}

- (void) sendEmailToApple {
  NSArray* recipients;
  if (UIAccessibilityIsVoiceOverRunning()) {
    recipients = [NSArray arrayWithObjects:@"accessibility@apple.com", @"tcook@apple.com", nil];
  } else {
    recipients = [NSArray arrayWithObjects:@"tcook@apple.com", @"accessibility@apple.com", nil];
  }
  NSArray* cc = [NSArray arrayWithObject:@"integrate@fleksy.com"];
  
  NSString* text = [self makeFleksyLinksForText:APPLE_EMAIL_TEXT evenLowercase:NO];
  text = [text stringByReplacingOccurrencesOfString:@"iDevice" withString:[UIDevice currentDevice].model];
  
  [self sendInAppMailTo:recipients cc:cc text:text subject:APPLE_EMAIL_SUBJECT signature:NO];
}

- (void) writeAppStoreReview {
  
  [TestFlight passCheckpoint:@"writeAppStoreReview"];
  
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:IOS_DEVICE_REVIEW_LINK]];
}

- (void) sendTo:(NSString*) recipient {
  if ([recipient rangeOfString:@"@"].location != NSNotFound) {
    [self sendInAppMailTo:recipient useText:textView.text];
  } else {
    [self sendInAppSMS:recipient text:textView.text];
  }
}

- (void) showFleksyInOtherApps {
  
  [TestFlight passCheckpoint:@"showFleksyInOtherApps"];
  
  fleksyInOtherApps = [[UIAlertView alloc] initWithTitle:@"Revolutionary keyboard!"
                                                 message:@"Unfortunately, due to iOS limitations, it's not possible to replace the standard keyboard.\n\nHere's how you can support us:" delegate:self cancelButtonTitle:@"Later, I promise!"
                                       otherButtonTitles:@"App Store review", @"Read more...", nil];
  [fleksyInOtherApps show];
}

- (void) sendFeedback {
  [TestFlight submitFeedback:textView.text];
  
  if (purchaseManager.fullVersion) {
    
    BOOL voiceover = UIAccessibilityIsVoiceOverRunning();
    
    NSMutableString *subjectPrefixString = [@"Feedback" mutableCopy];
    
    if (voiceover) {
      [subjectPrefixString appendString:@": "];
    }
    else {
      [subjectPrefixString appendString:@":: "];
    }
    
    [self sendInAppMailTo:@"feedback@fleksy.com" useText:textView.text subjectPrefix:subjectPrefixString];
  } else {
    [VariousUtilities performAudioFeedbackFromString:@"Thank you. Your feedback has been submitted"];
  }
}

//////////////////////////////////////////////////

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  //NSLog(@" 999999999 clickedButtonAtIndex: %d, firstOtherButtonIndex: %d, cancelButtonIndex: %d", buttonIndex, actionSheet.firstOtherButtonIndex, actionSheet.cancelButtonIndex);
}

- (void)actionSheet:(UIActionSheet*) actionSheet didDismissWithButtonIndex:(NSInteger) buttonIndex {
  
  NSLog(@"didDismissWithButtonIndex: %d, firstOtherButtonIndex: %d, cancelButtonIndex: %d", buttonIndex, actionSheet.firstOtherButtonIndex, actionSheet.cancelButtonIndex);
  
  if (buttonIndex == actionSheet.cancelButtonIndex) {
    NSLog(@"actionSheet cancel, isUIActionSheetVisible: %d", [self isUIActionSheetVisible:actionSheet]);
    [self showKeyboard];
    return;
  }
  
  NSString* buttonTitle = buttonIndex < actionSheet.numberOfButtons && buttonIndex >= 0 ? [actionSheet buttonTitleAtIndex:buttonIndex] : @"N/A (dismissed)";
  //NSLog(@"actionSheet buttonIndex: %d, thread %@", buttonIndex, [NSThread currentThread]);
  //NSLog(@"actionSheet buttonTitle: %@", buttonTitle);
  
  if (actionSheet == actionMainMenu) {
    
    if (buttonIndex == 100) {
      [VariousUtilities performAudioFeedbackFromString:@"Resume typing"];
    
    } else if (buttonIndex == 200) {
      //dismiss for orientation event, will show again right away
      
//    } else if ([buttonTitle isEqualToString:@"Clear"]) {
//      [self resetState];
//      [self voiceOverSpeak:@"Text cleared"];
//      //[self performSelector:@selector(showInitialMainMenu) withObject:nil afterDelay:1.2];
//      
    } else if ([buttonTitle isEqualToString:UPGRADE_FULL_VERSION_TITLE]) {
      [purchaseManager askUpgradeToFullVersion];
    } else if ([buttonTitle isEqualToString:RESTORE_FULL_VERSION_TITLE]) {
      [purchaseManager checkRestoreToFullVersion];

      
    } else if ([buttonTitle isEqualToString:@"Email"]) {
      [self sendInAppMailTo:nil useText:textView.text];
      
    } else if ([buttonTitle isEqualToString:@"Message"]) {
      [self sendInAppSMS:nil text:textView.text];
    
    } else if ([buttonTitle isEqualToString:BUTTON_TITLE_POST_TO_TWITTER]) {
      NSString* serviceType = nil;
      if (NSClassFromString(@"SLComposeViewController")) {
        serviceType = SLServiceTypeTwitter;
      }
      [self postToSocialService:serviceType text:textView.text];
      
    } else if ([buttonTitle isEqualToString:BUTTON_TITLE_POST_TO_FACEBOOK]) {
      [self postToSocialService:SLServiceTypeFacebook text:textView.text];
      
    } else if ([buttonTitle isEqualToString:BUTTON_TITLE_POST_TO_WEIBO]) {
      [self postToSocialService:SLServiceTypeSinaWeibo text:textView.text];
      
    } else if ([buttonTitle isEqualToString:@"Copy & Clear"]) {
      [self copyText];
      [self resetState];
      [self unSaveText];
      
    } else if ([buttonTitle isEqualToString:@"Instructions"]) {
      [self showDetailedInstructions:NO];
      
    } else if ([buttonTitle isEqualToString:@"Settings"]) {
      [self showSettings];
      
    } else if ([buttonTitle isEqualToString:@"Vote for Syntellia!"]) {
      [self showVoting:YES];
      
    } else if ([buttonTitle isEqualToString:@"♥ Fleksy in other apps?"]) {
      [self showFleksyInOtherApps];
    
    } else if ([buttonTitle isEqualToString:@"We love feedback!"]) {
      [self sendFeedback];
    } else if ([buttonTitle hasPrefix:@"Favorites"]) {
      
      isExecutedWithFavorites = YES;
      
      //FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain withMode:FL_FavoritesTVC_Mode_Operate];
      
      NSLog(@"Favorites BEFORE = %@", favorites);
      [self reloadFavorites];
      NSLog(@"Favorites AFTER = %@", favorites);
      
      favorites = [FLFavoritesTableViewController automaticReplenisherForFavorites:[favorites mutableCopy]];
      [self updateFavoriteStorage:favorites];
      
      FLFavoritesTableViewController *favTVC = [[FLFavoritesTableViewController alloc] initWithStyle:UITableViewStylePlain withMode:FL_FavoritesTVC_Mode_Operate withFavorites:favorites];
      favTVC.propertyType = (FL_PropertyType)(FL_PropertyType_PhoneNumber | FL_PropertyType_EmailAddress);

      favTVC.favoritesDelegate = self;
      favTVC.title = @"Favorites";
      
      if (favoritesNavigationController) {
        favoritesNavigationController = nil;
      }
//      else {
//        // Only replinish after a re-launch, just in case
//        favorites = [FLFavoritesTableViewController automaticReplenisherForFavorites:favorites];
//      }
//      
//      favTVC.favorites = favorites;

      favoritesNavigationController = [[UINavigationController alloc] init];
      
      [favoritesNavigationController addChildViewController:favTVC];
      
      [self presentViewController:favoritesNavigationController animated:YES completion:NULL];

//    } else if ([buttonTitle hasPrefix:@"Send to"]) {
//      NSString* recipient = [[buttonTitle componentsSeparatedByString:@"Send to "] objectAtIndex:1];
//      [self sendTo:recipient];
      
    } else if ([buttonTitle hasPrefix:@"Reply to"]) {
      NSString* recipient = [[buttonTitle componentsSeparatedByString:@"Reply to "] objectAtIndex:1];
      [self setReplyTo:nil];
      [self sendTo:recipient];
      
    } else if ([buttonTitle isEqualToString:@"Follow @fleksy"]) {
      [self menu_fleksy_twitter];
    
    } else if ([buttonTitle isEqualToString:@"Visit fleksy.com"]) {
      [self menu_fleksy_web];
      
    } else if ([buttonTitle isEqualToString:@"Export dictionary"]) {
      
      NSString* contents = [[FLTypingController_iOS sharedFLTypingController_iOS].fleksyClient.userDictionary stringContent];
      if (!contents || !contents.length) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Export dictionary" message:@"Dictionary is empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
      
      } else {
        
        [TestFlight passCheckpoint:@"ExportDictionary"];
        
        NSString* contents2 = [[contents stringByReplacingOccurrencesOfString:@"\n" withString:@":"] stringByReplacingOccurrencesOfString:@"\t" withString:@"_"];
        NSString* link = [NSString stringWithFormat:@"<a href=\"fleksy://_ADD_WORDS:%@\">Link</a>", [contents2 substringToIndex:contents2.length-1]];
        TestFlightLog(@"custom_dictionary:\n%@", contents);
        [self sendInAppMailTo:nil text:[NSString stringWithFormat:@"Click this link from a device that is running Fleksy to automatically add all these words: %@\n\n%@", link, contents] subject:@"My Fleksy dictionary backup" signature:NO];
      }
      
    } else if ([buttonTitle isEqualToString:@"Clear NSUserDefaults"]) {
      [NSUserDefaults resetStandardUserDefaults];
      [self recreatePlainMenus];
      [self reloadFavorites];
      [VariousUtilities performAudioFeedbackFromString:@"Cleared NSUserDefaults"];
      
    } else {
      NSLog(@"ERROR! unknown buttonIndex: %d, buttonTitle: %@", buttonIndex, buttonTitle);
    }
    
  } else if (actionSheet == initialMainMenu) {
    
    if (buttonIndex == 100) {
      [self resetState];
      
    } else if (buttonIndex == 200) {
      //dismiss for recreate, will show again right away
    
    } else if ([buttonTitle isEqualToString:UPGRADE_FULL_VERSION_TITLE]) {
      [purchaseManager askUpgradeToFullVersion];
    } else if ([buttonTitle isEqualToString:RESTORE_FULL_VERSION_TITLE]) {
      [purchaseManager checkRestoreToFullVersion];
    
    } else if ([buttonTitle isEqualToString:@"Instructions"]) {
      [self showDetailedInstructions:NO];
      
    } else if ([buttonTitle isEqualToString:@"Settings"]) {
      [self showSettings];
      
    } else if ([buttonTitle isEqualToString:@"Vote For Syntellia!"]) {
      [self showVoting:YES];
      
    } else if ([buttonTitle isEqualToString:@"♥ Fleksy in other apps?"]) {
      [self showFleksyInOtherApps];
      
    } else if ([buttonTitle isEqualToString:@"We love feedback!"]) {
      [self sendFeedback];
      
    } else if ([buttonTitle isEqualToString:@"Follow @fleksy"]) {
      [self menu_fleksy_twitter];
      
    } else if ([buttonTitle isEqualToString:@"Visit fleksy.com"]) {
      [self menu_fleksy_web];
    
    } else {
      NSLog(@"ERROR! unknown buttonIndex: %d, buttonTitle: %@", buttonIndex, buttonTitle);
    }
  }
}


- (BOOL) isUIActionSheetVisible:(UIActionSheet*) sheet {
  //the .visible property has a bug where on application resume it will always be NO
  //also isFirstResponder will be NO after we send an email / sms
  //so we also use window and superview
  return (sheet.visible || [sheet isFirstResponder] || sheet.superview || sheet.window);
}


- (void) showMenu {
  
  [TestFlight passCheckpoint:@"showMenu"];
  
  if (purchaseManager.previousRuns > 50 || UIAccessibilityIsVoiceOverRunning()) { [FLColdWar yay]; }
  
  if (FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER) {
    [self saveText];
  }
  
  if ([textView.text length] > 0) {
    [self showActionMainMenu];
  } else {
    [self showInitialMainMenu];
  }
}


- (void) startButtonAnimation {
  
  NSLog(@"startButtonAnimation");
  
  float scaleFactor = 1.0 / 0.75f;
  
  actionButton.alpha = 0.6;
  actionButton.imageView.transform = CGAffineTransformIdentity;
  
  [UIView animateWithDuration:1.7 delay:0.0f
                      options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionRepeat | UIViewAnimationOptionAutoreverse | UIViewAnimationOptionAllowUserInteraction
                   animations:^{
                     actionButton.alpha = 1.0;
                     actionButton.imageView.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                   }
                   completion:^(BOOL finished) {}];
}


- (void) voiceOverStatusChanged:(NSNotification*) notification {
  
  BOOL voiceover = UIAccessibilityIsVoiceOverRunning();
  
  //NSLog(@"voiceOverStatusChanged: %d", voiceover);
  
  actionButton.hidden = voiceover;
  //actionButton.userInteractionEnabled = !voiceover;
  actionButton.isAccessibilityElement = NO;
  //actionButton.alpha = voiceover ? 0.4 : 0.8;
  
  
  if (voiceover) {
    
    if (!FLEKSY_APP_SETTING_INVISIBLE_KEYBOARD) {
      textView.inputView.alpha = 1;
    }
    
    if (blindAppAlert) {
      [blindAppAlert dismissWithClickedButtonIndex:-1 animated:YES];
      blindAppAlert = nil;
    }
  }

}

- (void) applicationFinishedLoading {
  //[self.view addSubview:actionButton];
  [self voiceOverStatusChanged:nil];
  
  //NSLog(@"previousRuns: %d", purchaseManager.previousRuns);
}


- (void) recreateActionMenu {
  
  //We do all this so that the new buttons will be "added" on top, as the first buttons
  //In reality, they seldom attack a human. The actionSheet cannot be modified so we have to create a new one
  // also used for the menuception bug on iPad when title is too long
  
  BOOL actionMenuWasVisible = [self isUIActionSheetVisible:actionMainMenu];
  if (actionMenuWasVisible) {
    [actionMainMenu dismissWithClickedButtonIndex:200 animated:YES];
  }
  
  UIActionSheet* actionMainMenu2 = [[UIActionSheet alloc] initWithTitle:actionMainMenu.title delegate:self
                                                      cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  
  if (self->replyTo) {
    [actionMainMenu2 addButtonWithTitle:[NSString stringWithFormat:@"Reply to %@", self->replyTo]];
  }
  
  // Put Favorites at the top
  //[actionMainMenu2 addButtonWithTitle:[NSString stringWithFormat:@"Favorites"]];
  
  //now add rest
  for (int i = 0; i < actionMainMenuPlain.numberOfButtons; i++) {
    NSString* title = [actionMainMenuPlain buttonTitleAtIndex:i];
    int index = [actionMainMenu2 addButtonWithTitle:title];
    
    if (i == actionMainMenuPlain.cancelButtonIndex) {
      actionMainMenu2.cancelButtonIndex = index;
    }
    
    if ([title isEqualToString:@"Copy & Clear"]) {
      //first add favorites
      //Only add the "Send to Favorites Button"
      //      for (NSString* newButtonTitle in favorites) {
      //        [actionMainMenu2 addButtonWithTitle:[NSString stringWithFormat:@"Send to %@", newButtonTitle]];
      //      }
      [actionMainMenu2 addButtonWithTitle:[NSString stringWithFormat:@"Favorites"]];
      
    }
  }

  actionMainMenu = actionMainMenu2;
  
  if (actionMenuWasVisible) {
    [self showActionMainMenu];
  }
}


- (void) recreatePlainActionMenuWithTitle:(NSString*) title {
  actionMainMenuPlain  = [[UIActionSheet alloc] initWithTitle:title  delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  if (!purchaseManager.fullVersion) {
    [actionMainMenuPlain addButtonWithTitle:UPGRADE_FULL_VERSION_TITLE];
    [actionMainMenuPlain addButtonWithTitle:RESTORE_FULL_VERSION_TITLE];
  } else {
    [actionMainMenuPlain addButtonWithTitle:@"Copy & Clear"];
    [actionMainMenuPlain addButtonWithTitle:@"Email"];
    [actionMainMenuPlain addButtonWithTitle:@"Message"];
    
    if (NSClassFromString(@"SLComposeViewController")) {
      //if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
      [actionMainMenuPlain addButtonWithTitle:BUTTON_TITLE_POST_TO_TWITTER];
      //}
      //if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]) {
      [actionMainMenuPlain addButtonWithTitle:BUTTON_TITLE_POST_TO_FACEBOOK];
      //}
      if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeSinaWeibo]) {
        [actionMainMenuPlain addButtonWithTitle:BUTTON_TITLE_POST_TO_WEIBO];
      }
    } else if (NSClassFromString(@"TWTweetComposeViewController")) {
      [actionMainMenuPlain addButtonWithTitle:BUTTON_TITLE_POST_TO_TWITTER];
    } else {
      NSLog(@"No SLComposeViewController or TWTweetComposeViewController framework detected");
    }
  }
  [actionMainMenuPlain addButtonWithTitle:@"Instructions"];
  [actionMainMenuPlain addButtonWithTitle:@"Settings"];
  [actionMainMenuPlain addButtonWithTitle:@"Vote for Syntellia!"];
  [actionMainMenuPlain addButtonWithTitle:@"♥ Fleksy in other apps?"];
  [actionMainMenuPlain addButtonWithTitle:@"We love feedback!"];
  [actionMainMenuPlain addButtonWithTitle:@"Follow @fleksy"];
  [actionMainMenuPlain addButtonWithTitle:@"Visit fleksy.com"];
  if (purchaseManager.fullVersion) {
    [actionMainMenuPlain addButtonWithTitle:@"Export dictionary"];
  }
  
  //http://stackoverflow.com/questions/5262428/uiactionsheet-buttonindex-values-faulty-when-using-more-than-6-custom-buttons
  actionMainMenuPlain.cancelButtonIndex = [actionMainMenuPlain addButtonWithTitle:@"Resume typing"];
  
  //[actionMainMenuPlain addButtonWithTitle:@"Rate us"];
}


- (void) recreatePlainMenus {
  
  initialMainMenu = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
  if (!purchaseManager.fullVersion) {
    [initialMainMenu addButtonWithTitle:UPGRADE_FULL_VERSION_TITLE];
    [initialMainMenu addButtonWithTitle:RESTORE_FULL_VERSION_TITLE];
  }
  [initialMainMenu addButtonWithTitle:@"Instructions"];
  [initialMainMenu addButtonWithTitle:@"Settings"];
  [initialMainMenu addButtonWithTitle:@"Vote For Syntellia!"];
  [initialMainMenu addButtonWithTitle:@"♥ Fleksy in other apps?"];
  [initialMainMenu addButtonWithTitle:@"We love feedback!"];
  [initialMainMenu addButtonWithTitle:@"Follow @fleksy"];
  [initialMainMenu addButtonWithTitle:@"Visit fleksy.com"];
  //http://stackoverflow.com/questions/5262428/uiactionsheet-buttonindex-values-faulty-when-using-more-than-6-custom-buttons
  initialMainMenu.cancelButtonIndex = [initialMainMenu addButtonWithTitle:@"Start typing"];
  
  
  [self recreatePlainActionMenuWithTitle:ACTION_MENU_TITLE];
}

- (void) showBasicInstructions {
  if (UIAccessibilityIsVoiceOverRunning()) {
    self->basicInstructions = [[UIAlertView alloc] initWithTitle:@"Basic instructions"
                                                         message:@"Single tap where you think each letter is. No need to tap and hold or be accurate. Flick right for space, left to delete a word. Flick down for next suggestion. Flick right after space for punctuation. For menu, flick up with 2 fingers." delegate:self cancelButtonTitle:@"Cool, I got it!" otherButtonTitles:@"Instructions", nil];
    [self->basicInstructions show];
  }
}

- (void) showAlerts {
  
  if (purchaseManager.previousRuns < 2) {
    [self showBasicInstructions];
  }
  
#if !TARGET_IPHONE_SIMULATOR
  if (purchaseManager.previousRuns < 1 && !UIAccessibilityIsVoiceOverRunning()) {
    blindAppAlert = [[UIAlertView alloc] initWithTitle:@"Happy Typing!"
                                               message:@"\nThousands of sighted and blind users enjoy typing with Fleksy.\n\nClose your eyes and try typing! :)" delegate:nil cancelButtonTitle:@"Cool!" otherButtonTitles:nil];
  
  NSLog(@"%s BEFORE blindAppAlert",__PRETTY_FUNCTION__);
  
#ifdef FL_BUILD_FOR_BETA
  [blindAppAlert performSelector:@selector(show) withObject:nil afterDelay:3.0];
#else
  [blindAppAlert show];  
#endif
  NSLog(@"%s AFTER blindAppAlert",__PRETTY_FUNCTION__);

  
  }
#endif
}

- (BOOL) disablesAutomaticKeyboardDismissal {
  NSLog(@"disablesAutomaticKeyboardDismissal CALLED");
  return YES;
}

- (void) keyboardClicked:(id) object {
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController playError];
  [VariousUtilities performAudioFeedbackFromString:FLEKSY_ACTIVATE_KEYBOARD_WARNING];
  //[self showMenu];
}


- (void) reloadFavorites {
  [favorites removeAllObjects];
  if (FLEKSY_APP_SETTING_SPEED_DIAL_1 && FLEKSY_APP_SETTING_SPEED_DIAL_1.length) {
    NSArray* components = [FLEKSY_APP_SETTING_SPEED_DIAL_1 componentsSeparatedByString:@","];
    for (NSString* favorite in components) {
      NSString* trimmed = [favorite stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
      if (trimmed && trimmed.length) {
        [favorites addObject:trimmed];
      }
    }
  }
  [self recreateActionMenu];
}

- (void) setReplyTo:(NSString*) _replyTo {
  NSLog(@"setReplyTo: %@", _replyTo);
  self->replyTo = _replyTo;
  [self recreateActionMenu];
}



- (void) keyboardWillHide:(id) notification {
  [actionButton removeFromSuperview];
}


//we have to do this in UIKeyboardDidShowNotification, layout subview still hasn't changed the keyboard frame, since it is a different UIWINDOW!
- (void) keyboardDidShow:(id) notification {
//  tripleClickView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - textView.inputView.frame.size.height);
//  tripleClickView.hidden = !UIAccessibilityIsVoiceOverRunning();
//  NSLog(@"tripleClickView.frame: %@", NSStringFromCGRect(tripleClickView.frame));
//  NSLog(@"tripleClickView.hidden: %d", tripleClickView.hidden);
//  [self.view bringSubviewToFront:tripleClickView];
  
  [textView.inputView.window addSubview:actionButton];
  [self startButtonAnimation];
  
  if (!shownTutorial && purchaseManager.previousRuns < 1 && !self->textView.text.length && !UIAccessibilityIsVoiceOverRunning()) {
    shownTutorial = YES;
    self->textView.text = @"Welcome to Fleksy: You no longer need to be accurate! \n\nSpace: flick right → \nDelete: flick left ← \nChange word: flick down ↓ \nPunctuation: → after Space \n\nHappy Typing! ";
  }
}


- (void) resizeAndScrollTextView {
  CGRect rect = self.view.bounds;
  int paddingBottom = 4;
  // top padding (preserved, not set here) to match button height, 
  // bottom padding because "low" letters like qgpj may appear below the baseline
  
  FleksyKeyboard* keyboard = (FleksyKeyboard*) textView.inputView;
  float height = keyboard.visualHeight;
  //NSLog(@"resizeAndScrollTextView [rect: %@], height1: %.3f", NSStringFromCGRect(rect), height);
  
  if (FLEKSY_APP_SETTING_INVISIBLE_KEYBOARD) {
    height = 0;
  }
  
  textView.frame = CGRectMake(0, 0, rect.size.width, rect.size.height - height - paddingBottom);
  //textView.backgroundColor = [UIColor redColor];
  //NSLog(@"textView.text.length: %d", textView.text.length);
  [textView scrollRangeToVisible:NSMakeRange(textView.text.length-1, 1)];
}


- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  NSLog(@"FleksyAppMainViewController didReceiveMemoryWarning");
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
  self.appSettingsViewController = nil;
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  favoritesNavigationController = nil;
}


- (void) viewWillLayoutSubviews {
  NSLog(@"FleksyAppMainViewController viewWillLayoutSubviews self.view.frame %@", NSStringFromCGRect(self.view.frame));
}

- (void) viewDidLayoutSubviews {
  NSLog(@"FleksyAppMainViewController viewDidLayoutSubviews self.view.frame %@", NSStringFromCGRect(self.view.frame));

  int paddingRight = 3;
  int paddingTop = 3;
  
  actionButton.center = CGPointMake(self.view.bounds.size.width - actionButton.bounds.size.width / 2 + actionButton.contentEdgeInsets.right - paddingRight,
                                    paddingTop + actionButton.bounds.size.height / 2 - actionButton.contentEdgeInsets.top);

  //[actionButton.superview bringSubviewToFront:actionButton];
  [self resizeAndScrollTextView];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  NSLog(@"didRotateFromInterfaceOrientation self.view.frame %@", NSStringFromCGRect(self.view.frame));
  
  if (initialMainMenu.tag == TAG_RESHOW_AFTER_ROTATION) {
    [self showInitialMainMenu];
    initialMainMenu.tag = 0;
  }
  if (actionMainMenu.tag == TAG_RESHOW_AFTER_ROTATION) {
    [self showActionMainMenu];
    actionMainMenu.tag = 0;
  }
  
//  UIAccessibilityTraits previousTraits = textView.inputView.accessibilityTraits;
//  textView.inputView.accessibilityTraits = UIAccessibilityTraitNone;
//  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, textView.inputView);
//  textView.inputView.accessibilityTraits = previousTraits;
}


#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  
  if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
    
    purchaseManager = [[FLPurchaseManager alloc] initWithListener:self];
    
    NSString* log = [NSString stringWithFormat:@"Full version: %d, previousRuns/10: %d", purchaseManager.fullVersion, purchaseManager.previousRuns / 10];
    [TestFlight passCheckpoint:log];
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"VoiceOver: %d", UIAccessibilityIsVoiceOverRunning()]];
    
    //    UITapGestureRecognizer* singleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTap:)];
    //    singleTapRecognizer.delaysTouchesBegan = YES;
    //    [singleTapRecognizer requireGestureRecognizerToFail:tripleTapRecognizer];
    //    [tripleClickView addGestureRecognizer:singleTapRecognizer];
    
    
    UIImage* image = [UIImage imageNamed:@"menu_blue.png"];
    float scale = deviceIsPad() ? 2 : 1;
    float buttonSize = 80 * scale;
    actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonSize, buttonSize)]; //this will be the hit area
    
    float insetX = buttonSize * 0.3;
    float insetY = insetX;
    actionButton.contentEdgeInsets = UIEdgeInsetsMake(insetY, insetX, insetY, insetX);
    
    [actionButton setImage:image forState:UIControlStateNormal];
    actionButton.showsTouchWhenHighlighted = YES;
    //actionButton.backgroundColor = [UIColor redColor];
    actionButton.imageView.backgroundColor = FLEKSYTHEME.actionButton_imageView_backgroundColor;
    actionButton.accessibilityLabel = @"Action";
    actionButton.accessibilityHint = @"Double tap for menu";
    [actionButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
    
    //actionButton.transform = CGAffineTransformMakeScale(2, 2);
    
    
    // we need to do this to ensure glow effect can be on top of the imageView
    // we wouldn't need to do this if we used setBackgroundImage instead of setImage,
    // but then contentEdgeInsets wouldn't apply
    [actionButton.imageView.superview sendSubviewToBack:actionButton.imageView];
    
    lastShowedInitMenu = 0;
    lastShowedActionMenu = 0;
    self->replyTo = nil;
    
    [self recreatePlainMenus];
    actionMainMenu = actionMainMenuPlain;
    
    favorites = [[NSMutableArray alloc] init];
    [self reloadFavorites];
        
    //self.wantsFullScreenLayout = YES;
    
    shownTutorial = NO;
    
    NSLog(@"self.disablesAutomaticKeyboardDismissal: %d", self.disablesAutomaticKeyboardDismissal);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardClicked:) name:FLEKSY_KEYBOARD_CLICKED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMenu) name:FLEKSY_MENU_INVOKED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFavoritesWillUpdate:) name:FleksyFavoritesWillUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFavoritesDidUpdate:) name:FleksyFavoritesDidUpdateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeDidChange:) name:FleksyThemeDidChangeNotification object:nil];

    _userHasVisitedQuestionaireLink = [[NSUserDefaults standardUserDefaults] boolForKey:@"FLEKSY_APP_CACHE_WSJ_QUESTIONAIRE"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handle_kIASKAppSettingChanged:) name:kIASKAppSettingChanged object:nil];
    //kIASKAppSettingChanged
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSignatureWillUpdate:) name:FleksySignatureWillUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSignatureDidUpdate:) name:FleksySignatureDidUpdateNotification object:nil];

  }
  return self;
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
 
  // First time: favorites may not be properly loaded
  
  if ([favorites count] == 0 && [FLEKSY_APP_SETTING_SPEED_DIAL_1 length] > 0) {
    [self reloadFavorites];
  }

#ifndef RELEASE
  NSLog(@"Favorites before strip: %@", favorites);
  NSLog(@"SPEED DIAL before strip: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);
  
  favorites = [self testStripFavoritesOfNames:[favorites mutableCopy]];
  
  NSLog(@"Favorites after strip: %@", favorites);
  NSLog(@"SPEED DIAL after strip: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);
  
  [self updateFavoriteStorage:favorites];
#endif
  
  NSLog(@"Favorites before magic: %@", favorites);
  NSLog(@"SPEED DIAL before magic: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);
  
    [FLFavoritesTableViewController checkAddressBookAuthorizationWithCompletion:^{
      favorites = [FLFavoritesTableViewController automaticReplenisherForFavorites:[favorites mutableCopy]];
      
      NSLog(@"Favorites after magic: %@", favorites);
      NSLog(@"SPEED DIAL after magic: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);
      
      [self updateFavoriteStorage:favorites];
      
      NSLog(@"Favorites after update: %@", favorites);
      NSLog(@"SPEED DIAL after update: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);

    }];
  
//  favorites = [FLFavoritesTableViewController automaticReplenisherForFavorites:[favorites mutableCopy]];
  
//  NSLog(@"Favorites after magic: %@", favorites);
//  NSLog(@"SPEED DIAL after magic: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);
//  
//  [self updateFavoriteStorage:favorites];
//  
//  NSLog(@"Favorites after update: %@", favorites);
//  NSLog(@"SPEED DIAL after update: %@", FLEKSY_APP_SETTING_SPEED_DIAL_1);

  if (!FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER) {
    [self unSaveText];
  }
}

- (NSMutableArray *)testStripFavoritesOfNames:(NSMutableArray *)myFavorites {
    
  // Convert  {Sam_Jones:a1@b1.com,Tiny_Tim:222-333-4444} to {a1b1.com, 222-333-4444}
  for (int i = 0; i < [myFavorites count]; i++) {
    NSString *favString = [myFavorites objectAtIndex:i];
    NSArray *components = [favString componentsSeparatedByString:@":"];
    if ([components count] > 1) {
      [myFavorites replaceObjectAtIndex:i withObject:components[1]];
    }
  }
  return myFavorites;
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Orientation and Rotation Support

- (BOOL) shouldAutorotate {
  
  //FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION = [[[NSUserDefaults standardUserDefaults] valueForKey:@"FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION"] boolValue];
  
  BOOL result = YES; //!FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION;
  ///NSLog(@"123123 shouldAutorotate, FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION: %d, current device orientation: %d. Result: %d", FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION, [UIDevice currentDevice].orientation, result);
  NSLog(@"123123 shouldAutorotate, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d, result: %d", FLEKSY_APP_SETTING_LOCK_ORIENTATION, result);
  return result;
}


//- (UIInterfaceOrientation) preferredInterfaceOrientationForPresentation {
//  return result;
//}


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
  //NSLog(@"1231234 supportedInterfaceOrientations, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d, result: %d", FLEKSY_APP_SETTING_LOCK_ORIENTATION, result);
  return result;
}

// for iOS 5.0 compatibility
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return [self shouldAutorotate];
}

- (CGRect) keyboardFrameForOrientation:(UIInterfaceOrientation) orientation {
  
  CGRect bounds = [UIScreen mainScreen].bounds;
  CGRect result;
  
  if (FLEKSY_FULLSCREEN) {
    if (UIInterfaceOrientationIsLandscape(orientation)) {
      result = CGRectMake(0, 0, bounds.size.height, bounds.size.width);
    } else {
      result = CGRectMake(0, 0, bounds.size.width, bounds.size.height);
    }
  } else {
    if (UIInterfaceOrientationIsLandscape(orientation)) {
      result = CGRectMake(0, 0, bounds.size.height, FLEKSY_DEFAULT_HEIGHT_LANDSCAPE + FLEKSY_TOP_PADDING_LANDSCAPE);
    } else {
      result = CGRectMake(0, 0, bounds.size.width, FLEKSY_DEFAULT_HEIGHT_PORTRAIT + FLEKSY_TOP_PADDING_PORTRAIT);
    }
  }
  
  //NSLog(@"123123 keyboardFrameForOrientation %d: %@. Bounds was %@, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d", orientation, NSStringFromCGRect(result), NSStringFromCGRect(bounds), FLEKSY_APP_SETTING_LOCK_ORIENTATION);
  return result;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  
  //NSLog(@"123123 willRotateToInterfaceOrientation %d, FLEKSY_APP_SETTING_LOCK_ORIENTATION: %d", toInterfaceOrientation, FLEKSY_APP_SETTING_LOCK_ORIENTATION);
  //NSLog(@"self.view.bounds: %.2f %.2f", self.view.bounds.size.width, self.view.bounds.size.height);

  // have to change the keyboard frame here, not in layout since the keyboard is a whole different window of its own
  // TODO: we should have a dedicated controller just for the keyboard
  textView.inputView.frame = [self keyboardFrameForOrientation:toInterfaceOrientation];
  
  if (!UIAccessibilityIsVoiceOverRunning()) {
    
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
      [VariousUtilities performAudioFeedbackFromString:@"Portrait"];
    }
    
    if (toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
      [VariousUtilities performAudioFeedbackFromString:@"Portrait flipped"];
    }
    
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight) {
      [VariousUtilities performAudioFeedbackFromString:@"Landscape. Home button to the right"];
    }
    
    if (toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
      [VariousUtilities performAudioFeedbackFromString:@"Landscape. Home button to the left"];
    }
  }
  
  AppDelegate* appDelegate = (AppDelegate*) [UIApplication sharedApplication].delegate;
  [appDelegate setProximityMonitoringEnabled:!UIInterfaceOrientationIsLandscape(toInterfaceOrientation)];
  
  
  if ([self isUIActionSheetVisible:initialMainMenu]) {
    [self dismissInitialMainMenu];
    initialMainMenu.tag = TAG_RESHOW_AFTER_ROTATION;
  }
  if ([self isUIActionSheetVisible:actionMainMenu]) {
    [self dismissActionMainMenu];
    actionMainMenu.tag = TAG_RESHOW_AFTER_ROTATION;
  }
}


/*

- (void) handleNewInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	
  NSLog(@"handleNewInterfaceOrientation, orientation: %d", toInterfaceOrientation);
  
  //[[UIApplication sharedApplication] setStatusBarOrientation:[UIDevice currentDevice].orientation animated:YES];
  
	//NOTE: here we assume that screen bounds is a rect that
	//matches PORTRAIT MODE. So if in the future there is a device 
	//like a netbook that has a default landscape orientation, we 
	//need to check what screen bounds returns
	
	CGSize size = [[UIScreen mainScreen] bounds].size;
	
	if(toInterfaceOrientation == UIInterfaceOrientationPortrait || toInterfaceOrientation == UIInterfaceOrientationPortraitUpsideDown){
		
	} else if(toInterfaceOrientation == UIInterfaceOrientationLandscapeRight || toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft){
//    size = CGSizeMake(size.height, size.width);
	}
	
	
  //self.view.frame = self.view.superview.bounds;
	
  //self.view.frame = CGRectMake(0, 0, 500, 500);
  
  //for (UIView* subview in self.view.subviews) {
  //  [subview setNeedsLayout];
  //}
  
	
  //NSLog(@"self.view.bounds: %.2f %.2f", self.view.bounds.size.width, self.view.bounds.size.height);
  //NSLog(@"self.view.frame:  %.2f %.2f", self.view.frame.size.width,  self.view.frame.size.height);
  
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//NSLog(@"didRotateFromInterfaceOrientation, orientation: %d", fromInterfaceOrientation);
	//NSLog(@"self.view.bounds: %.2f %.2f", self.view.bounds.size.width, self.view.bounds.size.height);  
}


- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
  
	//NSLog(@"willRotateToInterfaceOrientation, orientation: %d", toInterfaceOrientation);
  //NSLog(@"self.view.bounds: %.2f %.2f", self.view.bounds.size.width, self.view.bounds.size.height);
  
	[UIView setAnimationsEnabled:YES];
	
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  
	[UIView beginAnimations:nil context:NULL];
  [UIView setAnimationDuration:duration];// * 2];
	
	[self handleNewInterfaceOrientation:toInterfaceOrientation];
  
	
	[UIView commitAnimations];
}
 */

- (void) setTextView:(FleksyTextView*) _textView {
  NSLog(@"setTextView");
  self->textView = _textView;
  self->textView.fleksyTextViewDelegate = self;
}

#pragma mark - FleksyTextViewDelegate Protocol Method

- (void) textViewDidBeginEditing:(UITextView *)aTextView {
  NSLog(@"FleksyAppMainViewController textViewDidBeginEditing");
  if (FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER && [aTextView.text length] != 0) { // Case: First time setting is turned on
    [self saveText];
  }
  else if (FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER) { // Case: App relaunch
    [aTextView setText:[[NSUserDefaults standardUserDefaults] objectForKey:@"FLEKSY_APP_SETTING_SAVE_TEXT_BUFFER_KEY"]];
  }
  else {
    [self unSaveText];
  }

}

@synthesize purchaseManager;

@end
