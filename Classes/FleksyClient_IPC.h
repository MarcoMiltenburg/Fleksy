//
//  FleksyClient.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 20/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#if FLEKSY_USE_SOCKETS

#import "FLSocketsCommon.h"
#import "FastSocket.h"
#import "FleksyClient.h"
#import "FLUserDictionary.h"

@interface FleksyClient_IPC : NSObject<FLUserDictionaryChangeListener> {
  FleksyClient* client;
  BOOL hasBeenConnected;
  FLUserDictionary* theUserDictionary;
}

- (id) initWithServerAddress:(NSString*) serverAddress serverPort:(NSString*) serverPort;

- (void) loadData;

- (FLResponse*) getCandidatesForRequest:(FLRequest*) request;

@property (readonly, getter = theUserDictionary) FLUserDictionary* userDictionary;

@end

#endif