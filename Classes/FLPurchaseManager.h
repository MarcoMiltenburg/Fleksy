//
//  FLPurchaseManager.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 7/23/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#define FLEKSY_PREVIOUS_RUNS @"FLEKSY_PREVIOUS_RUNS"


@protocol FLPurchaseListener <NSObject>
- (void) switchToFullVersion;
@end


@interface FLPurchaseManager : NSObject<SKPaymentTransactionObserver, SKRequestDelegate, SKProductsRequestDelegate> {
  
  id <FLPurchaseListener> listener;
  
  int previousRuns;
}

- (id) initWithListener:(id<FLPurchaseListener>) _listener;
- (void) checkRestoreToFullVersion;
- (void) askUpgradeToFullVersion;
- (void) incrementRuns;
- (void) resetRuns;

@property (readwrite) BOOL fullVersion;
@property (readonly) int previousRuns;

@end
