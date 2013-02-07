//
//  FLPurchaseManager.m
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/23/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FLPurchaseManager.h"
#import "Settings.h"

#define FLEKSY_FULL_VERSION @"FLEKSY_FULL_VERSION"
#define FLEKSY_GRANDFATHERED @"FLEKSY_GRANDFATHERED"
#define FLEKSY_HAS_RUN_FREEMIUM @"FLEKSY_HAS_RUN_FREEMIUM"
#define FLEKSY_INAPP_ID01 @"com.syntellia.Fleksy.IAP01"

typedef enum {
  FLRestoreTypeNone, //purchase, not fail
  FLRestoreTypeGrandfathered,
  FLRestoreTypeApple,
} FLRestoreType;


@implementation FLPurchaseManager

- (void) setFullVersion:(BOOL) _fullVersion {
  if (!_fullVersion) {
    [[NSUbiquitousKeyValueStore defaultStore] removeObjectForKey:FLEKSY_GRANDFATHERED];
  }
  [[NSUserDefaults standardUserDefaults]    setBool:_fullVersion forKey:FLEKSY_FULL_VERSION];
  [[NSUbiquitousKeyValueStore defaultStore] setBool:_fullVersion forKey:FLEKSY_FULL_VERSION];
  [[NSUserDefaults standardUserDefaults]    synchronize];
  [[NSUbiquitousKeyValueStore defaultStore] synchronize];
}

- (BOOL) fullVersion {

  // Fleksy for iOS is now FREE for all.
  return YES;
  
  if ([self isGrandfathered]) {
    return YES;
  }
  return [[NSUserDefaults standardUserDefaults] boolForKey:FLEKSY_FULL_VERSION] || [[NSUbiquitousKeyValueStore defaultStore] boolForKey:FLEKSY_FULL_VERSION];
}


- (id) initWithListener:(id<FLPurchaseListener>) _listener {
  if (self = [super init]) {
    
    self->listener = _listener;

    //load values
    previousRuns = [[NSUserDefaults standardUserDefaults] integerForKey:FLEKSY_PREVIOUS_RUNS];
    BOOL hasRunFreemiumVersionBefore = [[NSUserDefaults standardUserDefaults] boolForKey:FLEKSY_HAS_RUN_FREEMIUM];
    
    //grandfather check on first run only
    if (!hasRunFreemiumVersionBefore && previousRuns > 0) {
      NSLog(@"hasRunFreemiumVersionBefore: NO, and previousRuns = %d, grandfathering into full version of freemium", previousRuns);
      //mark as full version locally and on iCloud
      self.fullVersion = YES;
      //mark as full version on iCloud. If a grandfathered user later moves to a different device this will be our way of knowing.
      [[NSUbiquitousKeyValueStore defaultStore] setBool:YES forKey:FLEKSY_GRANDFATHERED];
    }
    
    //mark so that next run will not be considered first run of freemium
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:FLEKSY_HAS_RUN_FREEMIUM];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
  }
  return self;
}

- (void) incrementRuns {
  [[NSUserDefaults standardUserDefaults] setInteger:previousRuns+1 forKey:FLEKSY_PREVIOUS_RUNS];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) resetRuns {
  previousRuns = 0;
  [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:FLEKSY_PREVIOUS_RUNS];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) isGrandfathered {
  return [[NSUbiquitousKeyValueStore defaultStore] boolForKey:FLEKSY_GRANDFATHERED];
}

- (void) checkRestoreToFullVersion {
  
  // this is needed for ex. in the case where the login prompt has a username that is not the one we want.
  // if we switch to settings app and come back, the login prompt is lost and we will keep getting 
  // <SKPaymentQueue: 0x365d90>: Ignoring restoreCompletedTransactions because already restoring transactions
  // if we simply call restoreCompletedTransactions
  
//  NSLog(@"transactions in queue: %d", [SKPaymentQueue defaultQueue].transactions.count);
//  NSLog(@"will finish transactions...");
//  for (SKPaymentTransaction* transaction in [SKPaymentQueue defaultQueue].transactions) {
//    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
//  }
//  NSLog(@"transactions in queue: %d", [SKPaymentQueue defaultQueue].transactions.count);
  
  if ([self isGrandfathered]) {
    [self handlePurchasedFullVersionWithRestore:FLRestoreTypeGrandfathered];
  } else {
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
  }
}

