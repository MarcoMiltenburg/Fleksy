//
//  TouchAnalyzer.h
//  GestureTest
//
//  Created by Kostas Eleftheriou on 11/13/12.
//  Copyright (c) 2012 Kostas Eleftheriou. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLTouch.h"

@interface TouchAnalyzer : NSObject {
  int currentTest;
}

- (void) initialize;
- (void) loadTestsFromFile:(NSString*) filename;
- (void) runAllTests;
- (BOOL) checkTouchPassedTest:(FLTouch *)swipe print:(BOOL)print;
+ (UITouchKind) getKindForTouch:(FLTouch*) swipe print:(BOOL) print;
+ (FLTouch*) deltas:(FLTouch*) touch addFirstRaw:(BOOL) addFirstRaw;

+ (TouchAnalyzer*) sharedTouchAnalyzer;

@end
