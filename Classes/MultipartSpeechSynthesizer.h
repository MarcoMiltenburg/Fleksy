//
//  MultipartSpeechSynthesizer.h
//  iFleksy
//
//  Created by Kostas Eleftheriou on 1/3/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MultipartSpeechSynthesizerListener
@optional
- (void) speechEnded;
@end

@interface MultipartSpeechSynthesizer : NSObject {
  int currentBlockIndex;
  NSArray* parts;
  id<MultipartSpeechSynthesizerListener> listener;
}

- (id) initWithParts:(NSArray*) parts listener:(id<MultipartSpeechSynthesizerListener>) listener;
- (void) start;
- (void) stop;

@end
