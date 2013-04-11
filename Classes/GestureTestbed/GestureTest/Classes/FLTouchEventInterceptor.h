//
//  FLTouchEventInterceptor.h
//  FleksyKeyboard
//
//  Created by Kostas Eleftheriou on 11/15/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TouchAnalyzer.h"

@interface FLTouchEventInterceptor : UIGestureRecognizer {
  TouchAnalyzer* touchAnalyzer;
  NSMutableArray* forwardListeners;
  NSMutableDictionary* newTouchesDictionary;

  NSMutableDictionary* startedTouches;
  NSMutableDictionary* endedTouches;
}

- (void) addListener:(id) listener;

+ (FLTouchEventInterceptor*) sharedFLTouchEventInterceptor;

@property BOOL forwardRawValues;
@property float splitSwipesInPoints;
@property CGPoint shiftValue;

@end
