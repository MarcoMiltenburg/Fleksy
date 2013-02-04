//
//  BlacklistGenerator.h
//  Fleksy
//
//  Created by Kostas Eleftheriou on 5/24/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SystemsIntegrator.h"

@interface BlacklistGenerator : NSObject {
}

+ (void) runWith:(SystemsIntegrator*) worker;

@end
