//
//  MyTextChecker.mm
//  iFleksy
//
//  Created by Kosta Eleftheriou on 2/25/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "MyTextChecker.h"
#include <PatternRecognizer/Platform.h>
#include "StringConversion.h"
#include "TimeFunctions.h"

void dsdsaads();


void MyTextChecker::log(const char* format, ...) {
  pthread_mutex_lock(&print_mutex);
  va_list args;
  va_start( args, format );
  char mybuffer[1024];
  vsnprintf(mybuffer, sizeof(mybuffer), format, args );
  va_end( args );
  LOGI("MyTextChecker::%s\n", mybuffer);
  pthread_mutex_unlock(&print_mutex);
}

//disable logging
//#define log(format, ...)


MyTextChecker::MyTextChecker() {
  
  checker = [[UITextChecker alloc] init];
  language = [[UITextChecker availableLanguages] objectAtIndex:0];
  language = @"en_US";
  NSLog(@"UITextChecker using language %@", language);
  
  pthread_create(&producer_thread, NULL, MyTextChecker::producerThread, this);
}


#pragma mark PRODUCER SIDE

// this will block until we get a request
void MyTextChecker::getNextRequest(FLString& result) {
  
  pthread_mutex_lock(&request_mutex);
  while (!requestedTokenIDs.size()) {
    log("producerThread: waiting for request...");
    //Note that the pthread_cond_wait routine will automatically and atomically unlock mutex while it waits.
    pthread_cond_wait(&request_available, &request_mutex);
  }
  
  result = requestedTokenIDs.front();
  requestedTokenIDs.pop();
  
  //log("Found request %d", result);
  
  pthread_mutex_unlock(&request_mutex);
}


void MyTextChecker::producerThread() {
  
  log("producerThread thread start, this: %p", this);
  
  double totalDt = 0;
  int totalRequests = 0;
  
  while (1) {
    
    FLString tokenToProcess;
    getNextRequest(tokenToProcess);
    
    // now produce while processing_mutex is locked
    pthread_mutex_lock(&processing_mutex);
    
    double startTime = fl_get_time();
    lastResults.clear();
    
    // do the actual work here
    NSArray* temp = this->getAppleCandidatesForString(FLStringToNSString(tokenToProcess));
    for (NSString* s : temp) {
      lastResults.push_back(NSStringToFLString(s));
    }
    
    //usleep(200 * 1000); //for testing / debugging
    double dt = fl_get_time() - startTime;
    
    // mark for consumer to know and check
    lastProcessedTokenID = tokenToProcess;
    
    totalRequests++;
    totalDt += dt;
    
    log("Finished producing %s in %.6f (average: %.6f), signalling...", lastProcessedTokenID.c_str(), dt, totalDt / totalRequests);
    pthread_cond_signal(&data_available);
    
    pthread_mutex_unlock(&processing_mutex);
  }
  
  pthread_exit(NULL);
}


// simple static wrapper
void* MyTextChecker::producerThread(void* _z) {
  MyTextChecker* z = (MyTextChecker*) _z;
  //z->log("static MyTextChecker::producerThread, argument: %p", _z);
  z->producerThread();
  return 0;
}


#pragma mark CONSUMER SIDE

// this will only block while producer is in getNextRequest, NOT while it is producing, so it is guaranteed not to block
void MyTextChecker::prepareResultsAsync(FLString tokenID) {
  
  pthread_mutex_lock(&request_mutex);
  ///////////////////////////////////
  
  requestedTokenIDs.push(tokenID);
  pthread_cond_signal(&request_available);
  
  /////////////////////////////////////
  pthread_mutex_unlock(&request_mutex);
}



// this will block until producer has processed our requested token_id
void MyTextChecker::peekResults(vector<FLString> &result, FLString tokenID) {
  
  pthread_mutex_lock(&processing_mutex);
  
  log("peekResults lastProcessedWordID: %s, tokenID requested: %s", lastProcessedTokenID.c_str(), tokenID.c_str());
  
  while (lastProcessedTokenID != tokenID) {
    log("peek: not ready yet, will wait... (lastProcessedTokenID %s != tokenID %s)", lastProcessedTokenID.c_str(), tokenID.c_str());
    pthread_cond_wait(&data_available, &processing_mutex);
  }
  
  log("peek: results are in for requestedID %s, length = %d", tokenID.c_str(), lastResults.size());
  
  for (FLString s : lastResults) {
    result.push_back(s);
  }
  
  pthread_mutex_unlock(&processing_mutex);
}


//////////////////////////////////////////////

bool MyTextChecker::appleKnowsWord(NSString* string) {
  NSRange range = [checker rangeOfMisspelledWordInString:string
                                                   range:NSMakeRange(0, [string length])
                                              startingAt:0
                                                    wrap:NO
                                                language:language];
  return range.location == NSNotFound;
}

