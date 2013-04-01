//
//  MultipartSpeechSynthesizer.m
//  iFleksy
//
//  Created by Kostas Eleftheriou on 1/3/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "MultipartSpeechSynthesizer.h"
#import "VariousUtilities.h"

@implementation MultipartSpeechSynthesizer


- (id) initWithParts:(NSArray*) _parts listener:(id<MultipartSpeechSynthesizerListener>) _listener {
  if (self = [super init]) {
    self->parts = _parts;
    self->currentBlockIndex = 0;
    self->listener = _listener;
  }
  return self;
}

- (void)didFinishAnnouncement:(NSNotification *)dict {
  //NSString* valueSpoken = [[dict userInfo] objectForKey:UIAccessibilityAnnouncementKeyStringValue];
  //NSString* wasSuccessful = [[dict userInfo] objectForKey:UIAccessibilityAnnouncementKeyWasSuccessful];
  NSLog(@"didFinishAnnouncement, %@", dict);
  // TODO if (dict && ![wasSuccessful boolValue]) { [self stop]; return; }
  currentBlockIndex++;
  [self startNextBlock];
}

- (void) startNextBlock {
  if (currentBlockIndex >= self->parts.count) {
    NSLog(@"reached end of blocks");
    [self stop];
    return;
  }
  
  [VariousUtilities performAudioFeedbackFromString:[self->parts objectAtIndex:self->currentBlockIndex]];
  
  // simulate effect of UIAccessibilityAnnouncementDidFinishNotification
  if (!UIAccessibilityIsVoiceOverRunning()) {
    [self performSelector:@selector(didFinishAnnouncement:) withObject:nil afterDelay:0.7];
  }
}

- (void) start {
  
  NSLog(@"MultipartSpeechSynthesizer start with parts: %@", self->parts);
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didFinishAnnouncement:) name:UIAccessibilityAnnouncementDidFinishNotification object:nil];
  [self startNextBlock];
}


- (void) stop {
  [[NSNotificationCenter defaultCenter] removeObserver:self name:UIAccessibilityAnnouncementDidFinishNotification object:nil];
  [VariousUtilities stopSpeaking];
  [listener speechEnded];
}


@end
