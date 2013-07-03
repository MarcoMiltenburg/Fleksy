//
//  FLFavoritesTableViewController.m
//  FLAddressBook
//
//  Created by Vince Mansel on 7/1/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#import "FLFavoritesTableViewController.h"
#import "ABWrappers.h"
#import "ABContactsHelper+EmailSearch.h"

@interface FLFavoritesTableViewController ()<ABPersonViewControllerDelegate, ABUnknownPersonViewControllerDelegate>

@property (nonatomic, strong) NSIndexPath *currentIndexPath;
@property (nonatomic, strong) NSString *currentCellString;

@end

NSString * const FleksyFavoritesWillUpdateNotification = @"FleksyFavoritesWillUpdateNotification";
NSString * const FleksyFavoritesDidUpdateNotification  = @"FleksyFavoritesDidUpdateNotification";
NSString * const FleksyFavoritesKey                    = @"FleksyFavoritesKey";

NSString *const kDenied = @"Access to address book is denied.\nYou can authorize access in Privacy Settings.";
NSString *const kRestricted = @"Access to address book is restricted";

ABAddressBookRef addressBook;

@implementation FLFavoritesTableViewController

@synthesize favorites = _favorites;
@synthesize propertyType = _propertyType;

- (void)setFavorites:(NSMutableArray *)favorites {
    _favorites = favorites;
}

- (id)initWithStyle:(UITableViewStyle)style withMode:(FL_FavoritesTVC_Mode)aMode
{
  self = [super initWithStyle:style];
  if (self) {
    _operatingMode = aMode;
    [FLFavoritesTableViewController checkAddressBookAuthorization];
  }
  return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (self) {
    _operatingMode = FL_FavoritesTVC_Mode_Operate;
    _operatingMode = FL_FavoritesTVC_Mode_Operate;
    _propertyType = FL_PropertyType_EmailAndPhone;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Uncomment the following line to preserve selection between presentations.
  // self.clearsSelectionOnViewWillAppear = NO;
  
  if (self.operatingMode == FL_FavoritesTVC_Mode_Settings) {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addFavorite:)];
    
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *editButton = self.editButtonItem;
    
    [self.navigationController setToolbarHidden:NO];
    
    [self setToolbarItems:[NSArray arrayWithObjects:flexSpace, editButton, nil]];

  }
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelled:)];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - Navigation Controller Action Method

- (void)addFavorite:(id)sender {
  [FLFavoritesTableViewController checkAddressBookAuthorization];
  if (self.propertyType == FL_PropertyType_EmailAddress) {
    //[self showPickerEmail:sender];
  }
  else if (self.propertyType == FL_PropertyType_PhoneNumber) {
    //[self showPickerPhone:sender];
  }
  else if (self.propertyType == FL_PropertyType_EmailAndPhone) {
    [self showPickerEmailAndPhone:sender];
  }
  else {
    NSLog(@"Error Property type not set or incorrect");
    assert(0);
  }
}

- (void)cancelled:(id)sender {
  
  if ([self.favoritesDelegate respondsToSelector:@selector(dismissFavoritesTVC)]) {
    [self.favoritesDelegate dismissFavoritesTVC];
  }
  else {
    NSLog(@"Error: Delegate not set");
    assert(0);
  }
}

#pragma mark - ABPeoplePickerNavigationController Drivers

- (void) showPickerEmailAndPhone:(id)sender {
  ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
  picker.peoplePickerDelegate = self;
  
  [picker setDisplayedProperties: [NSArray arrayWithObjects:@(kABPersonEmailProperty), @(kABPersonPhoneProperty), nil]];
  picker.navigationBar.topItem.prompt = @"Choose contact to add to Fleksy favorites";
  
  [self presentViewController:picker animated:YES completion:nil];
}

