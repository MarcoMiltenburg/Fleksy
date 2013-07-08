//
//  ABContactsHelper+EmailSearch.m
//  FLAddressBook
//
//  Created by Vince Mansel on 7/2/13.
//  Copyright (c) 2013 Syntellia. All rights reserved.
//

#import "ABContactsHelper+EmailSearch.h"

@implementation ABContactsHelper (EmailSearch)

+ (NSArray *) contactsMatchingEmail: (NSString *) emailAddress
{
  NSPredicate *pred;
  NSArray *contacts = [ABContactsHelper contacts];
  pred = [NSPredicate predicateWithFormat:@"emailaddresses contains[cd] %@", emailAddress];
  return [contacts filteredArrayUsingPredicate:pred];
}


@end
