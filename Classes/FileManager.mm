//
//  FileManager.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 17/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "FileManager.h"
#import <Settings.h>
#import "SynthesizeSingleton.h"
#import "VariousUtilities.h"

#define WEB_SERVER_PORT 9999

@implementation FileManager

SYNTHESIZE_SINGLETON_FOR_CLASS(FileManager);

- (BOOL)fileExists:(NSString *)file {
  
  NSString* filepath;
  if ([file hasPrefix:@"/"]) {
    filepath = file;
  } else {
    filepath = [NSString stringWithFormat:@"%@/%@", [FileManager runningAsApp] ? [[VariousUtilities theBundle] bundlePath] : fleksyPath, file];
  }
  
  NSLog(@" filepath exist is %@", filepath);
  return [[NSFileManager defaultManager] fileExistsAtPath:filepath];

}

- (BOOL)deleteFile:(NSString *)file {
  
  NSString* filepath;
  if ([file hasPrefix:@"/"]) {
    filepath = file;
  } else {
    filepath = [NSString stringWithFormat:@"%@/%@", [FileManager runningAsApp] ? [[VariousUtilities theBundle] bundlePath] : fleksyPath, file];
  }
  
  NSLog(@" filepath delete is %@", filepath);
  NSError *error;

  // NSFilePosixPermissions
  NSLog(@"Attributes of Item Settings file: %@", [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:&error]);
  /* 2013-07-08 20:26:58.387 FleksyDev[1035:907] Attributes of Item Settings file: {
   NSFileCreationDate = "2013-07-08 20:52:51 +0000";
   NSFileExtensionHidden = 0;
   NSFileGroupOwnerAccountID = 501;
   NSFileGroupOwnerAccountName = mobile;
   NSFileModificationDate = "2013-07-08 20:52:51 +0000";
   NSFileOwnerAccountID = 501;
   NSFileOwnerAccountName = mobile;
   NSFilePosixPermissions = 420;
   NSFileProtectionKey = NSFileProtectionNone;
   NSFileReferenceCount = 1;
   NSFileSize = 6108;
   NSFileSystemFileNumber = 6104799;
   NSFileSystemNumber = 16777218;
   NSFileType = NSFileTypeRegular;
   */
  
  if (![[NSFileManager defaultManager] setAttributes:[NSDictionary dictionaryWithObject:@(777) forKey:NSFilePosixPermissions] ofItemAtPath:filepath error:&error]) {
    NSLog(@"Could not change permission of Settings file: %@", error);
  }
  
  error = nil;
  
  NSLog(@"Attributes of Item Settings file: %@", [[NSFileManager defaultManager] attributesOfItemAtPath:filepath error:&error]);

  BOOL isDeleted = [[NSFileManager defaultManager] removeItemAtPath:filepath error:&error];
  
  if (!isDeleted) {
    NSLog(@"Error: Cannot delete file: %@", error);
  }

  return isDeleted;
}


- (NSData*) dataWithContentsOfFile:(NSString*) filepath logErrors:(BOOL) logErrors {
  NSURL* url = [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%d%@", WEB_SERVER_PORT, filepath]];
  NSData* data = nil;
  @try {
    data = [NSData dataWithContentsOfURL:url];
  }
  @catch (NSException* exception) {
    NSLog(@"dataWithContentsOfFile:%@ EXCEPTION: %@", filepath, exception);
  }
  @finally {
  }
  //web server is configured to return empty file on 404
  if (![data length]) {
    data = nil;
  }
  if (data) {
    //NSLog(@"dataWithContentsOfFile:%@ %@", filepath, [data subdataWithRange:NSMakeRange(0, fmin(30, [data length]))]);
  } else if (logErrors) {
    NSLog(@"dataWithContentsOfFile:%@ NOT FOUND!, url: %@", filepath, url);
  }
  return data;
}

- (NSArray*) contentsOfDirectoryAtPath:(NSString*) path {
  
  if ([FileManager runningAsApp]) {
    NSError* err;
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&err];
  }  
  
  NSString* contents = [FileManager stringContentsOfFile:path encoding:NSASCIIStringEncoding];
  NSArray* result0 = [contents componentsSeparatedByString:@"<a href="];
  NSMutableArray* result = [[NSMutableArray alloc] init];
  int i = 0;
  for (NSString* s in result0) {
    if (i > 1) {
      NSString* f = [[[[s componentsSeparatedByString:@"</a>"] objectAtIndex:0] componentsSeparatedByString:@">"] objectAtIndex:1];
      [result addObject:f];
    }
    i++;
  }
  //NSLog(@"contentsOfDirectoryAtPath: %@: %@", path, result);
  return result;
}