//- (void)showPickerPhone:(id)sender {
//  
//  ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
//  picker.peoplePickerDelegate = self;
//  picker.navigationBar.topItem.prompt = @"Choose contact to add to phone favorites";
//  
//  [picker setDisplayedProperties: [NSArray arrayWithObject:@(kABPersonPhoneProperty)]];
//  
//  [self presentViewController:picker animated:YES completion:NULL];
//}
//
//
//- (void)showPickerEmail:(id)sender {
//  ABPeoplePickerNavigationController *picker = [[ABPeoplePickerNavigationController alloc] init];
//  picker.peoplePickerDelegate = self;
//  picker.navigationBar.topItem.prompt = @"Choose contact to add to email favorites";
//  
//  [picker setDisplayedProperties: [NSArray arrayWithObject:@(kABPersonEmailProperty)]];
//  
//  [self presentViewController:picker animated:YES completion:NULL];
//}

#pragma mark - ABPeoplePickerNavigationControllerDelegate Methods

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker {
  [self dismissViewControllerAnimated:YES completion:NULL];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person {
  //[self displayPerson:person];
  //[self dismissViewControllerAnimated:YES completion:NULL];
  
  return YES;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier {
  
  // Guaranteed to only be working with e-mail and phone here
  [self dismissViewControllerAnimated:YES completion:nil];
  
  NSMutableString *favString = [NSMutableString string];
  NSString *propertyString;
  
  NSString *firstName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
  NSString *lastName = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonLastNameProperty);
  
  [favString appendString:firstName];
  
  if (lastName) {
    [favString appendString:@"_"];
    [favString appendString:lastName];
  }
  
  [favString appendString:@":"];
  
  NSArray *array = [ABContact arrayForProperty:property inRecord:person];
  propertyString = (NSString *)[array objectAtIndex:identifier];
  [favString appendString:propertyString];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksyFavoritesWillUpdateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self.favorites copy] forKey:FleksyFavoritesKey]];
  
   if (property == kABPersonEmailProperty) {
    [self.favorites addObject:favString];
  }
  else if (property == kABPersonPhoneProperty) {
    [self.favorites addObject:favString];
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksyFavoritesDidUpdateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self.favorites copy] forKey:FleksyFavoritesKey]];

  // This favorite is added to the end of the tableView.
  // Scroll and highlight it.
  [self.tableView reloadData];
  
  self.currentIndexPath = [NSIndexPath indexPathForRow:[self.favorites count]-1 inSection:0];
  //UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.currentIndexPath];
  self.currentCellString = [self.favorites lastObject];
  
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:self.currentIndexPath] withRowAnimation:UITableViewRowAnimationNone];
  [self.tableView selectRowAtIndexPath:self.currentIndexPath animated:NO scrollPosition:UITableViewScrollPositionBottom];
  //[self.tableView scrollToRowAtIndexPath:self.currentIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
  
  return NO;
}

//- (void)displayPerson:(ABRecordRef)person {
//  NSLog(@"Display a person: %d", (int)person);
//
//  NSString *name = (__bridge_transfer NSString*)ABRecordCopyValue(person, kABPersonFirstNameProperty);
//  //self.firstName.text = name;
//
//  NSString *phone = nil;
//  ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
//
//  if (ABMultiValueGetCount(phoneNumbers) > 0) {
//    phone = (__bridge_transfer NSString*)ABMultiValueCopyValueAtIndex(phoneNumbers, 0);
//  }
//  else {
//    phone = @"[None]";
//  }
//
//  //self.phoneNumber.text = phone;
//  CFRelease(phoneNumbers);
//}


#pragma mark - Address Book Authorization Utilities

