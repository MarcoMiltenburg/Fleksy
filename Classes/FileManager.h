//
//  FileManager.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 17/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface FileManager : NSObject {

  BOOL jailbroken;
  NSString* fleksyPath;
  //BOOL weAreSandboxed;
}

+ (UIImage*) imageNamed:(NSString*) name;
+ (NSString*) stringContentsOfFile:(NSString*) filename encoding:(NSStringEncoding) encoding;
+ (NSDictionary*) settings;
+ (BOOL) deviceIsJailbroken;
+ (BOOL) runningAsApp;
+ (NSURL*) URLForResource:(NSString*) name withExtension:(NSString*) ext subdirectory:(NSString*) subdirectory;
+ (NSData*) contentsOfFile:(NSString*) file;

@end
