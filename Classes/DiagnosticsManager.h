//
//  DiagnosticsManager.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 6/8/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DiagnosticsManager : NSObject {
  NSString* filepath;
  NSFileHandle* handle;
}

- (void) append:(NSString*) string;
- (void) points:(NSArray*) points suggestions:(NSArray*) suggestions;
- (void) sendWithComment:(NSString*) comment;

@end