NSArray* MyTextChecker::getAppleCandidatesForString(NSString* string) {
  
  NSMutableArray* results = [[NSMutableArray alloc] init];
  //check if word is already valid word
  //TODO move this out, same way we check [[FleksyUtilities sharedFleksyUtilities] isWordInDictionary:expectedWord] and
  //dont even do that check if the typed word is a valid word in any of the systems
  
  double startTime = fl_get_time();
  
  if (this->appleKnowsWord(string)) {
    [results addObject:string];
  }
  double dt1 = fl_get_time() - startTime;
  [results addObjectsFromArray:[checker guessesForWordRange:NSMakeRange(0, [string length]) inString:string language:language]];
  double dt2 = fl_get_time() - startTime;
  NSLog(@"took %.6f, %.6f", dt1, dt2);
  return results;
}



void dsdsaads() {
  

  //float processingTimeApple = 0;
  //we try to infer string from points here, so we can use transformation
  //But: then we lose Apple's key charging
  //    double startTimeApple = fl_get_time();
  //
  //    NSString* inputString = [NSString stringWithCString:currentWord_c.c_str() encoding:NSUTF8StringEncoding] ;
  //    inputString = [inputString lowercaseString]; //if this is not lowercase then UITextChecker might return the raw input as a suggestion
  //
  //    NSArray* appleCandidates = [self getAppleCandidatesForString:inputString];
  //    //NSLog(@"appleCandidates: %@", appleCandidates);
  //    processingTimeApple = fl_get_time() - startTimeApple;
  //
  //    for (NSString* appleCandidate in appleCandidates) {
  //      if ([appleCandidate rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@" -"]].length == 0) {
  //        NSString* appleCandidateCopy = [VariousUtilities onlyKeepAlphaFromString:appleCandidate];
  //        string s([appleCandidateCopy UTF8String]);
  //        [self addCandidate:&s inputString:&currentWord_c shapeScore:-1 apple:YES frequency:-1 frequencyRank:-1 groupFrequencyRank:-1 candidateList:&shapeCandidates];
  //      } else {
  //        //NSLog(@"ignoring apple suggestion %@", appleCandidate);
  //      }
  //    }
  
  
  //remove apple candidates to compare
  //[candidates removeAllObjects];
  
  //TODO if small cardinality (eg <= 4) dont sort apple results, they are better without
  //[shapeCandidates sortUsingSelector:@selector(compareEditDistance:)];
  //////////////////////
  //assert([self checkSort:shapeCandidates]);
  
  /*
   while ([candidates count] > 0) {
   CandidateEntry* entry = [candidates lastObject];
   if (entry->stringEditDistance >= 3) {
   //NSLog(@"removing bad apple: %@(%.1f) for input %@, index=%d", entry->letters, entry->stringEditDistance, test.inputString, [candidates indexOfObject:entry]);
   [candidates removeLastObject];
   } else {
   break;
   }
   }*/
  
  
  
  
  
  //dt = CFAbsoluteTimeGetCurrent() - startTime;
  
  
  /*
   if (range.location != NSNotFound) {
   NSLog(@"APPLE did NOT know word %@", currentWord);
   NSLog(@"expected: %@", expectedWord);
   for (NSString* guess in candidates) {
   NSLog(@"guess: %@", guess);
   }
   NSLog(@"Took %.6f", dt);
   }*/
  
  
  
  //    if (appleAutocorrect && [self appleKnowsWord:appleAutocorrect]) {
  //
  //      /*
  //       //need to check if apple suggestion is already included
  //       if (apple) {
  //       CandidateEntry* entry = [candidateList objectAtIndex:0];
  //       if ([entry->letters caseInsensitiveCompare:letters] == NSOrderedSame) {
  //
  //       //int i = 0;
  //       //for (CandidateEntry* e in candidateList) {
  //       //  NSLog(@"%d: %@", i++, e->letters);
  //       //}
  //
  //       NSLog(@"Skipping UITextChecker suggestion %@, already in index-0 from autocorrect", letters);
  //       return;
  //       }
  //       }*/
  //
  //      //TODO remove previous if already added with same string (appleAutocorrect)
  //
  //      [self addCandidate:appleAutocorrect inputString:inputString shapeScore:-999 apple:YES frequency:-1 frequencyRank:-1 groupFrequencyRank:-1 candidateList:shapeCandidates];
  //    }
  
}

//- (void) textChecker {
//  
//  //  string s1("McDonnells");
//  //  string s2("mcdonalds");
//  //  string s3("rosettacode");
//  //  string s4("raisethysword");
//  //  NSLog(@"aaa %.1f", OptimalStringAlignmentDistance(&s1, &s2));
//  //  NSLog(@"aaa %.1f", OptimalStringAlignmentDistance(&s3, &s4));
//  
//  
//}

