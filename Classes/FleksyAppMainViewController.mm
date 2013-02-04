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

//#define APP_STORE_LINK @"http://itunes.apple.com/us/app/fleksy/id520337246?mt=8&uo=4"

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

@implementation FleksyAppMainViewController


- (void) hideKeyboard {
  
  //we now (DIRECT_TOUCH) avoid resigning the keyboard, otherwise we always need 1 initial tap to "activate" it...
  //problem still exists at the very beginning of app launch
  
  //MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);

  //return;
 
  NSLog(@"hideKeyboard");
  [textView resignFirstResponder];
}

- (void) showKeyboard {
  
  //NSLog(@"controller showKeyboard, textView was responder: %d", textView.isFirstResponder);
  //return;
  
  if (!textView.isFirstResponder) {
    [textView becomeFirstResponder];
  } else {
    [textView reloadInputViews];
  }
  
}

- (NSString*) getMessageFooter {
  if (FLEKSY_APP_SETTING_SMS_REPLY_TO && FLEKSY_APP_SETTING_SMS_REPLY_TO.length) {
    return [NSString stringWithFormat:@"%@reply://%@", APP_STORE_LINK_SMS, FLEKSY_APP_SETTING_SMS_REPLY_TO];
  } else {
    return APP_STORE_LINK_SMS;
  }
}

- (NSString*) emailSignature {
  NSString* result = FLEKSY_APP_SETTING_EMAIL_SIGNATURE;
  if (!result) {
    result = @"";
  }
  NSString* fleksyLink = [NSString stringWithFormat:@"<a href=\"%@\">Fleksy</a>", @"http://fleksy.com/app"];
  result = [result stringByReplacingOccurrencesOfString:@"fleksy" withString:@"Fleksy"];
  result = [result stringByReplacingOccurrencesOfString:@"Fleksy" withString:fleksyLink];
  return result;
}

- (NSString*) getEmailFooter {
  NSMutableString* result = [[NSMutableString alloc] init];
  [result appendString:[self emailSignature]];
  if (FLEKSY_APP_SETTING_EMAIL_REPLY_TO && FLEKSY_APP_SETTING_EMAIL_REPLY_TO.length) {
    [result appendFormat:@"</br>reply://%@", FLEKSY_APP_SETTING_EMAIL_REPLY_TO];
  }
  [result appendString:@"</br></br>"];
  return result;
}


- (void) resetState {
  textView.text = @"";
  [[FLKeyboardContainerView sharedFLKeyboardContainerView] reset];
}

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

- (void) copyText {
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:@"ACTION_COPY"];
  UIPasteboard* pasteboard = [UIPasteboard generalPasteboard];
  [pasteboard setString:textView.text];
}

- (void) _showActionMainMenu {
  //[self hideKeyboard];
  actionMainMenu.title = [NSString stringWithFormat:@"%@", textView.text];
  
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
  
  NSLog(@"postToSocialService: %@", serviceType);
  
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
  
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:[NSString stringWithFormat:@"ACTION_%@", serviceType]];
  
  
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
  
  [[FLKeyboardContainerView sharedFLKeyboardContainerView].typingController.diagnostics sendWithComment:@"ACTION_SMS"];
  
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
  [self presentViewController:smsController animated:YES completion:nil];
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


- (void) sendInAppMailTo:(NSString*) recipient text:(NSString*) text subject:(NSString*) subject {
  
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
  [mailController setToRecipients:[NSArray arrayWithObjects:recipient, nil]];
  
  BOOL html = YES;
  if (html) {
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"</br>"];
  }
  
  [mailController setMessageBody:[NSString stringWithFormat:@"%@</br></br>%@", text, [self getEmailFooter]] isHTML:html];
  [self presentViewController:mailController animated:YES completion:nil];
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
  [self sendInAppMailTo:recipient text:text subject:[NSString stringWithFormat:@"%@%@", subjectPrefix, subject]];
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
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/fleksy"]];  
}

