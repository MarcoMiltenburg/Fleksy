//
//  FleksyClient.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 20/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#if FLEKSY_USE_SOCKETS

#include "FleksyClient.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


FleksyClient::FleksyClient(const char* serverAddress, const char* serverPort) {
  socket = new FastSocket(serverAddress, serverPort);
  struct timeval timeout = {0, 900 * 1000}; // sec, usec
  socket->setTimeout(timeout);
  hasBeenConnected = false;
  this->connect();
}


void FleksyClient::connect() {
  
  //we need this when reconnecting to have a chance to tell server to also end its thread
  if (hasBeenConnected) {
    socket->closeSocket();
  }
  
  printf("Client %p %sconnecting...\n", this, hasBeenConnected ? "re" : "");
  if (socket->connectSocket()) {
    hasBeenConnected = true;
    printf("Client connected to %s:%s, timeout is %d usec\n", socket->getHost(), socket->getPort(), socket->getTimeout().tv_usec);
  } else {
    printf("Could not connect to server: %d\n", socket->getLastError());
    socket->closeSocket();
    //usleep(1000 * 1000);
  }
}



#define receiveBufferSize 51024

FLResponse* FleksyClient::_getCandidatesForRequest(FLRequest* request) {
  
  double startTime = time(0);
  request->requestTime = startTime;
  
  
  char receiveBuffer[receiveBufferSize];
  
  int requestSize = request->getSize();
  
  double inputCreation = time(0) - startTime;
  
  long bytesSent = socket->sendBytes(request, requestSize);
  if (bytesSent != requestSize) {
    printf("Error sending bytes, requested: %d, bytesSent: %ld, error: %d\n", requestSize, bytesSent, socket->getLastError());
    return NULL;
  }
  long bytesRead = socket->receiveBytes(receiveBuffer, receiveBufferSize);
  //TODO also assert message was received in full from contents
  if (bytesRead <= 0) {
    printf("Error reading bytes, bytesRead: %ld, error: %d\n", bytesRead, socket->getLastError());
    return NULL;
  }
  
  double receiveTime = time(0);
  
  FLResponse* result = (FLResponse*) calloc(bytesRead, 1);
  memcpy(result, receiveBuffer, bytesRead);
  
  printf("received %d results in %ld bytes\n", result->candidatesN, bytesRead);
  
  return (FLResponse*) result;
}


FLResponse* FleksyClient::getCandidatesForRequest(FLRequest* request) {
  
  FLResponse* result = this->_getCandidatesForRequest(request);
  //give it a second chance, might have lost connection due to lost sreen etc
  if (!result) {
    this->connect();
    result = this->_getCandidatesForRequest(request);
  }
  
  //still no result, will not attempt anything apart from one more reconnect in the background
//  if (!result) {
//    [self performSelectorInBackground:@selector(connect) withObject:self];
//  }
  
  return result;
}

#endif