+ (void)checkAddressBookAuthorization {
  CFErrorRef error = NULL;
  
  switch (ABAddressBookGetAuthorizationStatus()){
    case kABAuthorizationStatusAuthorized:{
      addressBook = ABAddressBookCreateWithOptions(NULL, &error);
      /* Do your work and once you are finished ... */
      if (addressBook != NULL){
        CFRelease(addressBook);
      }
      break;
    }
    case kABAuthorizationStatusDenied:{
      [[self class] displayMessage:kDenied];
      break;
    }
    case kABAuthorizationStatusNotDetermined:{
      addressBook = ABAddressBookCreateWithOptions(NULL, &error);
      ABAddressBookRequestAccessWithCompletion
      (addressBook, ^(bool granted, CFErrorRef error) {
        if (granted){
          NSLog(@"Access was granted");
        } else {
          NSLog(@"Access was not granted");
        }
        if (addressBook != NULL){
          CFRelease(addressBook);
        }
      });
      break;
    }
    case kABAuthorizationStatusRestricted:{
      [[self class] displayMessage:kRestricted];
      break;
    }
  }
}

+ (void) displayMessage:(NSString *)paramMessage{
  [[[UIAlertView alloc] initWithTitle:nil
                              message:paramMessage
                             delegate:nil
                    cancelButtonTitle:@"OK"
                    otherButtonTitles:nil] show];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  // Return the number of sections.
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  NSInteger numberOfRows = 0;
  
  if (self.propertyType == FL_PropertyType_EmailAndPhone) {
    numberOfRows = [self.favorites count];
  }
  else {
    NSLog(@"Error Property type not set or incorrect");
    assert(0);
  }
  return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"FavoritesCell";
  
  if (self.operatingMode == FL_FavoritesTVC_Mode_Settings) {
    CellIdentifier = @"FavoritesSetupCell";
  }
  
  //FYI: This is iOS 6+ only. Need to deal with iOS 5 devices also if used.
  //[tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CellIdentifier];
  //UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  
  if (cell == nil)
	{
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];

		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    if (self.operatingMode == FL_FavoritesTVC_Mode_Operate) {
      cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
  }
  
  NSString *favString;
  
  if (self.propertyType == FL_PropertyType_EmailAndPhone) {
    favString = [self.favorites objectAtIndex:[indexPath row]];
  }
  else {
    NSLog(@"Error Property type not set or incorrect");
    assert(0);
  }
  //Check the favString for a colon. If a colon, break into person's name and actual property item (email or phone)
  NSArray* components = [favString componentsSeparatedByString:@":"];
  NSArray* nameComponents = [components[0] componentsSeparatedByString:@"_"];
  
  if ([nameComponents count] == 2) {
    cell.textLabel.text = [self cellTextFromString:[NSString stringWithFormat:@"%@ %@", nameComponents[0], nameComponents[1]]];
  }
  else {
    cell.textLabel.text = nameComponents[0];
  }
  
  if ([components count] == 2) {
    [cell.detailTextLabel setText:[components lastObject]];
  }
  
  return cell;
}

- (NSString *)cellTextFromString:(NSString *)favString {
  return favString;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Return NO if you do not want the specified item to be editable.
  if (self.operatingMode == FL_FavoritesTVC_Mode_Operate) {
    return NO;
  }
  return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.operatingMode == FL_FavoritesTVC_Mode_Operate) {
    return;
  }
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    // Delete the row from the data source
    [[NSNotificationCenter defaultCenter] postNotificationName:FleksyFavoritesWillUpdateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self.favorites copy] forKey:FleksyFavoritesKey]];
    [self.favorites removeObjectAtIndex:indexPath.row];
    [[NSNotificationCenter defaultCenter] postNotificationName:FleksyFavoritesDidUpdateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self.favorites copy] forKey:FleksyFavoritesKey]];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];

  }
  else if (editingStyle == UITableViewCellEditingStyleInsert) {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
  }
}


/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  // Handle user choice for individual favorite inspection or replinishment
  
  if (self.operatingMode == FL_FavoritesTVC_Mode_Settings) {
    
    [self tableView:tableView setupFavoriteAtIndexPath:indexPath];
    
  }
  else {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // The string is or is not replinished: i.e. Joe_Blow:444-341-1112 or 444-341-1112, so first examine from the datasource
    
    NSString *favString = [self.favorites objectAtIndex:indexPath.row];

    if ([favString rangeOfString:@":"].location != NSNotFound) { // Replinished
      favString = cell.detailTextLabel.text;
    }
    
    // Handle sending a text or an email
    
    [self.favoritesDelegate selectedFavorite:favString];
  }
}

