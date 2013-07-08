//
//  ABContactsHelper+EmailSearch.h
//  FLAddressBook
//
//  Created by Vince Mansel on 7/2/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#import "ABContactsHelper.h"

@interface ABContactsHelper (EmailSearch)

+ (NSArray *) contactsMatchingEmail: (NSString *) emailAddress;

@end
