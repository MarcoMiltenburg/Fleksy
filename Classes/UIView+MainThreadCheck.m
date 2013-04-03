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

#ifdef DEBUG
#if FLEKSY_IS_MAIN_THREAD_CHECK
+(id)alloc
{
  NSParameterAssert([NSThread isMainThread]==YES);
  return [super alloc];
}
#endif
#endif

@end
