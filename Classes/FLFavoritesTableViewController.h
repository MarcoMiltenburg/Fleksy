//
//  FLFavoritesTableViewController.h
//  FLAddressBook
//
//  Created by Vince Mansel on 7/1/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBookUI/AddressBookUI.h>

typedef enum {
  FL_PropertyType_UNKNOWN,
  FL_PropertyType_EmailAddress,
  FL_PropertyType_PhoneNumber,
  FL_PropertyType_EmailAndPhone
  
} FL_PropertyType;

typedef enum {
  FL_FavoritesTVC_Mode_Settings,
  FL_FavoritesTVC_Mode_Operate
} FL_FavoritesTVC_Mode ;

@protocol FLFavoritesTVCDelegateProtocol <NSObject>

- (void)dismissFavoritesTVC;
- (void)selectedFavorite:(NSString *)favoriteString;

@end

@interface FLFavoritesTableViewController : UITableViewController <ABPeoplePickerNavigationControllerDelegate>
{
  NSMutableArray *_favorites;
  FL_PropertyType _propertyType;
}

@property (assign, nonatomic) id<FLFavoritesTVCDelegateProtocol> favoritesDelegate;
@property (strong, nonatomic) NSMutableArray *favorites;
@property (nonatomic) FL_PropertyType propertyType;
@property (nonatomic) FL_FavoritesTVC_Mode operatingMode;


- (id)initWithStyle:(UITableViewStyle)style withMode:(FL_FavoritesTVC_Mode)mode;
+ (void)checkAddressBookAuthorization;

/**
 * @notification FleksyFavoritesWillUpdateNotification, FleksyFavoritesDidUpdateNotification
 *
 */

extern NSString * const FleksyFavoritesWillUpdateNotification;
extern NSString * const FleksyFavoritesDidUpdateNotification;
extern NSString * const FleksyFavoritesKey;


@end