- (NSData*) contentsOfFile:(NSString*) file {
  
  NSString* filepath;
  if ([file hasPrefix:@"/"]) {
    filepath = file;
  } else {
    filepath = [NSString stringWithFormat:@"%@/%@", [FileManager runningAsApp] ? [[VariousUtilities theBundle] bundlePath] : fleksyPath, file];
  }
    
  //NSLog(@"contentsOfFile: %@", filepath);
  if ([FileManager runningAsApp]) {
    NSData* result = [NSData dataWithContentsOfFile:filepath];
    if (!result) {
      NSLog(@"ERROR: contentsOfFile %@: File not found!", file);
      //[NSException raise:@"ERROR" format:@"contentsOfFile %@: File not found!", file];
    }
    return result;
  } else {
    return [self dataWithContentsOfFile:filepath logErrors:YES];
  }
}


- (id) init {
  
  self = [super init];
  
  NSLog(@"FileManager init, UIApplication is %@", [UIApplication sharedApplication]);
  
  NSError* err;
  NSArray* files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Applications/Cydia.app" error:&err];
  if (!files || ![files count]) {
    jailbroken = NO;
  } else {
    jailbroken = YES;
  }
  
  NSLog(@"Device is %@jailbroken", jailbroken ? @"" : @"NOT ");
  NSLog(@"Running as a standalone app: %@", [FileManager runningAsApp] ? @"YES" : @"NO");
  
  if ([FileManager runningAsApp]) {
    return self; //nothing more to do
  }
  
  //BOOL daemonAlive;
  float totalWaitTime = 0;
  while (1) {
    if ([self dataWithContentsOfFile:@"/Applications/Calculator.app" logErrors:YES]) {
      break;
    }
    float sleepTime = 1.0f;
    NSLog(@"waiting %.3f seconds for lighttpd... (%.3f seconds so far)", sleepTime, totalWaitTime);
    [NSThread sleepForTimeInterval:sleepTime];
    totalWaitTime += sleepTime;
    
    if (totalWaitTime > 30) {
      NSLog(@"timeout");
      break;
    }
  }
  NSLog(@"waiting for lighttpd...DONE in %.3f seconds", totalWaitTime);
  
  
  fleksyPath = nil;
  files = [self contentsOfDirectoryAtPath:@"/var/mobile/Applications"]; //[[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/var/mobile/Applications" error:&err];
  for (NSString* file in files) {
    NSString* fullPath = [NSString stringWithFormat:@"/var/mobile/Applications/%@/%@.app", file, FLEKSY_PRODUCT_NAME];
    if ([self dataWithContentsOfFile:fullPath logErrors:NO]) {
      fleksyPath = [fullPath copy];
      break;
    }
  }
  
  if (!fleksyPath) {
    NSException* ex = [[NSException alloc] initWithName:@"Fatal" reason:@"Could not locate application bundle" userInfo:nil];
    NSLog(@"%@", ex);
    [ex raise];
  }
  
  //weAreSandboxed = ![[NSFileManager defaultManager] fileExistsAtPath:fleksyPath];
  //NSLog(@"weAreSandboxed: %d", weAreSandboxed);
  
  return self;
}


+ (UIImage*) imageNamed:(NSString*) name {
  return [UIImage imageWithData:[[FileManager sharedFileManager] contentsOfFile:name]];
}


+ (NSString*) stringContentsOfFile:(NSString*) file encoding:(NSStringEncoding) encoding {

  NSData* data = [[FileManager sharedFileManager] contentsOfFile:file];
  NSString* result2 = [[NSString alloc] initWithData:data encoding:encoding];
  //NSLog(@"stringContentsOfFile: %@:\n%@", filename, result);
  return result2;
}

