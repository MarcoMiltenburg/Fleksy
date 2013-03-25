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


NSString* getWritablePathWithFilename(NSString* filename) {
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  NSString* result = [documentsDirectory stringByAppendingPathComponent:filename];
  //NSURL* url = [NSURL URLWithString:result];
  [[NSFileManager defaultManager] createDirectoryAtPath:[result stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
  return result;
}


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
  
  double startTime = CFAbsoluteTimeGetCurrent();
  
  NSString* filename;
  NSString* text;
  
  void* buffer;
  size_t bufferSize;
  
  
  filename = getAbsolutePath(@"keyboards/keyboard-iPhone-ASCII.txt.xxx", languagePack);
  buffer = EncryptionUtilities::readBinaryFile(filename.UTF8String, bufferSize);
  self.systemsIntegrator->loadKeyboardData(buffer, bufferSize, true);
  free(buffer);
  
  string preprocessedFilepathFormat = NSStringToString(getAbsolutePath(@"preprocessed/preprocessed-%d.txt", languagePack));
  
  BOOL usePreprocessedFiles = YES;
  if (usePreprocessedFiles) {
    double startTimePreload = CFAbsoluteTimeGetCurrent();
    for (int i = 1; i <= FLEKSY_MAX_WORD_SIZE; i++) {
      string* filepath = _resolveFilepath(preprocessedFilepathFormat, i);
      printf("_resolveFilepath %d: %s\n", i, filepath->c_str());
      size_t length;
      char* contents = FLBlackBoxSerializer::memoryMapFile(filepath->c_str(), &length);
      if (contents && length) {
        self.systemsIntegrator->preloadWithContents(i, contents, length);
        FLBlackBoxSerializer::unmapMemoryMapFile(contents, length);
      } else {
        [[NSException exceptionWithName:@"LoadingException" reason:[NSString stringWithFormat:@"preprocessed file %s not found!", filepath->c_str()] userInfo:nil] raise];
      }
      delete filepath;
    }
    NSLog(@"> loadTables took %.6f", CFAbsoluteTimeGetCurrent() - startTimePreload);
  } else {
    NSLog(@"not using preprocessed files");
  }
  
#if !DEBUG_NO_WORDS
  
  filename = getAbsolutePath(@"wordlists/wordlist-master-blacklist-capitalized.txt.xxx", languagePack);
  buffer = EncryptionUtilities::readBinaryFile(filename.UTF8String, bufferSize);
  self.systemsIntegrator->loadDictionary(NSStringToString(filename), buffer, bufferSize, FLStringMake("\t"), kWordlistBlacklist, true);
  free(buffer);
  
  filename = getAbsolutePath(@"wordlists/wordlist-master-blacklist.txt.xxx", languagePack);
  buffer = EncryptionUtilities::readBinaryFile(filename.UTF8String, bufferSize);
  self.systemsIntegrator->loadDictionary(NSStringToString(filename), buffer, bufferSize, FLStringMake(" "), kWordlistBlacklist, true);
  free(buffer);
  
  filename = getAbsolutePath(@"wordlists/wordlist-master-ASCII.txt.xxx", languagePack);
  buffer = EncryptionUtilities::readBinaryFile(filename.UTF8String, bufferSize);
  self.systemsIntegrator->loadDictionary(NSStringToString(filename), buffer, bufferSize, FLStringMake("\t"), kWordlistStandard, true);
  free(buffer);
  
  // we want to write before we load "dynamic" dictionaries (preloaded and user dictionaries have their BB values calculated on the fly)
  //filename = [NSString stringWithFormat:@"%@/preprocessed/preprocessed-%%d.txt", languagePack];
  //systemsIntegrator->writeTablesIfNeeded(NSStringToString(getWritablePathWithFilename(filename)));
  
  filename = getAbsolutePath(@"wordlists/wordlist-preloaded.txt.xxx", languagePack);
  buffer = EncryptionUtilities::readBinaryFile(filename.UTF8String, bufferSize);
  self.systemsIntegrator->loadDictionary(NSStringToString(filename), buffer, bufferSize, FLStringMake(" "), kWordlistPreloaded, true);
  free(buffer);
  
  if (self.userDictionary && !RUN_FLEKSY_TESTS) {
    // TODO: what do we do for words that are remotely added (eg. iCloud) AFTER postload is called?
    // need to update ranks?
    [self.userDictionary load];
    filename = @"NSDEFAULTS_USER_DICTIONARY";
    text = [self.userDictionary stringContent];
    FLString myText = NSStringToFLString(text); 
    self.systemsIntegrator->loadDictionary(NSStringToString(filename), (void*)myText.c_str(), myText.length(), FLStringMake("\t"), kWordlistUser, false);
  }
#endif
  
  
  //if ([[NSFileManager defaultManager] fileExistsAtPath:filename]) {
    self.systemsIntegrator->loadContextData(NSStringToString(getAbsolutePath(@"context/unigram.file", languagePack)),
                                       NSStringToString(getAbsolutePath(@"context/bigram.file", languagePack)),
                                       NSStringToString(getAbsolutePath(@"context/trigram.file", languagePack)),
                                       "", "", "", false);
  //}
  
  self.systemsIntegrator->postload();
  
  NSLog(@"loadData took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
  
#if RUN_FLEKSY_TESTS
    filename = getAbsolutePath(@"tests/0000.txt", languagePack);
    NSLog(@"Running tests from file %@...", filename);
    double startTime = CFAbsoluteTimeGetCurrent();
    [FleksyEngineTestCase runFile:filename withFleksy:systemsIntegrator printErrors:YES percentErrorThreshold:0];
    NSLog(@"tests took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
#endif
  
  // notify loading is 100% done
  [[NSNotificationCenter defaultCenter] postNotificationName:FLEKSY_LOADING_NOTIFICATION object:[NSNumber numberWithFloat:1]];
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
