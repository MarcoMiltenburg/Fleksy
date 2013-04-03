//
//  FleksyClient_NOIPC.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/27/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "FleksyClient_NOIPC.h"
#import "Settings.h"
#import "FileManager.h"
#import "VariousUtilities.h"
#import "VariousUtilities2.h"
#import "EncryptionUtilities.h"

#import <PatternRecognizer/CoreSettings.h>
#import <PatternRecognizer/FLBlackBoxSerializer.h>
#import <PatternRecognizer/Platform.h>


#define RUN_FLEKSY_TESTS 0

#if RUN_FLEKSY_TESTS
#import "FleksyEngineTestCase.h"
#endif

#include "FleksyPrivateAPI.h"


bool preprocessedFilesExist(NSString* filepathFormat);
NSString* getAbsolutePath(NSString* filepath, NSString* languagePack);

@implementation FleksyClient_NOIPC

- (void) handleSettingsChanged:(id) arg1 {
  
  //NSLogGreenBackground(@"handleSettingsChanged: %@", arg1);
  NSDictionary* settings = [FileManager settings];
  if (!settings) {
    return;
  }
  
  self.systemsIntegrator->setSettingPlusMinus1([[VariousUtilities getSettingNamed:@"FLEKSY_CORE_SETTING_SEARCH_MINUS_EXTRA" fromSettings:settings] boolValue]);
  self.systemsIntegrator->setSettingUseTx([[VariousUtilities getSettingNamed:@"FLEKSY_CORE_SETTING_USE_TX" fromSettings:settings] boolValue]);
  self.systemsIntegrator->setSettingUseWordFrequency([[VariousUtilities getSettingNamed:@"FLEKSY_CORE_SETTING_USE_WORD_FREQUENCY" fromSettings:settings] boolValue]);
  
  //NSLog(@"FleksyClient_NOIPC handleSettingsChanged: %@", settings);
}


- (id) init {
  
  if (self = [super init]) {
    EmptyOutputInterface e = EmptyOutputInterface();
    fleksyAPI = new FleksyAPI(e);
    self.systemsIntegrator = fleksyAPI->pImpl->fleksy;
    self->_userDictionary = [[FLUserDictionary alloc] initWithChangeListener:self];
    [VariousUtilities loadSettingsAndListen:self action:@selector(handleSettingsChanged:)];
  }
  return self;
}


//NSString* getWritablePathWithFilename(NSString* filename) {
//  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//  NSString* documentsDirectory = [paths objectAtIndex:0];
//  NSString* result = [documentsDirectory stringByAppendingPathComponent:filename];
//  //NSURL* url = [NSURL URLWithString:result];
//  [[NSFileManager defaultManager] createDirectoryAtPath:[result stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
//  return result;
//}


bool preprocessedFilesExist(NSString* filepathFormat) {
  return [[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:filepathFormat, 1]];
}

static string* _resolveFilepath(string& filepathFormat, int i) {
  size_t buffSize = filepathFormat.length() + 10;
  char buff[buffSize];
  snprintf(buff, buffSize, filepathFormat.c_str(), i);
  string* result = new string(buff);
  return result;
}

NSString* getAbsolutePath(NSString* filepath, NSString* languagePack) {
  return [NSString stringWithFormat:@"%@/%@/%@", [[VariousUtilities theBundle] bundlePath], languagePack, filepath];
}

- (void) loadDataWithLanguagePack:(NSString*) languagePack {

  NSLog(@"FleksyClient_NOIPC LOADING, languagePack: %@", languagePack);
  
  fleksyAPI->setResourcePath(getAbsolutePath(@"", languagePack).UTF8String);
  fleksyAPI->loadResources();  
  
  
  if (self.userDictionary && !RUN_FLEKSY_TESTS) {
    // TODO: what do we do for words that are remotely added (eg. iCloud) AFTER postload is called?
    // need to update ranks?
    [self.userDictionary load];
    NSString* filename = @"NSDEFAULTS_USER_DICTIONARY";
    NSString* text = [self.userDictionary stringContent];
    FLString myText = NSStringToFLString(text);
    self.systemsIntegrator->loadDictionary(NSStringToString(filename), (void*)myText.c_str(), myText.length(), FLStringMake("\t"), kWordlistUser, false);
  }
  
#if RUN_FLEKSY_TESTS
    filename = getAbsolutePath(@"tests/0000.txt", languagePack);
    NSLog(@"Running tests from file %@...", filename);
    double startTime = CFAbsoluteTimeGetCurrent();
    [FleksyEngineTestCase runFile:filename withFleksy:systemsIntegrator printErrors:YES percentErrorThreshold:0];
    NSLog(@"tests took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
#endif
  
}


- (FLAddWordResult) addedUserWord:(NSString*) word frequency:(float) frequency {
  NSLog(@"FleksyClient_NOIPC: addedUserWord: %@", word);
  return self.systemsIntegrator->addUserWord(NSStringToFLString(word), frequency);
}

- (bool) removedUserWord:(NSString*) word {
  NSLog(@"FleksyClient_NOIPC: removedUserWord: %@", word);
  return self.systemsIntegrator->removeUserWord(NSStringToFLString(word));
}

- (FLResponse*) getCandidatesForRequest:(FLRequest*) request {

  double startTime = CFAbsoluteTimeGetCurrent();

  int n = 1;
  FLResponse* result = NULL;
  for (int i = 0; i < n; i++) {
    free(result);
    result = self.systemsIntegrator->getCandidatesForRequest(request);
    //printf("new  calloc %p\n", result1);
    //printf("will free %p\n", result1);
  }

  double dt = CFAbsoluteTimeGetCurrent() - startTime;
  NSLog(@"FleksyClient_NOIPC request took %.6f (average over %d runs)", dt / n, n);
  return result;
}

@end
