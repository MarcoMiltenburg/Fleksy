//
//  AppDelegate.m
//  GestureTest
//
//  Created by Kostas Eleftheriou on 10/30/12.
//  Copyright (c) 2012 Kostas Eleftheriou. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"
#import "DebugGestureRecognizer.h"
#import "TouchAnalyzer.h"
#import "FLTouchEventInterceptor.h"


@implementation AppDelegate

- (void) setLabel:(NSString*) text {
  label.text = text;
}

- (void) setPassedTest:(BOOL) passedTest {
  self.window.backgroundColor = passedTest ? [UIColor blackColor] : [UIColor darkGrayColor];
}

- (void) setSwipeOk:(BOOL) swipeOK {
  if (swipeOK) {
    [greenSwipeButton setTitle:@"SWIPE" forState:UIControlStateNormal];
    [redSwipeButton   setTitle:@"swipe" forState:UIControlStateNormal];
  } else {
    [redSwipeButton   setTitle:@"SWIPE" forState:UIControlStateNormal];
    [greenSwipeButton setTitle:@"swipe" forState:UIControlStateNormal];
  }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
  self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  self.viewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
  
  TouchAnalyzer* touchAnalyzer = [TouchAnalyzer sharedTouchAnalyzer];
  
  
  float paddingTop = 0; //greenSwipeButton.bounds.size.height + button5.bounds.size.height;
  UIView* testView = [[UIView alloc] initWithFrame:CGRectMake(0, paddingTop, self.window.bounds.size.width, self.window.bounds.size.height - paddingTop)];
  testView.backgroundColor = [UIColor darkGrayColor];
  DebugGestureRecognizer* debugRecognizer = [[DebugGestureRecognizer sharedDebugGestureRecognizer] initWithTarget:testView action:nil];
  if (YES) {
    [FLTouchEventInterceptor sharedFLTouchEventInterceptor].forwardRawValues = 1;
    [FLTouchEventInterceptor sharedFLTouchEventInterceptor].shiftValue = CGPointMake(0, -50);
    [FLTouchEventInterceptor sharedFLTouchEventInterceptor].splitSwipesInPoints = 2.5;
    [[FLTouchEventInterceptor sharedFLTouchEventInterceptor] addListener:debugRecognizer];
    [testView addGestureRecognizer:[FLTouchEventInterceptor sharedFLTouchEventInterceptor]];
  } else {
    [testView addGestureRecognizer:debugRecognizer];
  }
  
  [self.viewController.view addSubview:testView];
  
  
  
  greenSwipeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
  [greenSwipeButton setTitle:@"swipe" forState:UIControlStateNormal];
  [greenSwipeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  greenSwipeButton.backgroundColor = [UIColor greenColor];
  greenSwipeButton.showsTouchWhenHighlighted = YES;
  [greenSwipeButton addTarget:debugRecognizer action:@selector(storeLastSwipeOK) forControlEvents:UIControlEventTouchUpInside];
  [self.viewController.view addSubview:greenSwipeButton];
  
  redSwipeButton = [[UIButton alloc] initWithFrame:CGRectMake(100, 0, 100, 40)];
  [redSwipeButton setTitle:@"swipe" forState:UIControlStateNormal];
  [redSwipeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  redSwipeButton.backgroundColor = [UIColor redColor];
  redSwipeButton.showsTouchWhenHighlighted = YES;
  [redSwipeButton addTarget:debugRecognizer action:@selector(storeLastSwipeError) forControlEvents:UIControlEventTouchUpInside];
  [self.viewController.view addSubview:redSwipeButton];
  
  UIButton* button3 = [[UIButton alloc] initWithFrame:CGRectMake(200, 0, 60, 40)];
  [button3 setTitle:@"Clear" forState:UIControlStateNormal];
  [button3 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  button3.backgroundColor = [UIColor whiteColor];
  button3.showsTouchWhenHighlighted = YES;
  [button3 addTarget:debugRecognizer action:@selector(clear) forControlEvents:UIControlEventTouchUpInside];
  [self.viewController.view addSubview:button3];
  
  UIButton* button4 = [[UIButton alloc] initWithFrame:CGRectMake(260, 0, 60, 40)];
  [button4 setTitle:@"Print" forState:UIControlStateNormal];
  [button4 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  button4.backgroundColor = [UIColor brownColor];
  button4.showsTouchWhenHighlighted = YES;
  [button4 addTarget:debugRecognizer action:@selector(print) forControlEvents:UIControlEventTouchUpInside];
  [self.viewController.view addSubview:button4];
  
  
  UIButton* button5 = [[UIButton alloc] initWithFrame:CGRectMake(0, button4.bounds.size.height, 100, 40)];
  [button5 setTitle:@"< Run" forState:UIControlStateNormal];
  [button5 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  button5.backgroundColor = [UIColor orangeColor];
  button5.showsTouchWhenHighlighted = YES;
  [button5 addTarget:touchAnalyzer action:@selector(runPreviousTest) forControlEvents:UIControlEventTouchUpInside];
  [button5 addTarget:touchAnalyzer action:@selector(runPreviousTestUntilFail) forControlEvents:UIControlEventTouchUpOutside];
  [self.viewController.view addSubview:button5];
  
  
  UIButton* button6 = [[UIButton alloc] initWithFrame:CGRectMake(100, button4.bounds.size.height, 100, 40)];
  [button6 setTitle:@"Run >" forState:UIControlStateNormal];
  [button6 setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
  button6.backgroundColor = [UIColor greenColor];
  button6.showsTouchWhenHighlighted = YES;
  [button6 addTarget:touchAnalyzer action:@selector(runNextTest) forControlEvents:UIControlEventTouchUpInside];
  [button6 addTarget:touchAnalyzer action:@selector(runNextTestUntilFail) forControlEvents:UIControlEventTouchUpOutside];
  [self.viewController.view addSubview:button6];
  
  
  label = [[UILabel alloc] initWithFrame:CGRectMake(200, button4.bounds.size.height, 120, 40)];
  label.backgroundColor = [UIColor lightGrayColor];
  label.adjustsFontSizeToFitWidth = YES;
  label.userInteractionEnabled = YES;
  [self.viewController.view addSubview:label];
  
  
  [touchAnalyzer initialize];
  [touchAnalyzer loadTestsFromFile:@"iPad-err"];[touchAnalyzer loadTestsFromFile:@"iPhone-err"];
  [touchAnalyzer loadTestsFromFile:@"iPad-ok"];[touchAnalyzer loadTestsFromFile:@"iPhone-ok"];
  [touchAnalyzer loadTestsFromFile:@"kostas-ok"];
  
  [touchAnalyzer runAllTests];
  
  self.window.rootViewController = self.viewController;
  [self.window makeKeyAndVisible];
  
  //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didUndo:) name:NSUndoManagerDidUndoChangeNotification object:nil];
  
  return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
