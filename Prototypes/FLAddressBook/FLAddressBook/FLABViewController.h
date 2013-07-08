//
//  FLABViewController.h
//  FLAddressBook
//
//  Created by Vince Mansel on 6/30/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLFavoritesTableViewController.h"

@interface FLABViewController : UIViewController <FLFavoritesTVCDelegateProtocol>

- (IBAction)showPicker:(id)sender;
//- (IBAction)showPickerPhone:(id)sender;
//- (IBAction)showPickerEmail:(id)sender;
- (IBAction)menuSelector:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *firstName;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumber;
@property (weak, nonatomic) IBOutlet UILabel *emailAddress;

@end
