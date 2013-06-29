//
//  HookingUtilities.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 16/11/2011.
//  Copyright (c) 2011 Syntellia Inc. All rights reserved.
//

#import "HookingUtilities.h"
#import "SynthesizeSingleton.h"
#import "Settings.h"
#import <objc/runtime.h>


static NSMutableDictionary* originalImplementations = nil;


@implementation NSObject (InstanceVariableForKey)

//int testVar = *(int*) [self primitiveInstanceVariableForKey:@"testVar"];

/*
- (void*) primitiveInstanceVariableForKey:(NSString*) aKey {
  if (aKey) {
    Ivar ivar = object_getInstanceVariable(self, [aKey UTF8String], NULL);
    if (ivar) {
      return (void*)((__bridge char*)self + ivar_getOffset(ivar));
    }
    NSLog(@"Could not find ivar %@ in object %@", aKey, self);
  }
  return NULL;
}*/

//NSMutableArray* testArray = (NSMutableArray*) [self objectInstanceVariableForKey:@"testArray"];
- (id) objectInstanceVariableForKey:(NSString*) key {
  Ivar ivar = class_getInstanceVariable([self class], [key UTF8String]);
  return object_getIvar(self, ivar);
}

@end


@implementation HookingUtilities

SYNTHESIZE_SINGLETON_FOR_CLASS(HookingUtilities);


- (id) init {
  id result = [super init];
  originalImplementations = [[NSMutableDictionary alloc] init];
  return result;
}


- (IMP) originalMethodNamed:(NSString*) methodName inClassNamed:(NSString*) className {
  
  NSString* key1 = [NSString stringWithFormat:@"%@/%@", className, methodName];
  IMP originalImplementation = (IMP) [[originalImplementations objectForKey:key1] pointerValue];
  
  if (!originalImplementation || (!className || className.length == 0)) {
    NSLog(@"Did not find exact match for %@, will search for method name only among all originalImplementations...", key1);
    for (NSString* key in originalImplementations) {
      NSLog(@"Searching key %@", key);
      if ([key hasSuffix:methodName]) {
        originalImplementation = (IMP) [[originalImplementations objectForKey:key] pointerValue];
        NSLog(@"Found %@", key);
        break;
      }
    }
  }

  if (!originalImplementation) {
    NSLog(@"ERROR: Did not find original implementation for %@ in our dictionary, will return NULL", key1);
    //NSLog(@"%@", [NSThread callStackSymbols]);
  }
  
  return originalImplementation;
}

- (BOOL) alreadyHookedMethodNamed:(NSString*) methodName inClassNamed:(NSString*) className {
  NSString* key1 = [NSString stringWithFormat:@"%@/%@", className, methodName];
  IMP originalImplementation = (IMP) [[originalImplementations objectForKey:key1] pointerValue];
  return originalImplementation != nil;
}

- (IMP) originalMethodNamed:(NSString*) methodName inClass:(Class) c {
  return [self originalMethodNamed:methodName inClassNamed:NSStringFromClass(c)];
}


- (Method) findMethod:(NSString*) name inClass:(Class) c {
  
  //NSLog(@"findMethod:%@ inClass:%@", name, NSStringFromClass(c));
  //This will find methods defined in class c OR superclasses
  //TODO: this is a problem since if we want to override UIKeyboard layout for example,
  //we end up overriding UIView's method. Need to then filter explicitly for class
  //name on layout call here...
  return class_getInstanceMethod(c, NSSelectorFromString(name));
    
  //This search will only find method defined in class c, not superclasses
//  Method m = nil;
//  unsigned int methodCount;
//  Method* mlist = class_copyMethodList(c, &methodCount);
//  if (mlist != NULL) {
//    int i;
//    for (i = 0; i < methodCount; ++i) {
//      NSString* methodName = NSStringFromSelector(method_getName(mlist[i]));
//      //NSLog(@"found %@.%@", NSStringFromClass(c), methodName);
//      if ([methodName compare:name] == NSOrderedSame) {
//        m = mlist[i];
//        break;
//      }
//    }
//  }
//  return m;
}

- (NSString*) getMethodDescription:(Method) m {
  if (!m) {
    return nil;
  }
  NSString* selectorName = NSStringFromSelector(method_getDescription(m)->name);
  return [NSString stringWithFormat:@"%@, %s", selectorName, method_getDescription(m)->types];
}

- (void) swapMethodNamed:(NSString*) orgMethodName inClass:(Class) orgClass
   withCustomMethodNamed:(NSString*) customMethodName inClass:(Class) customClass {
  
//  NSLog(@"swapMethod %@/%@ <--> %@/%@", orgClass, orgMethodName, customClass, customMethodName);
  
  //Intercept desired method by swapping
  Method orgMethod    = [self findMethod:orgMethodName inClass:orgClass];
  Method customMethod = [self findMethod:customMethodName inClass:customClass];
  
  if (orgMethod && customMethod) {
    NSString* key = [NSString stringWithFormat:@"%@/%@", NSStringFromClass(orgClass), orgMethodName];
    [originalImplementations setObject:[NSValue valueWithPointer:(void*) method_getImplementation(orgMethod)] forKey:key];
    method_exchangeImplementations(orgMethod, customMethod);
    NSLog(@"orgMethod:    %@", [self getMethodDescription:orgMethod]);
    NSLog(@"customMethod: %@", [self getMethodDescription:customMethod]);
  } else {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"swapMethod FAILED!");
    NSLog(@"orgMethod:    %@", [self getMethodDescription:orgMethod]);
    NSLog(@"customMethod: %@", [self getMethodDescription:customMethod]);
  }
}


- (void) swapMethodNamed:(NSString*) orgMethodName    inClassNamed:(NSString*) orgClassName
   withCustomMethodNamed:(NSString*) customMethodName inClassNamed:(NSString*) customClassName {
  
  if ([self alreadyHookedMethodNamed:orgMethodName inClassNamed:orgClassName]) {
    NSLog(@"Already hooked %@.%@, skipping", orgClassName, orgMethodName);
    return;
  }
  
  [self swapMethodNamed:orgMethodName inClass:objc_getClass([orgClassName cStringUsingEncoding:NSASCIIStringEncoding])
  withCustomMethodNamed:customMethodName inClass:objc_getClass([customClassName cStringUsingEncoding:NSASCIIStringEncoding])];
}

- (void) swapMethodNamed:(NSString*) orgMethodName inClassNamed:(NSString*) orgClassName withSameMethodInClassNamed:(NSString*) customClassName {
  [self swapMethodNamed:orgMethodName inClassNamed:orgClassName withCustomMethodNamed:orgMethodName inClassNamed:customClassName];
}

@end
