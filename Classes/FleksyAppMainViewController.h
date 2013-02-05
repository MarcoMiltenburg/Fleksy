//
//  MainViewController.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/9/11.
//  Copyright 2011 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <MessageUI/MFMailComposeViewController.h>
#import <MessageUI/MFMessageComposeViewController.h>
#import <Social/Social.h>
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "FleksyTextView.h"
#import "FLPurchaseManager.h"

#define FLEKSY_DIRECT_TOUCH 1

@interface FleksyAppMainViewController : UIViewController<UIActionSheetDelegate, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, FLPurchaseListener, UIWebViewDelegate, UITextViewDelegate> {

  FleksyTextView* textView;
  UIActionSheet* initialMainMenu;
  
  UIActionSheet* actionMainMenu;
  UIActionSheet* actionMainMenuPlain;
  
  NSMutableArray* favorites;
  
  double lastShowedInitMenu;
  double lastShowedActionMenu;
  
  UIAlertView* blindAppAlert;
  UIAlertView* basicInstructions;
  
  NSString* replyTo;
  
  FLPurchaseManager* purchaseManager;
  
  //
  UIViewController* instructionsController;
  UIWebView* instructionsWebView;
  
  UIButton* actionButton;
  UIAlertView* askClearDefaultsAlert;
  
  UIButton* testView;
}

- (void) applicationFinishedLoading;
- (void) startButtonAnimation;
- (void) showMenu;
- (void) voiceOverStatusChanged:(NSNotification*) notification;
- (void) reloadFavorites;
- (void) resetState;
- (void) dismissActionMainMenu;
- (void) setReplyTo:(NSString*) _replyTo;
- (void) showAlerts;
- (void) setTextView:(FleksyTextView*) _textView;
- (BOOL) shouldSpeakText;
- (CGRect) keyboardFrameForOrientation:(UIInterfaceOrientation) orientation;

@property (readonly) FLPurchaseManager* purchaseManager;

@end
