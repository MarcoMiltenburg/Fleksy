//
//  FLSignatureViewController.m
//  iFleksy
//
//  Created by Vince Mansel on 8/26/13.
//  Copyright (c) 2013 Syntellia Inc. All rights reserved.
//

#import "FLSignatureViewController.h"
#import "VariousUtilities.h"

@interface FLSignatureViewController ()
{
  UITextView *textView;
}
@end

NSString * const FleksySignatureWillUpdateNotification = @"FleksySignatureWillUpdateNotification";
NSString * const FleksySignatureDidUpdateNotification  = @"FleksySignatureDidUpdateNotification";
NSString * const FleksySignatureKey = @"FleksySignatureKey";

@implementation FLSignatureViewController

//- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
//{
//    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
//    if (self) {
//        // Custom initialization
//    }
//    return self;
//}

- (id)initWithSignature:(NSString *)aSignature {
  
  self = [super initWithNibName:nil bundle:nil];
  if (self) {
    _signature = aSignature;
  }
  return self;
}

//- (void)loadView {
//  NSLog(@"Signature View Loaded");
//}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
  
  textView = [[UITextView alloc] initWithFrame:self.view.frame];
  textView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  if (self.signature == nil) {
    self.signature = @"Typed With Fleksy";
  }
  
  [textView setText:self.signature];
  
  float extra = deviceIsPad() ? 1.5 : 1;
  
  [textView setFont:[UIFont fontWithName:@"HelveticaNeue" size:20.0 * extra]];
  
  [self.view addSubview:textView];
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(handleSave:)];
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(handleUndo:)];
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button Handlers

- (void)handleSave:(id)sender {
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksySignatureDidUpdateNotification
                                                      object:self userInfo:[NSDictionary dictionaryWithObject:[self.signature copy] forKey:FleksySignatureKey]];
  
  self.signature = textView.text;
  
  [[NSNotificationCenter defaultCenter] postNotificationName:FleksySignatureDidUpdateNotification
                                                      object:self userInfo:[NSDictionary dictionaryWithObject:[self.signature copy] forKey:FleksySignatureKey]];
  
  [self.signatureDelegate dismissSignatureVC];
}

- (void)handleUndo:(id)sender {
  
  [textView setText:self.signature];
}

@end
