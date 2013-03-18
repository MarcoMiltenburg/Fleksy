//
//  StringConversion.h
//  iFleksy
//
//  Created by Kostas Eleftheriou on 12/27/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FLString.h"

extern std::wstring _NSStringToStringW ( NSString* Str );
extern NSString* _StringWToNSString ( const std::wstring& Str );
extern FLString _NSStringToString(NSString* str);
extern NSString* _StringToNSString(const FLString &s);
// for filenames / paths etc
extern std::string _NSStringToStringUTF8(NSString* str);

extern bool stringsEqual(NSString* _s1, FLString &s2);
