//
//  StringConversion.mm
//  iFleksy
//
//  Created by Kostas Eleftheriou on 12/27/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "StringConversion.h"


std::wstring _NSStringToStringW ( NSString* Str ) {
  NSStringEncoding pEncode    =   CFStringConvertEncodingToNSStringEncoding ( kCFStringEncodingUTF32LE );
  NSData* pSData              =   [ Str dataUsingEncoding : pEncode ];
  return std::wstring ( (wchar_t*) [ pSData bytes ], [ pSData length] / sizeof ( wchar_t ) );
}

NSString* _StringWToNSString ( const std::wstring& Str ) {
  NSString* pString = [ [ NSString alloc ]
                       initWithBytes : (char*)Str.data()
                       length : Str.size() * sizeof(wchar_t)
                       encoding : CFStringConvertEncodingToNSStringEncoding ( kCFStringEncodingUTF32LE ) ];
  return pString;
}

FLString _NSStringToString(NSString* str) {
  if (!str) {
    return FLStringMake("");
  }
  
  if (str.length == 1) {
    if ([str isEqualToString:@"→"] || [str isEqualToString:@"←"] || [str isEqualToString:@"↓"] || [str isEqualToString:@"↑"]) {
      return FLStringMake(str.UTF8String);
    }
  }
  
  long bufferSize = str.length+1;
  char* buffer = (char*) malloc(bufferSize);
  NSUInteger usedLength = -1;
  BOOL ok = [str getBytes:buffer maxLength:bufferSize usedLength:&usedLength encoding:NSISOLatin1StringEncoding options:0 range:NSMakeRange(0, str.length) remainingRange:nil];
  if (!ok) {
#ifndef FL_BUILD_FOR_APP_STORE
    NSLog(@"_NSStringToString: NSISOLatin1StringEncoding !ok for <%@>, trying NSWindowsCP1252StringEncoding", str);
#endif
    ok = [str getBytes:buffer maxLength:bufferSize usedLength:&usedLength encoding:NSWindowsCP1252StringEncoding options:0 range:NSMakeRange(0, str.length) remainingRange:nil];
  }
  //NSLog(@"_NSStringToString: <%@>, bufferSize: %lu, usedLength: %d, ok: %d", str, bufferSize, usedLength, ok);
  assert(ok);
  assert(usedLength == bufferSize-1);
  //NSLog(@"buffer[bufferSize-1]: %d", buffer[bufferSize-1]);
  //ensure NULL-terminated
  buffer[bufferSize-1] = NULL;
  assert(!buffer[bufferSize-1]);
  FLString result = FLStringMake(buffer);
  //NSLog(@"str.length: %d, bufferSize: %lu, result.length: %lu", str.length, bufferSize, result.length());
  assert(str.length == result.length());
  free(buffer);
  return result;
}

NSString* _StringToNSString(const FLString &s) {
  return [NSString stringWithCString:(const char*) s.c_str() encoding:NSISOLatin1StringEncoding];
}


std::string _NSStringToStringUTF8(NSString* str) {
  return std::string([str UTF8String]);
}

bool stringsEqual(NSString* _s1, FLString &s2) {
  FLString s1 = NSStringToFLString(_s1);
  //flcout << "comparing <" << s1.length() << "." << s1 << "> and <" << s2.length() << "." << s2 << ">\n";
  return s1.compare(s2) == 0;
}

