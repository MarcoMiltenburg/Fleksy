//
//  DiagnosticsManager.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/8/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "DiagnosticsManager.h"
#import "SSZipArchive.h"
#import "AFNetworking.h"

#define MAX_FILE_SIZE (10 * 1024)

@implementation DiagnosticsManager


+ (NSString*) zip:(NSString*) inputFile {
  NSString* zipName = [[inputFile lastPathComponent] stringByReplacingOccurrencesOfString:@".txt" withString:@".zip"];
  NSString* zippedPath = [[inputFile stringByDeletingLastPathComponent] stringByAppendingPathComponent:zipName];
  NSArray* inputPaths = [NSArray arrayWithObjects:inputFile, nil];
  BOOL result = [SSZipArchive createZipFileAtPath:zippedPath withFilesAtPaths:inputPaths];
  if (result) {
    NSError* error;
    if ([[NSFileManager defaultManager] removeItemAtPath:inputFile error:&error]) {
      NSLog(@"Deleted log file %@", inputFile);
    } else {
      NSLog(@"Could not delete log file %@: %@", inputFile, error);
    }
    return zippedPath;
  }
  return nil;
}


+ (void) sendFile:(NSString*) inputFile {
  
  NSString* filename = [inputFile lastPathComponent];
  NSString* mimeType = @"application/zip";
  
  NSURL* url = [NSURL URLWithString:@"http://www.drivehq.com"];
  AFHTTPClient* httpClient = [[AFHTTPClient alloc] initWithBaseURL:url];
  NSData* data = [NSData dataWithContentsOfFile:inputFile]; 
  
  NSMutableDictionary* parameters = [[NSMutableDictionary alloc] init];
  NSString* name = @"123";
  [parameters setObject:name forKey:@"txtName"];
  
  NSMutableURLRequest* request = [httpClient multipartFormRequestWithMethod:@"POST" path:[NSString stringWithFormat:@"/Dropbox/dropbox.aspx?dropboxid=60831030&action=upload&templateID=0&uniqueID=%d", 123]
                                                                 parameters:parameters constructingBodyWithBlock: ^(id <AFMultipartFormData>formData) {
                                                                   [formData appendPartWithFileData:data name:filename fileName:filename mimeType:mimeType];
                                                                 }];
  
  AFHTTPRequestOperation* operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];  [operation setCompletionBlockWithSuccess:
   ^(AFHTTPRequestOperation *operation, id responseObject) {
    NSLog(@"upload %@ success", inputFile);
    NSError* error;
    if ([[NSFileManager defaultManager] removeItemAtPath:inputFile error:&error]) {
      NSLog(@"Deleted log file %@", inputFile);
    } else {
      NSLog(@"Could not delete log file %@: %@", inputFile, error);
    }
  }
                                   failure:
   ^(AFHTTPRequestOperation *operation, NSError *error) {
     NSLog(@"upload %@ failure, %@", inputFile, error);
  }];
  
  [operation setUploadProgressBlock:^(NSInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
    NSLog(@"Sent %lld of %lld bytes for file %@", totalBytesWritten, totalBytesExpectedToWrite, inputFile);
  }];
  [operation start];
}


+ (void) processFile:(NSString*) inputFile {
  NSString* zipFile = [DiagnosticsManager zip:inputFile];
  [DiagnosticsManager sendFile:zipFile];
}

- (id) init {
  if (self = [super init]) {
    [self startNewFile];
  }
  return self;
}

- (void) startNewFile {
  
  [self cleanup];
  
  NSArray* paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString* documentsDirectory = [paths objectAtIndex:0];
  filepath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Fleksy.log.%.0f.txt", CFAbsoluteTimeGetCurrent()]];
  BOOL createFile = ![[NSFileManager defaultManager] fileExistsAtPath:filepath];
  if (createFile) {
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:filepath contents:nil attributes:nil];
    if (!result) {
      NSLog(@"Could not create log file %@", filepath);
    }
  }
  handle = [NSFileHandle fileHandleForWritingAtPath:filepath];
  [self append:[NSString stringWithFormat:@"\n//Log started %@", [NSDate date]]];
}

- (void) sendWithComment:(NSString*) comment {
  NSLog(@"DiagnosticsManager sendWithComment: %@", comment);
  [self append:comment];
  [DiagnosticsManager performSelector:@selector(processFile:) withObject:[NSString stringWithString:filepath] afterDelay:2];
  [self startNewFile];
}

- (void) append:(NSString*) string {
  
  if (!string) {
    return;
  }
  
  string = [NSString stringWithFormat:@"%.2f %@", CFAbsoluteTimeGetCurrent(), string];
  long long size = [handle seekToEndOfFile];
  [handle writeData:[string dataUsingEncoding:NSUTF8StringEncoding]];
  [handle writeData:[@"\n"  dataUsingEncoding:NSUTF8StringEncoding]];
  
  if (size > MAX_FILE_SIZE) {
    [handle writeData:[@"MAX_FILE_SIZE" dataUsingEncoding:NSUTF8StringEncoding]];
    [self sendWithComment:nil];
  }
}

- (void) points:(NSArray*) points suggestions:(NSArray*) suggestions {
  NSMutableString* string = [[NSMutableString alloc] init];
  
  for (NSValue* value in points) {
    CGPoint point = [value CGPointValue];
    [string appendFormat:@"%.0f,%.0f ", point.x, point.y];
  }
  
  for (NSString* suggestion in suggestions) {
    [string appendFormat:@"%@ ", suggestion];
  }
  [self append:string];
  
  
//  if (suggestions && [suggestions count]) {
//    [TestFlight passCheckpoint:[suggestions objectAtIndex:0]];
//  }
}



- (void) cleanup {
  [handle closeFile];
}


- (void) dealloc {
  NSLog(@"DiagnosticsManager closing file %@", filepath);
  [self cleanup];
}

@end