+ (void) addSettingsFromFile:(NSString*) filename toDictionary:(NSMutableDictionary*) result {
  
  //NSLog(@"adding settings from file %@", filename);
  
  NSData* contents = [[FileManager sharedFileManager] contentsOfFile:filename];
  if (!contents) {
    NSLog(@"WARNING: could not get settings!");
    return;
  }
  
  NSDictionary* defaults = [NSPropertyListSerialization propertyListWithData:contents options:NSPropertyListImmutable format:nil error:nil];
  NSArray* preferencesArray = [defaults objectForKey:@"PreferenceSpecifiers"];
  for (NSDictionary* item in preferencesArray) {
    //Get the key of the item.
    NSString* keyValue = [item objectForKey:@"Key"];
    //Get the default value specified in the plist file.
    id defaultValue = [item objectForKey:@"DefaultValue"];
    //NSLog(@"setting %@, default = %@", keyValue, defaultValue);
    //Some items won't have these, like labels, dividers, text fields
    if (keyValue && defaultValue) {				
      [result setObject:defaultValue forKey:keyValue];
    } else {
      NSString* title = [item objectForKey:@"Title"];
      if ([title rangeOfString:@"version"].length > 0) {
        //NSString* version = [[title componentsSeparatedByString:@" "] lastObject];
        [result setObject:title forKey:@"FLEKSY_VERSION"];
      }
      //NSLog(@"item: %@", item);
    }
  }
}


+ (NSDictionary*) settings {
  
  return [NSUserDefaults standardUserDefaults].dictionaryRepresentation;
  
//  //first fetch all the previous values from old Settings file
//  
//  if ([[FileManager sharedFileManager] fileExists:@"Settings.bundle/Root.plist"]) {
//    [FileManager addSettingsFromFile:@"Settings.bundle/Root.plist" toDictionary:result];
//    
//    NSLog(@" result from old Settings = %@", result);
//    
//    // Now delete it forever
//    
//    [[FileManager sharedFileManager] deleteFile:@"Settings.bundle/Root.plist"];
//  }
//  
//  //first fetch all the default values
//  [FileManager addSettingsFromFile:@"InAppSettings.bundle/Root.inApp.plist" toDictionary:result];
//  
//  //now the hidden preferences
//  [FileManager addSettingsFromFile:@"Settings_HIDDEN.bundle/Root.plist" toDictionary:result];
//    
//  //now overwrite with changed values (if any)
//  NSData* contents = [[FileManager sharedFileManager] contentsOfFile:[NSString stringWithFormat:@"../Library/Preferences/%@.plist", [[NSBundle mainBundle] bundleIdentifier]]];
//  if (contents) {
//    NSDictionary* changedPreferences = [NSPropertyListSerialization propertyListWithData:contents options:NSPropertyListImmutable format:nil error:nil];
//    //NSLog(@"defaults had %d entries, adding another %d changed preferences", [result count], [changedPreferences count]);
//    [result addEntriesFromDictionary:changedPreferences];
//  } else {
//    NSLog(@"Could not get changed preferences, will just use defaults from Settings.bundle/Root.plist");
//  }
//  
//  NSLog(@"settings(%d):\n%@", [result count], result);
//  
//  return result;
}
                             
+ (BOOL) deviceIsJailbroken {
  return [FileManager sharedFileManager]->jailbroken;
}

+ (BOOL) runningAsApp {
  return YES;
  
  //NSProcessInfo* processInfo = [NSProcessInfo processInfo];
  BOOL result = [[[NSBundle mainBundle] bundlePath] hasSuffix:[NSString stringWithFormat:@"%@.app", FLEKSY_PRODUCT_NAME]];
  //NSLogBlue(@"runningAsApp: %d (bundle %@)", result, [[NSBundle mainBundle] bundlePath]);
  return result;
}

+ (NSURL*) URLForResource:(NSString*) name withExtension:(NSString*) ext subdirectory:(NSString*) subdirectory {
  if ([FileManager runningAsApp]) {
    return [[VariousUtilities theBundle] URLForResource:name withExtension:ext subdirectory:subdirectory];
  } else {
    return [NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%d/%@/%@.%@", WEB_SERVER_PORT, [FileManager sharedFileManager]->fleksyPath, name, ext]];  
  }
}


+ (NSData*) contentsOfFile:(NSString*) file {
  return [[FileManager sharedFileManager] contentsOfFile:file];
}



@end
