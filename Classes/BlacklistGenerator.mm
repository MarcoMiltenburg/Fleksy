//
//  BlacklistGenerator.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 5/24/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "BlacklistGenerator.h"
#import "FleksyUtilities.h"
#import "VariousUtilities.h"
#import "FLSocketsCommon.h"

static SystemsIntegrator* systemsIntegrator = nil;

@implementation BlacklistGenerator


- (void) findPITAwordsFor:(FLWord*) word badFrequencyLimit:(int) badFrequencyLimit suggestionsToLook:(int) suggestionsToLook blacklist:(NSMutableDictionary*) blacklist {
  
  FLRequest* request = FLRequest::FLRequestMake(word->getNPoints());
  request->debug = NO;
  
  //NSLog(@"findPITAwordsFor %@ (F:%d)", word.printLetters, word.frequencyRank);
  for (int i = 0; i < word->getNPoints(); i++) {
    request->points[i] = word->rawPoints[i];
  }
  FLResponse* result = systemsIntegrator->getCandidatesForRequest(request);
  for (int i = 0; i < result->candidatesN; i++) {
    FLResponseEntry* candidate = result->getCandidate(i);
    if (candidate->groupFrequencyRank > word->getGroupFrequencyRank() + badFrequencyLimit) {
      NSString* logEntry = [NSString stringWithFormat:@"near (%dth) word '%s' (#%d/#%d), ", i, word->getPrintLetters()->c_str(), word->getGroupFrequencyRank(), word->getFrequencyRank()];
      FLString s(candidate->letters, candidate->lettersN);
      NSString* key = FLStringToNSString(s);
      NSMutableString* log = [blacklist objectForKey:key];
      if (!log) {
        log = [[NSMutableString alloc] init];
        [log appendFormat:@"%s (#%d/#%d) is ", candidate->letters, candidate->groupFrequencyRank, candidate->frequencyRank];
        [blacklist setObject:log forKey:key];
      }
      [log appendString:logEntry];
    }
    if (i > suggestionsToLook) {
      break;
    }
  }
}

- (void) findPITAsForLength:(int) length badFrequencyLimit:(int) badFrequencyLimit top:(int) top suggestionsToLook:(int) suggestionsToLook blacklist:(NSMutableDictionary*) blacklist {
  
  NSLog(@"findPITAsForLength: %d badFrequencyLimit: %d top: %d", length, badFrequencyLimit, top);
  
  int i = 0;
  for (FLWord* word : *(systemsIntegrator->getUtils()->allWords)) {
    if (i > top) {
      break;
    }
    if (word->getNPoints() != length) {
      continue;
    }
    [self findPITAwordsFor:word badFrequencyLimit:badFrequencyLimit suggestionsToLook:suggestionsToLook blacklist:blacklist];
    i++;
  }
}

- (void) printBlacklist:(NSMutableDictionary*) blacklist {
  
  NSMutableString* log = [[NSMutableString alloc] init];
  
  //NSArray* allKeys = [blacklist allKeys];
  NSArray* allKeys = [blacklist keysSortedByValueWithOptions:NSSortStable usingComparator:^NSComparisonResult(NSString* value1, NSString* value2) {
    
    //    NSString* word1 = [[value1 componentsSeparatedByString:@" "] objectAtIndex:0];
    //    NSString* word2 = [[value2 componentsSeparatedByString:@" "] objectAtIndex:0];
    //    if (word1.length == word2.length) {
    return [[NSNumber numberWithInt:value2.length] compare:[NSNumber numberWithInt:value1.length]];
    //    }
    //    return [[NSNumber numberWithInt:word1.length] compare:[NSNumber numberWithInt:word2.length]];    
  }];
  
  
  for (NSString* key in allKeys) {
    NSString* value = [blacklist objectForKey:key];
    [log appendString:value];
    [log appendString:@"\n"];
  }
  
  NSLog(@"\n\n%@\n\n", log);
}


- (void) findPITAs {
  
  bool temp = systemsIntegrator->getSettingUseWordFrequency();
  systemsIntegrator->setSettingUseWordFrequency(false);
  
  NSLog(@"findPITAs, frequency setting is: %d", temp);
  
  NSMutableDictionary* blacklist = [[NSMutableDictionary alloc] init];
  
//  [self findPITAsForLength:2 badFrequencyLimit:15   top:999   suggestionsToLook:6  blacklist:blacklist];
//  [self findPITAsForLength:3 badFrequencyLimit:120  top:999   suggestionsToLook:6  blacklist:blacklist];
//  [self findPITAsForLength:4 badFrequencyLimit:600  top:99999 suggestionsToLook:10 blacklist:blacklist];
  [self findPITAsForLength:5 badFrequencyLimit:2400 top:99999 suggestionsToLook:10 blacklist:blacklist];
//  [self findPITAsForLength:6 badFrequencyLimit:3000 top:99999 suggestionsToLook:5  blacklist:blacklist];
//  [self findPITAsForLength:7 badFrequencyLimit:2500 top:99999 suggestionsToLook:4  blacklist:blacklist];
//  [self findPITAsForLength:8 badFrequencyLimit:2500 top:99999 suggestionsToLook:4  blacklist:blacklist];
  
  [self printBlacklist:blacklist];
  
  //[self findPITAsForLength:7 badFrequencyLimit:2000 top:99999 suggestionsToLook:3 blacklist:blacklist]; [self printBlacklist:blacklist];
  
  systemsIntegrator->setSettingUseWordFrequency(temp);
}

+ (void) runWith:(SystemsIntegrator*) worker {
  systemsIntegrator = worker;
  BlacklistGenerator* generator = [[BlacklistGenerator alloc] init];
  [generator findPITAs];
}

@end