#pragma mark - Table View Delegate Helpers

- (void)tableView:(UITableView *)tableView setupFavoriteAtIndexPath:(NSIndexPath *)indexPath {
  NSString *selectedCellString = [self.favorites objectAtIndex:indexPath.row];
  self.currentCellString = selectedCellString;
  self.currentIndexPath = indexPath;
  
  ABContact *contact;
  
  NSArray* components = [selectedCellString componentsSeparatedByString:@":"];
  
  if ([components count] > 1) {
    // Joe_Blow or Joe
    
    NSArray* nameComponents = [components[0] componentsSeparatedByString:@"_"];
    
    
    if ([nameComponents count] == 2) {
      contact = [[ABContactsHelper contactsMatchingName:nameComponents[0] andName:nameComponents[1]] lastObject];
    }
    else {
      contact = [[ABContactsHelper contactsMatchingName:nameComponents[0]] lastObject];
    }
    
    ABPersonViewController *pvc = [[ABPersonViewController alloc] init];
    pvc.displayedPerson = contact.record;
    pvc.personViewDelegate = self;
    if (self.operatingMode == FL_FavoritesTVC_Mode_Settings) {
      pvc.allowsEditing = YES; // optional editing
    }
    else {
      pvc.allowsEditing = NO;
    }
    [self.navigationController pushViewController:pvc animated:YES];
  }
  else {
    // This allows backwards compatibility with older Fleksy storage string.
    // First search for a possible contact with the property. If not found, attempt to associate:
    
    ABUnknownPersonViewController *upvc = [[ABUnknownPersonViewController alloc] init];
    upvc.unknownPersonViewDelegate = self;
    
    NSString *message;
    
    if ([selectedCellString rangeOfString:@"@"].location != NSNotFound) {
      contact = [[ABContactsHelper contactsMatchingEmail:selectedCellString] lastObject];
      
      if (contact) {
        //Fix up the Fleksy favorite with a name
        
        [self replinishFavoritesWithContact:contact selectedCellString:selectedCellString atIndexPath:indexPath];
      }
      else {
        // This email does not have a know contact
        contact = [ABContact contact];
        [contact addEmailItem:selectedCellString withLabel:(__bridge CFStringRef)@"email"];
        message = @"Who's email is this?";
        [self pushUPVC:upvc contact:contact message:message alternateName:selectedCellString];
      }
      
    }
    else {
      contact = [[ABContactsHelper contactsMatchingPhone:selectedCellString] lastObject];
      
      if (contact) {
        //Fix up the Fleksy favorite with a name
        
        [self replinishFavoritesWithContact:contact selectedCellString:selectedCellString atIndexPath:indexPath];
      }
      else {
        // This phone does not have a know contact
        
        contact = [ABContact contact];
        [contact addPhoneItem:selectedCellString withLabel:(__bridge CFStringRef)@"phone"];
        message = @"Who's phone number is this?";
        [self pushUPVC:upvc contact:contact message:message alternateName:selectedCellString];
      }
    }
  }
} //End:- (void)tableView:(UITableView *)tableView setupFavoriteAtIndexPath:(NSIndexPath *)indexPath

