//
//  FleksyClient.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 20/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#if FLEKSY_USE_SOCKETS

#include "FLSocketsCommon.h"
#include "FastSocket.h"

class FleksyClient {
private:
  FastSocket* socket;
  bool hasBeenConnected;
  void connect();
  FLResponse* _getCandidatesForRequest(FLRequest* request);
  
public:
  FleksyClient(const char* serverAddress, const char* serverPort);
  FLResponse* getCandidatesForRequest(FLRequest* request);
};

#endif