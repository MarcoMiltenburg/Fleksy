//
//  UIView+MainThreadCheck.m
//  iFleksy
//
//  Created by Vince Mansel on 4/2/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "UIView+MainThreadCheck.h"
#import "Settings.h"

@implementation UIView (MainThreadCheck)

#if FLEKSY_IS_MAIN_THREAD_CHECK
+(id)alloc
{
  NSParameterAssert([NSThread isMainThread]==YES);
  return [super alloc];
}
#else
+(id)alloc {
  if (![NSThread isMainThread]) {
    [TestFlight passCheckpoint:[NSString stringWithFormat:@"Called on Background Thread %@ from %@ ", [[NSThread currentThread] description],  [[self class ] stackDescription]]];
  }
  return [super alloc];
}
#endif

+ (NSString *)stackDescription {
  NSMutableString *stackString = [[self class].description mutableCopy];
  
  for (NSString * methodName in [NSThread callStackSymbols]) {
    [stackString appendFormat:@"\n %@", methodName];
  }
  return stackString;
}

@end
