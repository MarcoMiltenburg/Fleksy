//
//  FleksyClient_NOIPC.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/27/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SystemsIntegrator.h"
#import "FLUserDictionary.h"

@interface FleksyClient_NOIPC : NSObject<FLUserDictionaryChangeListener> {
  SystemsIntegrator* _systemsIntegrator;
  FLUserDictionary* _userDictionary;
  //NSString* languagePack;
}

+ (void) loadData:(SystemsIntegrator*) systemsIntegrator userDictionary:(FLUserDictionary*) userDictionary languagePack:(NSString*) languagePack;

- (FLResponse*) getCandidatesForRequest:(FLRequest*) request;

@property (readonly, getter = theUserDictionary) FLUserDictionary* userDictionary;
@property (readonly) SystemsIntegrator* systemsIntegrator;

@end
