//
//  MyTextChecker.h
//  iFleksy
//
//  Created by Kosta Eleftheriou on 2/25/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#include <PatternRecognizer/Structures.h>
#include <iostream>
#include <queue>
#include <pthread.h>

using namespace std;

class MyTextChecker {
  
private:
  
  UITextChecker* checker;
  NSString* language;
  
  // MUTEXES
  // simple print mutex
  pthread_mutex_t print_mutex = PTHREAD_MUTEX_INITIALIZER;
  // to guard between prepareResultsAsync (consumer) and getNextRequest (producer)
  pthread_mutex_t request_mutex = PTHREAD_MUTEX_INITIALIZER;
  // to guard between peekResults (consumer) and producerThread (producer)
  pthread_mutex_t processing_mutex = PTHREAD_MUTEX_INITIALIZER;
  
  // CONDITIONS
  // signals to producer that a request is available
  pthread_cond_t request_available = PTHREAD_COND_INITIALIZER;
  // signals to consumer that results are ready
  pthread_cond_t data_available = PTHREAD_COND_INITIALIZER;
  
  
  pthread_t producer_thread; // background thread to perform the heavy task in producerThread()
  queue<FLString> requestedTokenIDs; // FIFO requests
  FLString lastProcessedTokenID; // marked by producer for consumer to ensure desired results
  vector<FLString> lastResults;
  
  void log(const char* format, ...);
  
  void getNextRequest(FLString& result); // for producer to fetch next request or block until there is one
  static void* producerThread(void* arg); //wrapper for instance method
  void producerThread(); // where the processing is done
  
  bool appleKnowsWord(NSString* string);
  NSArray* getAppleCandidatesForString(NSString* string);
  
public:
  MyTextChecker();
  
  // this is guaranteed not to block. Client can send multiple requests and they will all be processed in FIFO order
  void prepareResultsAsync(FLString tokenID);
  
  // this may block until results for this tokenID are calculated
  void peekResults(vector<FLString>& result, FLString tokenID);
};