- (void) menu_fleksy_web {
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://fleksy.com"]];  
}

- (void) menu_rate {
  //NSLog(@"Rate us");
  [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://fleksy.com/rate"]];
}

- (void) showDetailedInstructions {
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

  //create and load the web request, that will eventually trigger webViewDidFinishLoad
  NSString* filename = UIAccessibilityIsVoiceOverRunning() ? @"index-voiceover" : @"index-sighted";
  NSURL* url = [[VariousUtilities theBundle] URLForResource:filename withExtension:@".htm" subdirectory:@"instructions"];
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

- (void) dismissInstructions {
  [self dismissViewControllerAnimated:YES completion:nil];
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
      [self showDetailedInstructions];
    }
    return;
  }
  
  if (alertView == self->askClearDefaultsAlert) {
    if (buttonIndex == 1) {
      [self clearDefaultsAndCloud];
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


- (void) sendTo:(NSString*) recipient {
  if ([recipient rangeOfString:@"@"].location != NSNotFound) {
    [self sendInAppMailTo:recipient useText:textView.text];
  } else {
    [self sendInAppSMS:recipient text:textView.text];
  }
}

//////////////////////////////////////////////////

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
  //NSLog(@"clickedButtonAtIndex: %d, firstOtherButtonIndex: %d, cancelButtonIndex: %d", buttonIndex, actionSheet.firstOtherButtonIndex, actionSheet.cancelButtonIndex);
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
      
    } else if ([buttonTitle isEqualToString:@"Instructions"]) {
      [self showDetailedInstructions];
      
    } else if ([buttonTitle isEqualToString:@"Feedback"]) {
      [TestFlight submitFeedback:textView.text];
      
      if (purchaseManager.fullVersion) {
        [self sendInAppMailTo:@"feedback@fleksy.com" useText:textView.text subjectPrefix:@"Feedback: "];
      } else {
        [VariousUtilities performAudioFeedbackFromString:@"Thank you. Your feedback has been submitted"];
      }
      
    } else if ([buttonTitle isEqualToString:@"Rate us"]) {
      [self menu_rate];
      
    } else if ([buttonTitle hasPrefix:@"Send to"]) {
      NSString* recipient = [[buttonTitle componentsSeparatedByString:@"Send to "] objectAtIndex:1];
      [self sendTo:recipient];
      
    } else if ([buttonTitle hasPrefix:@"Reply to"]) {
      NSString* recipient = [[buttonTitle componentsSeparatedByString:@"Reply to "] objectAtIndex:1];
      [self setReplyTo:nil];
      [self sendTo:recipient];
      
    } else if ([buttonTitle isEqualToString:@"Fleksy on twitter"]) {
      [self menu_fleksy_twitter];
    
    } else if ([buttonTitle isEqualToString:@"Fleksy on the web"]) {
      [self menu_fleksy_web];
      
    } else if ([buttonTitle isEqualToString:@"Export dictionary"]) {
      
      NSString* contents = [[FLTypingController_iOS sharedFLTypingController_iOS].fleksyClient.userDictionary stringContent];
      if (!contents || !contents.length) {
        
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Export dictionary" message:@"Dictionary is empty" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
      
      } else {
        
        NSString* contents2 = [[contents stringByReplacingOccurrencesOfString:@"\n" withString:@":"] stringByReplacingOccurrencesOfString:@"\t" withString:@"_"];
        NSString* link = [NSString stringWithFormat:@"<a href=\"fleksy://_ADD_WORDS:%@\">Link</a>", [contents2 substringToIndex:contents2.length-1]];
        TestFlightLog(@"custom_dictionary:\n%@", contents);
        [self sendInAppMailTo:nil text:[NSString stringWithFormat:@"Click this link from a device that is running Fleksy to automatically add all these words: %@\n\n%@", link, contents] subject:@"My Fleksy dictionary backup"];
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
      [self showDetailedInstructions];
      
    } else if ([buttonTitle isEqualToString:@"Fleksy on twitter"]) {
      [self menu_fleksy_twitter];
      
    } else if ([buttonTitle isEqualToString:@"Fleksy on the web"]) {
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
  
  if ([textView.text length] > 0) {
    [self showActionMainMenu];
  } else {
    [self showInitialMainMenu];
  }
}


- (void) voiceOverStatusChanged:(NSNotification*) notification {
  
  BOOL voiceover = UIAccessibilityIsVoiceOverRunning();
  
  //NSLog(@"voiceOverStatusChanged: %d", voiceover);
  
  //actionButton.hidden = voiceover;
  actionButton.userInteractionEnabled = !voiceover;
  actionButton.isAccessibilityElement = NO;
  actionButton.alpha = voiceover ? 0.4 : 0.8;
  
  
  if (voiceover) {
    
    textView.inputView.alpha = 1;
    
    if (blindAppAlert) {
      [blindAppAlert dismissWithClickedButtonIndex:-1 animated:YES];
      blindAppAlert = nil;
    }
  }  
}

- (void) applicationFinishedLoading {
  //[self.view addSubview:actionButton];
  [self voiceOverStatusChanged:nil];
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
  
  //now add rest
  for (int i = 0; i < actionMainMenuPlain.numberOfButtons; i++) {
    NSString* title = [actionMainMenuPlain buttonTitleAtIndex:i];
    int index = [actionMainMenu2 addButtonWithTitle:title];
    
    if (i == actionMainMenuPlain.cancelButtonIndex) {
      actionMainMenu2.cancelButtonIndex = index;
    }
    
    if ([title isEqualToString:@"Copy & Clear"]) {
      //first add favorites
      for (NSString* newButtonTitle in favorites) {
        [actionMainMenu2 addButtonWithTitle:[NSString stringWithFormat:@"Send to %@", newButtonTitle]];
      }
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
  [actionMainMenuPlain addButtonWithTitle:@"Feedback"];
  if (purchaseManager.fullVersion) {
    [actionMainMenuPlain addButtonWithTitle:@"Export dictionary"];
  }
  [actionMainMenuPlain addButtonWithTitle:@"Fleksy on twitter"];
  [actionMainMenuPlain addButtonWithTitle:@"Fleksy on the web"];
  
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
  [initialMainMenu addButtonWithTitle:@"Fleksy on twitter"];
  [initialMainMenu addButtonWithTitle:@"Fleksy on the web"];
  //http://stackoverflow.com/questions/5262428/uiactionsheet-buttonindex-values-faulty-when-using-more-than-6-custom-buttons
  initialMainMenu.cancelButtonIndex = [initialMainMenu addButtonWithTitle:@"Start typing"];
  
  
  [self recreatePlainActionMenuWithTitle:ACTION_MENU_TITLE];
}

- (void) showBasicInstructions {
  if (UIAccessibilityIsVoiceOverRunning()) {
    self->basicInstructions = [[UIAlertView alloc] initWithTitle:@"Basic instructions"
                                                         message:@"Single tap where you think each letter is.\nNo need to tap and hold or be accurate.\nSwipe right for space, left to delete a word.\nSwipe down for next suggestion.\nSwipe right after space for punctuation." delegate:self cancelButtonTitle:@"Cool, I got it!" otherButtonTitles:@"Instructions", nil];
  } else {
    self->basicInstructions = [[UIAlertView alloc] initWithTitle:@"With Fleksy, you no longer need to be accurate!"
                                                         message:@"It will correct most mistyped letters\n\nSwipe right for space, left to delete\nSwipe down for next suggestion\nSwipe right again for punctuation\n\nHappy Typing!" delegate:self cancelButtonTitle:@"Cool, I got it!" otherButtonTitles:@"Instructions", nil];
  }
  [self->basicInstructions show];
}

- (void) showAlerts {
  
  if (purchaseManager.previousRuns < 2) {
    [self showBasicInstructions];
  }
  
#if !TARGET_IPHONE_SIMULATOR //&& !DEBUG
  if (purchaseManager.previousRuns < 5 && !UIAccessibilityIsVoiceOverRunning()) {
    blindAppAlert = [[UIAlertView alloc] initWithTitle:@"Did you know?"
                                               message:@"\nThis technology was designed specifically for the blind. If you have normal vision you may find some features to be rather different to what you are used to. Please remember that if you write a review.\n\nBy all means, give it a try and let us know how you like Fleksy." delegate:nil cancelButtonTitle:@"OK, let me try!" otherButtonTitles:nil];
    [blindAppAlert show];
  }
#endif
}

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

      
      UIImage* image = [UIImage imageNamed:@"Arrow.png"];
      float scale = deviceIsPad() ? 1.2 : 0.6;
      actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, image.size.width * scale, image.size.height * scale)];
      float insetX = actionButton.frame.size.width * 0.35;
      float insetY = actionButton.frame.size.height * 0.35;
      actionButton.contentEdgeInsets = UIEdgeInsetsMake(insetY, insetX, insetY, insetX);
      [actionButton setImage:image forState:UIControlStateNormal];
      actionButton.showsTouchWhenHighlighted = YES;
      actionButton.alpha = 0.8;
      //actionButton.backgroundColor = [UIColor blueColor];
      actionButton.imageView.backgroundColor = FLEKSY_TEXTVIEW_COLOR;
      actionButton.accessibilityLabel = @"Action";
      actionButton.accessibilityHint = @"Double tap for menu";
      [actionButton addTarget:self action:@selector(showMenu) forControlEvents:UIControlEventTouchUpInside];
      
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
      
      NSLog(@"self.disablesAutomaticKeyboardDismissal: %d", self.disablesAutomaticKeyboardDismissal);
      
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardClicked:) name:FLEKSY_KEYBOARD_CLICKED_NOTIFICATION object:nil];
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showMenu) name:FLEKSY_MENU_INVOKED_NOTIFICATION object:nil];
    }
    return self;
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

