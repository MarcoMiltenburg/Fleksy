//
//  FleksyClient_IPC.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 20/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//
#if FLEKSY_USE_SOCKETS

#import "FleksyClient_IPC.h"

@implementation FleksyClient_IPC

- (id) initWithServerAddress:(NSString*) serverAddress serverPort:(NSString*) serverPort {
  if (self = [super init]) {
    client = new FleksyClient(serverAddress.UTF8String, serverPort.UTF8String);
  }
  return self;
}

- (void) loadData {
  NSLog(@"FleksyClient_IPC loadData nop, load will be done on server side");
}


/*
- (FleksyResponse*) decodeResponseFrom:(FLResponse*) response {
  double startTime = CFAbsoluteTimeGetCurrent();
  FleksyResponse* result = [[FleksyResponse alloc] init];
  
  result->processingTimeApple = response->processingTimeApple;
  result->processingTimeFleksyPass1 = response->processingTimeFleksyPass1;
  result->processingTimeFleksyPass2 = response->processingTimeFleksyPass2;
  result->totalServerTime = response->totalServerTime;
  result->clientRequestTime = response->clientRequestTime;
  result->serverReceivedTime = response->serverReceivedTime;
  result->serverReplyTime = response->serverReplyTime;
  
  NSMutableArray* candidates = [[NSMutableArray alloc] init];
  
  long p = (long) response;
  p += sizeof(FLResponse);
  
  for (int i = 0; i < response->candidatesN; i++) {
    FLResponseEntry* response_candidate = (FLResponseEntry*) p;
    CandidateEntry* candidateEntry = [[CandidateEntry alloc] init];
    candidateEntry->frequency = response_candidate->frequency;
    candidateEntry->groupFrequencyRank = response_candidate->groupFrequencyRank;
    candidateEntry->frequencyRank = response_candidate->frequencyRank;
    candidateEntry->apple = response_candidate->apple;
    candidateEntry->fleksy = response_candidate->fleksy;
    candidateEntry->euclideanDistance = response_candidate->euclideanDistance;
    candidateEntry->shapeScore = response_candidate->shapeScore;
    candidateEntry->stringEditDistance = response_candidate->stringEditDistance;
    candidateEntry->letters = [[NSString alloc] initWithCString:response_candidate->letters encoding:NSUTF8StringEncoding];
    //[candidateEntry->letters autorelease];
    //NSLog(@"LETTERS: '%s' '%@'", response_candidate->letters, candidateEntry->letters);
    [candidates addObject:candidateEntry];
    p += sizeof(FLResponseEntry) + myalign(response_candidate->lettersN);
  }
  
  result->candidates = candidates;

  //NSLog(@"decode response took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
  return result;
}*/



- (FLAddWordResult) addedUserWord:(NSString*) word frequency:(float) frequency {
  
}


- (bool) removedUserWord:(NSString*) word {
  
}



- (FLResponse*) getCandidatesForRequest:(FLRequest*) request {

  FLResponse* response = client->getCandidatesForRequest(request);
  
  //FleksyResponse* result = [self decodeResponseFrom:response];
  
  
  //FREQUENCY SORT
  //  if (2 <= [points count] && [points count] <= 5) {
  //    startTime = CFAbsoluteTimeGetCurrent();
  //    [result->candidates sortUsingComparator: ^NSComparisonResult(CandidateEntry* e1, CandidateEntry* e2){
  //      //NSLog(@"e1: %@:%.0f, e2: %@:%.0f", e1->letters, e1->frequency, e2->letters, e2->frequency);
  //      return [[NSNumber numberWithFloat:e2->frequency] compare:[NSNumber numberWithFloat:e1->frequency]];
  //    }];
  //    NSLog(@"sort response took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
  //  }////////////////////
  
  
  //IPC overhead is now about 1.6 msec on iPhone4, 0.9 msec on iPhone4S. "sub-millisecond IPC"
  //NSLog(@"outer TOTAL: %.6f, of which serverTime: %.6f, so IPC overhead was at most %.6f. fleksy1: %.6f, fleksy2: %.6f",
  //      receiveTime - startTime, result->totalServerTime, receiveTime - startTime - result->totalServerTime, result->processingTimeFleksyPass1, result->processingTimeFleksyPass2);
  return response;
}


/*
- (FleksyResponse*) unarchive:(NSData*) output receiveTime:(double) receiveTime {
  
  //NSLog(@"unarchive, data length = %d", [output length]);
  
  FleksyResponse* result;
  
  @try {
    //result = [NSKeyedUnarchiver unarchiveObjectWithData:output];
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:output];
    result = [unarchiver decodeObjectForKey:@"root"];
    [unarchiver finishDecoding];
    
    double roundtrip = receiveTime - result->clientRequestTime;
    double clientServerDelay = result->serverReceivedTime - result->clientRequestTime;
    double serverClientDelay = receiveTime - result->serverReplyTime;
    double serverProcessingDelay = result->serverReplyTime - result->serverReceivedTime;
    double networkDelay = serverClientDelay + clientServerDelay;
    NSLogGreenBackground(@"getCandidatesForPoints roundtrip: %.6f (network: %.6f, processing: %.6f), client->server: %.6f, server->client: %.6f, candidates: %@",
                         roundtrip, networkDelay, serverProcessingDelay, clientServerDelay, serverClientDelay, result->candidates);
  }
  @catch (NSException *exception) {
    NSLog(@"CLIENT ERROR: %@", exception);
    result = nil;
  }
  @finally {
    
  }
  
  if (!result) {
    NSLog(@"CLIENT ERROR, nil result");
  }
  
  return result;
}
 
 
- (void) didReceiveData:(NSData *)data {
    
  double receiveTime = CFAbsoluteTimeGetCurrent();
  data = [NSData dataWithBytes:[data bytes] length:[data length]-10];
  FleksyResponse* result = [self unarchive:data receiveTime:receiveTime];
}*/

@end

#endif