- (void)replinishFavoritesWithContact:(ABContact *)contact selectedCellString:(NSString *)selectedCellString atIndexPath:(NSIndexPath *)indexPath {
  NSString *firstName = contact.firstname;
  NSString *lastName = contact.lastname;
  
  NSMutableString *replacementFavString = [firstName mutableCopy];
  if (lastName) {
    [replacementFavString appendString:@"_"];
    [replacementFavString appendString:lastName];
  }
  [replacementFavString appendString:@":"];
  [replacementFavString appendString:selectedCellString];
  
  
  //TODO: This simply changes the text of the Cell and sets the favorites. The user is prompted by animation but may be surprised at quickness.
  //IDEA: How about just pre-converted all propertyTypes ahead before user even gets to this point.
  
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksyFavoritesWillUpdateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self.favorites copy] forKey:FleksyFavoritesKey]];
  [self.favorites replaceObjectAtIndex:indexPath.row withObject:replacementFavString];
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksyFavoritesDidUpdateNotification object:self userInfo:[NSDictionary dictionaryWithObject:[self.favorites copy] forKey:FleksyFavoritesKey]];
  
  [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)pushUPVC:(ABUnknownPersonViewController *)upvc contact:(ABContact *)contact message:(NSString *)message alternateName:(NSString *)selectedCellString {
  upvc.allowsActions = NO;
  
  if (self.operatingMode == FL_FavoritesTVC_Mode_Settings) {
    upvc.allowsAddingToAddressBook = YES;
  }
  else {
    upvc.allowsAddingToAddressBook = NO;
  }
  upvc.message = message;
  upvc.alternateName = selectedCellString;
  upvc.displayedPerson = contact.record;
  
  [self.navigationController pushViewController:upvc animated:YES];
}

// TODO: Handle when a user selects a favorite, then deassociates(deletes) the property from the name.
//  - The favorite should be deleted. Or should the property just go back into the list. If no action, the list goes stale and may not be what the user expects.

// FYI: Do not Handle when a user has replinished contacts on one device, and Fleksy favoritescontacts are iCloud transferred to another device (via Settings)
// fred_jones:555-555-5555 will find fred_jones but will not edit address book with propertyType (assume address book contacts are iCloud connected)

// TODO: If Jane_Blow (in Favorites) shares a number with Joe_Blow, and Joe_Blow is the AB, when the Jane_Blow is selected, the name is not found in address book.

// TODO: If user makes a mistake and replinishes/associates a property with a person, they can delete the entry from the ABContact form, then delete the favorite.
//  - They will lose the property and have to re-enter.

// TODO: If user creates duplicate entry in favorite (same name, same property), the user is reqiured to manually delete one of the entries.

// TODO: Provide a setting to allow user to sort entries, or manually priortize (re-arrange)

#pragma mark - ABPersonViewControllerDelegate Method

- (BOOL)personViewController: (ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
  // Reveal the item that was selected
  if ([ABContact propertyIsMultiValue:property])
  {
    NSArray *array = [ABContact arrayForProperty:property inRecord:person];
    NSLog(@"%@", [array objectAtIndex:identifierForValue]);
  }
  else
  {
    id object = [ABContact objectForProperty:property inRecord:person];
    NSLog(@"%@", [object description]);
  }
  
  return NO;
}

#pragma mark ABUnknownPersonViewControllerDelegate Method

- (void)unknownPersonViewController:(ABUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
  // Handle cancel events
  if (!person) return;
  
//  ABPersonViewController *abpvc = [[ABPersonViewController alloc] init];
//  abpvc.displayedPerson = person;
//  abpvc.allowsEditing = YES;
//  abpvc.personViewDelegate = self;
  
  [self.navigationController popViewControllerAnimated:YES];
  //[unknownPersonView dismissViewControllerAnimated:YES completion:NULL];
  [self replinishFavoritesWithContact:[ABContact contactWithRecord:person] selectedCellString:self.currentCellString atIndexPath:self.currentIndexPath];
  
  //[self.navigationController pushViewController:abpvc animated:YES];
}

- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController *)personViewController
shouldPerformDefaultActionForPerson:(ABRecordRef)person
                           property:(ABPropertyID)property
                         identifier:(ABMultiValueIdentifier)identifier
{
  // If this is YES, will attempt to make phone call or send email.
  // TODO: Can send this to delegate as 
  return NO;
}

@end