- (void) tripleTap:(UIGestureRecognizer*) gestureRecognizer {
  
  if (gestureRecognizer.state == UIGestureRecognizerStateRecognized) {
    //NSLog(@"tripleTap!");
    [self showMenu];
    //UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"title" message:@"message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:@"button2", nil];
    //[alert show];
  }
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
}


- (void) viewWillLayoutSubviews {
  //NSLog(@"FleksyAppMainViewController viewWillLayoutSubviews self.view.frame %@", NSStringFromCGRect(self.view.frame));
  int paddingRight = 1;//7;
  int paddingTop = 1;//7;
  actionButton.frame = CGRectMake(self.view.bounds.size.width - actionButton.frame.size.width + actionButton.contentEdgeInsets.right - paddingRight,
                                  paddingTop - actionButton.contentEdgeInsets.top, actionButton.frame.size.width, actionButton.frame.size.height);
  
  //[actionButton.superview bringSubviewToFront:actionButton];
  [self resizeAndScrollTextView];
}

- (void) viewDidLayoutSubviews {
  //NSLog(@"viewDidLayoutSubviews self.view.frame %@", NSStringFromCGRect(self.view.frame));
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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL) shouldAutorotate {
  
  //FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION = [[[NSUserDefaults standardUserDefaults] valueForKey:@"FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION"] boolValue];
  
  BOOL result = YES; //!FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION;
  //NSLog(@"123123 shouldAutorotate, FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION: %d, current device orientation: %d. Result: %d", FLEKSY_APP_SETTING_LOCK_CURRENT_ORIENTATION, [UIDevice currentDevice].orientation, result);
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
}

@synthesize purchaseManager;

@end