- (void) handlePurchasedFullVersionWithRestore:(FLRestoreType) restoreType {
  NSString* log = [NSString stringWithFormat:@"PurchasedFullVersion: %@, restoreType: %d", FLEKSY_INAPP_ID01, restoreType];
  TestFlightLog(@"%@", log);
  [TestFlight passCheckpoint:log];
  self.fullVersion = YES;
  
  if (restoreType == FLRestoreTypeNone) {
    [[[UIAlertView alloc] initWithTitle:@"Purchase complete" message:@"Thank you for purchasing the full version of Fleksy. Additional menu options are now available." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
  } else {
    [[[UIAlertView alloc] initWithTitle:@"Restore complete" 
                                message:[NSString stringWithFormat:@"Thank you for previously purchasing Fleksy. You have now upgraded to the full version. [%d]", restoreType] 
                               delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
  }
  
  [listener switchToFullVersion];
}


#pragma mark SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions {
  //Your application does not typically need to implement this method but might implement it to update its own user interface to reflect that a transaction has been completed.
  NSLog(@"paymentQueue %@ removedTransactions %@", queue, transactions);
}


- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
  //This method is called after all restorable transactions have been processed by the payment queue. Your application is not required to do anything in this method.
  NSLog(@"paymentQueue %@ restoreCompletedTransactionsFinished", queue);
  if (!self.fullVersion) {
    [[[UIAlertView alloc] initWithTitle:@"Restore error" message:@"We can't find a record of your previous purchase" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
  }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
  [[[UIAlertView alloc] initWithTitle:@"Restore error" message:[NSString stringWithFormat:@"%@", [error localizedDescription]] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
  
  for (SKPaymentTransaction *transaction in transactions) {
    switch (transaction.transactionState) {
        
      case SKPaymentTransactionStatePurchasing:
        // show wait view here
        NSLog(@"transactionState Processing...");
        break;
        
      case SKPaymentTransactionStatePurchased:
        // unlock feature
        [self handlePurchasedFullVersionWithRestore:FLRestoreTypeNone];
        // remove wait view here
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        break;
        
      case SKPaymentTransactionStateRestored:
        // unlock feature
        [self handlePurchasedFullVersionWithRestore:FLRestoreTypeApple];
        // remove wait view here
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        break;
        
      case SKPaymentTransactionStateFailed:

        if (transaction.error.code == SKErrorPaymentCancelled) {
          NSLog(@"Payment cancelled");
        } else {
          [[[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Transaction error %d", transaction.error.code] 
                                      message:[NSString stringWithFormat:@"%@", [transaction.error localizedDescription]] delegate:nil 
                            cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
        }
        
        // remove wait view here
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        break;
        
      default:
        NSLog(@"transactionState %d    ?!?!", transaction.transactionState);
        break;
    }
  }
}

#pragma mark SKProductsRequestDelegate

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
  
  // remove wait view here if we had one

  int count = [response.products count];
  if (count > 0) {
    SKProduct* validProduct = [response.products objectAtIndex:0];
    SKPayment* payment = [SKPayment paymentWithProduct:validProduct]; 
    [[SKPaymentQueue defaultQueue] addPayment:payment]; //ask for payment
    
  } else {
    [[[UIAlertView alloc] initWithTitle:@"Not Available" message:@"No products to purchase" delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
  }
}


#pragma mark Initiate UI

// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
  
  //NSLog(@"clicked button index: %d", buttonIndex);
  switch (buttonIndex) {
      
    case 1:
      
      // user tapped YES, but we need to check if IAP is enabled or not.  
      if ([SKPaymentQueue canMakePayments]) {
        SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:FLEKSY_INAPP_ID01]];   
        request.delegate = self;   
        [request start];
        
      } else {  
        
        [[[UIAlertView alloc]  
          initWithTitle:@"Prohibited"  
          message:@"Cannot make a purchase, please check if Parental Control is enabled"  
          delegate:self  
          cancelButtonTitle:nil  
          otherButtonTitles:@"OK", nil] show];
      }
      break;
      
    default:
      break;
  }
}


- (void) askUpgradeToFullVersion {
  
  if ([self isGrandfathered]) {
    [self handlePurchasedFullVersionWithRestore:FLRestoreTypeGrandfathered];
    return;
  }
  
  UIAlertView* askToPurchase = [[UIAlertView alloc] initWithTitle:@"Unlock Fleksy to use for everyday tasks"
                                                          message:@"The full version allows you to send email, SMS, Tweets, copy your text into any application and more, would you like to upgrade?"
                                                         delegate:self
                                                cancelButtonTitle:@"Not now"
                                                otherButtonTitles:@"Yes", nil];
  askToPurchase.delegate = self;
  [askToPurchase show];
}


@synthesize previousRuns;

@end
