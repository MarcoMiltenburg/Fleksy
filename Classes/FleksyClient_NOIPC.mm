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
  
  
  self.systemsIntegrator->setSettingShapeLayerWeight(    [[VariousUtilities getSettingNamed:@"SHAPE_LAYER_WEIGHT"     fromSettings:settings] floatValue]);
  self.systemsIntegrator->setSettingTransformLayerWeight([[VariousUtilities getSettingNamed:@"TRANSFORM_LAYER_WEIGHT" fromSettings:settings] floatValue]);
  self.systemsIntegrator->setSettingContextLayerWeight(  [[VariousUtilities getSettingNamed:@"CONTEXT_LAYER_WEIGHT"   fromSettings:settings] floatValue]);
  self.systemsIntegrator->setSettingPlatformLayerWeight( [[VariousUtilities getSettingNamed:@"PLATFORM_LAYER_WEIGHT"  fromSettings:settings] floatValue]);
  
  
  NSLog(@"FleksyClient_NOIPC handleSettingsChanged: %@", settings);
}


- (id) init {
  
  if (self = [super init]) {
    EmptyOutputInterface e = EmptyOutputInterface();
    self.fleksyAPI = new FleksyAPI(e);
    
    NSString* apiVersion = [NSString stringWithCString:self.fleksyAPI->getVersion().c_str() encoding:NSASCIIStringEncoding];
    NSLog(@"%@", apiVersion);
    
    [[NSUserDefaults standardUserDefaults] setObject:apiVersion forKey:FLEKSY_APP_API_VERSION_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // TODO: hack to access internal SystemsIntegrator object. Access to fleksyAPI->pImpl should be completely eliminated.
    self.systemsIntegrator = self.fleksyAPI->pImpl->fleksy;
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
  return [NSString stringWithFormat:@"%@/resourceArchive-%@.jet", [[VariousUtilities theBundle] bundlePath], languagePack];
}

- (void) loadDataWithLanguagePack:(NSString*) languagePack {
  
  NSLog(@"FleksyClient_NOIPC LOADING, languagePack: %@", languagePack);
  
  self.fleksyAPI->setResourceFile(getAbsolutePath(@"", languagePack).UTF8String);
  self.fleksyAPI->loadResources();
  
  
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
  FLStringPtr wordPtr = FLStringPtr(new FLStringMake(word.UTF8String));
  return self.systemsIntegrator->addUserWord(wordPtr);
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
#pragma unused(dt)
  return result;
}

@end
