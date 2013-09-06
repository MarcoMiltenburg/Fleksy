//
//  FLSignatureViewController.h
//  iFleksy
//
//  Created by Vince Mansel on 8/26/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FLSignatureVCDelegate <NSObject>

- (void)dismissSignatureVC;

@end

@interface FLSignatureViewController : UIViewController

- (id)initWithSignature:(NSString *)aSignature;

@property (strong, nonatomic) NSString *signature;
@property (assign, nonatomic) id<FLSignatureVCDelegate> signatureDelegate;

@end

/**
 * @notification FleksySignatureWillUpdateNotification, FleksySignatureDidUpdateNotification, FleksySignatureKey
 *
 */

extern NSString * const FleksySignatureWillUpdateNotification;
extern NSString * const FleksySignatureDidUpdateNotification;
extern NSString * const FleksySignatureKey;

