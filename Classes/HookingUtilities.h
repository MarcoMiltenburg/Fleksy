//
//  HookingUtilities.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 16/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (InstanceVariableForKey)
//- (void*) primitiveInstanceVariableForKey:(NSString*) aKey;
- (id) objectInstanceVariableForKey:(NSString*) key;
@end

@interface HookingUtilities : NSObject

//TODO make all these class methods

- (IMP) originalMethodNamed:(NSString*) methodName inClass:(Class) c;

- (BOOL) alreadyHookedMethodNamed:(NSString*) methodName inClassNamed:(NSString*) className;

- (void) swapMethodNamed:(NSString*) orgMethodName inClass:(Class) orgClass
   withCustomMethodNamed:(NSString*) customMethodName inClass:(Class) customClass;

- (void) swapMethodNamed:(NSString*) orgMethodName    inClassNamed:(NSString*) orgClassName
   withCustomMethodNamed:(NSString*) customMethodName inClassNamed:(NSString*) customClassName;

- (void) swapMethodNamed:(NSString*) orgMethodName inClassNamed:(NSString*) orgClassName withSameMethodInClassNamed:(NSString*) customClassName;

+ (HookingUtilities*) sharedHookingUtilities;

@end
