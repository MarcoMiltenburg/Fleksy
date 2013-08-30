//
//  KeyboardImageView.m
//  Fleksy
//
//  Created by Kostas Eleftheriou on 1/9/12.
//  Copyright (c) 2012 Syntellia Inc. All rights reserved.
//

#import "KeyboardImageView.h"
#import "FLKeyboardView.h"
#import "MathFunctions.h"
#import "Settings.h"
#import "CircleUIView.h"
#import "UITouchManager.h"
#import "VariousUtilities.h"
#import "VariousUtilities2.h"
#include "FleksyUtilities.h"
#import <QuartzCore/QuartzCore.h>
#import "FLThemeManager.h"

#import "FLTypingController_iOS.h"

#define LABEL_FONT_SIZE (deviceIsPad() ? 44 : 30)
#define POPUP_WIDTH  (2*LABEL_FONT_SIZE)
#define POPUP_HEIGHT 70
#define POPUP_SCALE 1
#define RIPPLE_VIEW_TAG 123

#define HIGHLIGHT_KEYS_FOR_SUGGESTIONS 0


@implementation KeyboardImageView

- (FLChar) getNearestCharForPoint:(CGPoint) target {
  FLPoint p = FLPointFromCGPoint(target);
  FLChar c = [FLKeyboardView sharedFLKeyboardView]->keyboard->getNearestChar(p, (FLKeyboardID) self.tag);
  //NSLog(@"getNearestCharForPoint %@: %d", NSStringFromCGPoint(target), c);
  return c;
}


- (CGPoint) getKeyboardPointForChar:(FLChar) c {
  
  //c = FleksyUtilities::toupper(c);
  
  //NSLog(@"getKeyboardPointForChar: %d, toupper: %d", c, FleksyUtilities::toupper(c));
  
  assert(c >= 0 && c < KEY_MAX_VALUE);
  FLPoint result = keyPoints[c];
  
  if (FLPointEqualToPoint(result, FLPointInvalid)) {
    [NSException raise:@"KeyboardImageView getKeyboardPointForChar" format:@"no value for char <%c>", c];
  }
  
  return result;
}

- (void) restoreAllKeyLabelsWithDuration:(float) duration delay:(float) delay {
  //NSLog(@"restoreAllKeyLabelsWithDuration: %.3f, delay: %.3f", duration, delay);
  
  for (UILabel* keyLabel in [keyLabels allValues]) {
    if (duration > 0) {
      [self restoreKeyLabel:keyLabel duration:duration delay:delay];
    } else {
      //[keyLabel.layer performSelector:@selector(removeAllAnimations) withObject:nil afterDelay:delay];
      [keyLabel.layer removeAllAnimations];
      //apparently subview animations are not removed
      for (UIView* subview in keyLabel.subviews) {
        if (subview.tag == RIPPLE_VIEW_TAG) {
          [subview.layer removeAllAnimations];
        }
      }
    }
  }
}


- (FLChar) highlightAtPoint:(CGPoint) point origin:(CGPoint) origin {
  FLChar nearestChar = [self getNearestCharForPoint:point];
  if (nearestChar == ' ') {
    return nearestChar;
  }
  
  popupView.tag = nearestChar;
  
  
  //CGPoint snapPoint = [self getKeyboardPointForChar:nearestChar];
 
  float shiftY = -24; //fmin(hitPoint.y - snapPoint.y, 0) - 35;
  if (deviceIsPad()) {
    shiftY *= 1.5;
  }
  
  //float multiplier = 10.0 / (10.0 + fabs(origin.x - snapPoint.x));
  float shiftMultiplier = CGPointEqualToPoint(point, origin) ? 0.75 : 0.24;
  float scaleMultiplier = CGPointEqualToPoint(point, origin) ? 0.75 : 0;
  
  //this will cause the KeyboardImageView to redraw, can it be avoided?
  UILabel* keyLabel = [keyLabels objectForKey:[NSNumber numberWithChar:nearestChar]];
  keyLabel.transform = CGAffineTransformConcat(CGAffineTransformInvert(self.superview.transform),
                                               CGAffineTransformConcat(CGAffineTransformMakeTranslation(0, shiftY * shiftMultiplier),
                                                                       CGAffineTransformMakeScale(0.5 * (1 + scaleMultiplier), 0.5 * (1 + scaleMultiplier))));
  
  if (CGPointEqualToPoint(point, origin)) {
//    CircleUIView* circle = [[CircleUIView alloc] initWithFrame:keyLabel.bounds];
//    [circle setRadius:32];
//    circle.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:1.0 alpha:0.2];
//    [keyLabel addSubview:circle];
    //keyLabel.backgroundColor = [UIColor colorWithRed:0.8 green:0.8 blue:1 alpha:0.06];
  }
    //  [keyLabel.superview bringSubviewToFront:keyLabel];
  
  [self restoreKeyLabel:keyLabel duration:CGPointEqualToPoint(point, origin) ? 0.25 : 0.2 delay:0.0];
  
  return nearestChar;
}

- (void) popupAtPoint:(CGPoint) target {
  
  FLChar nearestChar = [self getNearestCharForPoint:target];
  if (nearestChar == ' ') {
    return;
  }
  
  //UILabel* keyLabel = [keyLabels objectForKey:[NSNumber numberWithChar:nearestChar]];
  popupView.tag = nearestChar;
  
  NSArray *viewsToRemove = [popupInnerView subviews];
  for (UIView* v in viewsToRemove) {
    [v removeFromSuperview];
  }
  UILabel* label = [keyPopupLabels objectForKey:[NSNumber numberWithChar:nearestChar]];
  [popupInnerView addSubview:label];
  label.center = popupInnerView.center;
  
  CGPoint snap = [self getKeyboardPointForChar:nearestChar];

  imageView.frame = CGRectMake(POPUP_WIDTH/2 - snap.x, POPUP_HEIGHT/2 - (snap.y+2), self.image.size.width/2, self.image.size.height/2);
  
  //we want to be some pixels above the snap point, but we also want to be sure we are at least that many
  //pixels above the actual touchpoing to ensure the popup does not get blocked from view, specially
  //if we touch inside the suggestions and the snap points are all well below the finger
  CGPoint popupCenter = CGPointMake(snap.x, fmin(snap.y, target.y));
  
  
  CGPoint shift = CGPointMake(0, -47);
  //have to make sure we counter the superview transform so that it's always the same number of pixels above
  shift = CGPointApplyAffineTransform(shift, CGAffineTransformInvert(self.superview.transform));
  popupCenter = addPoints(popupCenter, shift);
  
  popupView.center = popupCenter;
  //counter the superview transform to prevent stretching
  popupView.transform = CGAffineTransformInvert(self.superview.transform);
  
  //ensure popup remains completely within the view, eg Q and P popups might be very near the edges
  float delta1 = popupView.frame.origin.x;
  float delta2 = popupView.frame.origin.x + popupView.frame.size.width - self.bounds.size.width;
  if (delta1 < 0) {
    popupView.center = CGPointMake(popupView.center.x - delta1, popupView.center.y);
  }
  if (delta2 > 0) {
    popupView.center = CGPointMake(popupView.center.x - delta2, popupView.center.y);
  }
  
  popupView.hidden = NO;
  [self bringSubviewToFront:popupView];
}

- (void) restoreKeyLabel:(UILabel*) keyLabel duration:(float) duration delay:(float) delay {
    
  //NSLog(@"restoreKeyLabel %@, duration: %.3f, delay: %.3f", keyLabel.text, duration, delay);
  
  [UIView animateWithDuration:duration delay:delay options:UIViewAnimationOptionCurveLinear
                   animations:^{
                     keyLabel.textColor = FLEKSYTHEME.keyboardImageView_keyLabelColor;
                     keyLabel.transform = CGAffineTransformConcat(CGAffineTransformInvert(self.superview.transform), CGAffineTransformMakeScale(0.5, 0.5));
                  }
                   completion:^(BOOL finished){
                     //keyLabel.backgroundColor = [UIColor clearColor];
                   }];
}

- (void) hidePopupWithDuration:(float) duration delay:(float) delay {
  popupView.hidden = YES;
  
  //NSLog(@"hidePopupWithDuration: %.3f, delay: %.3f", duration, delay);
  
  //UILabel* keyLabel = [keyLabels objectForKey:[NSNumber numberWithChar:popupView.tag]];
  //[self restoreKeyLabel:keyLabel];
  [self restoreAllKeyLabelsWithDuration:duration delay:delay];
}

- (UILabel*) createLabelForChar:(FLChar) c atPoint:(CGPoint) point popup:(bool) popup {
  float size = LABEL_FONT_SIZE;
  //if (popup) {
    size *= 2;
  //}
  KSLabel* label = [[KSLabel alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
  
  if (c == '\n') {
    label.text = NEWLINE_UI_CHAR;
  } else if (c == '\t') {
    label.text = @"½";
  } else if (c == BACK_TO_LETTERS) {
    label.text = @"←";
  } else {
    label.text = [[NSString alloc] initWithBytes:&c length:1 encoding:NSISOLatin1StringEncoding];
  }
  
  float featureVersion = 7.0;
  if ([[[UIDevice currentDevice] systemVersion] floatValue] >= featureVersion)
  {
    label.font = popup ? [UIFont fontWithName:@"HelveticaNeue" size:size] : [UIFont fontWithName:@"HelveticaNeue" size:size/*+12*/];
  }
  else {
    label.font = popup ? [UIFont fontWithName:@"HelveticaNeue-Bold" size:size] : [UIFont fontWithName:@"HelveticaNeue-Bold" size:size/*+12*/];
  }
  label.frame = CGRectMake(0, 0, [label.font lineHeight], [label.font lineHeight]);
  
  label.textAlignment = NSTextAlignmentCenter; // UITextAlignmentCenter;
  label.backgroundColor = FLClearColor;
  //label.alpha = 0.5;
  if (!popup) {
    label.center = point;
  }
  
  label.isAccessibilityElement = YES;
  
  
  label.clipsToBounds = NO;
  
  //label.transform = CGAffineTransformMakeScale(0.5, 0.5);
  
  
  // facebook theme
  //label.outlineWidth = 0;
  
  return label;
}

- (id) initWithImage:(UIImage *)image {
  
  self = [super initWithImage:image];
  if (self) {

    self.backgroundColor = FLClearColor;// [UIColor colorWithWhite:0.0 alpha:1];
    
    centroids = [[NSMutableArray alloc] init];
    
    imageView = [[UIImageView alloc] initWithImage:image];
    
    popupView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, POPUP_WIDTH, POPUP_HEIGHT)];
    popupView.layer.shadowOffset = CGSizeMake(0, 5);
    popupView.layer.shadowRadius = 12;
    popupView.layer.shadowOpacity = 1;
    //This will slow down the application. Adding the following line can improve performance as long as your view is visibly rectangular:
    //popupView.layer.shadowPath = [UIBezierPath bezierPathWithRect:popupView.bounds].CGPath;
    popupView.transform = CGAffineTransformMakeScale(POPUP_SCALE, POPUP_SCALE);
    popupView.userInteractionEnabled = NO;
    
    popupInnerView = [[UIView alloc] initWithFrame:popupView.bounds];
    popupInnerView.clipsToBounds = YES;
    popupInnerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2]; // darkGrayColor];
    [popupInnerView addSubview:imageView];
    popupInnerView.layer.cornerRadius = 4;
    [popupView addSubview:popupInnerView];
    
    [self addSubview:popupView];
    [self hidePopupWithDuration:0 delay:0];
    
    //seems that by default this is off for UIImageViews
    //self.userInteractionEnabled = YES;
    //self.multipleTouchEnabled = YES;
    
    lastTransform = CGAffineTransformIdentity;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleThemeDidChange:) name:FleksyThemeDidChangeNotification object:nil];
  }
  return self;
}

#pragma mark - FLTheme Notification Handlers

- (void)handleThemeDidChange:(NSNotification *)aNote {
  NSLog(@"%s = %@", __PRETTY_FUNCTION__, aNote);
  
  if (!FLEKSY_APP_SETTING_SPACE_BUTTON) {
    homeRowStripe.backgroundColor = FLEKSYTHEME.keyboardImageView_homeStripeBackgroundColor;
  } else {
    //TODO (Clean up) This displays a "fun" strip of fleksyBalls in the homeRow if SPACE_BUTTON enabled only.
    homeRowStripe.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"Icon.png"]];
  }
  
  if (keyLabels && keyPopupLabels) {
        
  // This is preferable to having individual keys listenting and then sending multiple notification to be handled by each keyLabel.

    for (KSLabel *keyLabel in [keyLabels allValues]) {
      if (!deviceIsPad()) {
        keyLabel.outlineColor = FLEKSYTHEME.keyboardImageView_label_outlineColor;
        keyLabel.outlineWidth = FLEKSYTHEME.keyboardImageView_label_outlineWidth;
      }
      keyLabel.textColor = FLEKSYTHEME.keyboardImageView_label_textColor; //[UIColor lightGrayColor];
    }
    
    
    for (KSLabel *keyLabel in [keyPopupLabels allValues]) {
      if (!deviceIsPad()) {
        keyLabel.outlineColor = FLEKSYTHEME.keyboardImageView_label_outlineColor;
        keyLabel.outlineWidth = FLEKSYTHEME.keyboardImageView_label_outlineWidth;
      }
      keyLabel.textColor = FLEKSYTHEME.keyboardImageView_label_textColorForPopup; //[UIColor lightGrayColor];
    }
  }
}


- (void) addButtonCentroid:(CGPoint) point color:(UIColor*) color {
  int size = 26;
  UIView* buttonCentroid = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size, size)];
  buttonCentroid.center = point;
  buttonCentroid.backgroundColor = color;
  buttonCentroid.alpha = 0.7;
  buttonCentroid.userInteractionEnabled = NO;
  [self addSubview:buttonCentroid];
  [self sendSubviewToBack:buttonCentroid];
  
  [centroids addObject:buttonCentroid];
}

- (void) setKeys:(FLPoint[]) _keys {
  
  for (int i = 0; i < KEY_MAX_VALUE; i++) {
    keyPoints[i] = _keys[i];
  }
  
  keyLabels = [[NSMutableDictionary alloc] init];
  keyPopupLabels = [[NSMutableDictionary alloc] init];
  
  for (int c = 0; c < KEY_MAX_VALUE; c++) {
    
    NSNumber* key = [NSNumber numberWithChar:c];
    CGPoint point = CGPointMake(keyPoints[c].x, keyPoints[c].y);
    if (!FLPointEqualToPoint(point, FLPointInvalid)) {
      
      FLChar existing = [self getNearestCharForPoint:point];
      //CGPoint p = [self getKeyboardPointForChar:existing];
      UILabel* existingLabel = [keyLabels objectForKey:[NSNumber numberWithChar:existing]];
      
      if (existingLabel) {
        //NSString* temp = [[NSString alloc] initWithBytes:&c length:1 encoding:NSISOLatin1StringEncoding];
        //NSLog(@"will not create new label %@, we already have %c (%d)", temp, existing, existing);
      } else {
      
        UILabel* label = [self createLabelForChar:c atPoint:point popup:NO];
        [keyLabels setObject:label forKey:key];
        [self addSubview:label];
      
        UILabel* popupLabel = [self createLabelForChar:c atPoint:point popup:YES];
        [keyPopupLabels setObject:popupLabel forKey:key];
      }
    }
  }
  
  
  if (!FLPointEqualToPoint(_keys['Q'], FLPointInvalid)) {
    homeRowStripe = [[UIView alloc] init];
    [self addSubview:homeRowStripe];
    [self sendSubviewToBack:homeRowStripe];
  } else {
    homeRowStripe = nil;
  }

  
  [self handleThemeDidChange:nil];
  
  
  ///////////////////////////////////////////////
  // Show button centroids for debugging
//  if (NO) {
//    for (NSNumber* key in keyPoints) {
//      char c = [key charValue];
//      for (NSValue* pointValue in [keyPoints objectForKey:key]) {
//        CGPoint point = [pointValue CGPointValue];
//        [self addButtonCentroid:point color:[UIColor redColor]];
//      }
//    }
//  }
}





- (void) doRippleForPoint:(CGPoint) pointToUse sharp:(BOOL) sharp {
  
  //UIView* view = self.superview.superview;
  FLChar nearestChar = [self getNearestCharForPoint:pointToUse];
  //pointToUse = [self getKeyboardPointForChar:nearestChar];
  //pointToUse = CGPointApplyAffineTransform(pointToUse, self.superview.transform);
  UILabel* keyLabel = [keyLabels objectForKey:[NSNumber numberWithChar:nearestChar]];
  
  
  float multiplierX = deviceIsPad() ? 1.12 * 4.0 : 1.0;
  float multiplierY = deviceIsPad() ? 1.12 * 3.0 : 1.0;
  
  UIView* touchTrace = [[UIView alloc] initWithFrame:sharp ? CGRectMake(0, 0, 50*1.2*multiplierX, 65*1.2*multiplierY) : CGRectMake(0, 0, 50*multiplierX, 65*multiplierY)];
  touchTrace.userInteractionEnabled = NO;
  touchTrace.layer.cornerRadius = 5 * multiplierX;
  touchTrace.center = CGPointMake(keyLabel.bounds.size.width * 0.5, keyLabel.bounds.size.height * 0.5);
  touchTrace.backgroundColor = FLEKSYTHEME.keyboardImageView_touchTrace_backgroundColor; //[UIColor colorWithRed:1 green:0 blue:1 alpha:1]; // [UIColor greenColor];
  touchTrace.alpha = FLEKSYTHEME.keyboardImageView_touchTrace_alpha;
  touchTrace.tag = RIPPLE_VIEW_TAG;
  [keyLabel addSubview:touchTrace];
  
  [self clearRippleForKey:keyLabel sharp:sharp];
}

- (void) clearRippleForKey:(UILabel*) keyLabel sharp:(BOOL) sharp {
  
  for (UIView* subview in keyLabel.subviews) {
    if (subview.tag == RIPPLE_VIEW_TAG) {
      float duration = sharp ? 0.4 : 0.3;
      if (deviceIsPad()) {
        duration *= 1.5;
      }
      [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionCurveLinear
                       animations:^{
                         subview.alpha = 0;
                         if (!deviceIsPad()) {
                           float scaleFactor = sharp ? 1 : 2.5;
                           subview.transform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
                         }
                       }
                       completion:^(BOOL finished){
                         [subview removeFromSuperview];
                       }];
    }
  }
}

- (void) doSidePopupForPoint:(CGPoint) point {
  
  const FLChar nn = 209;// Spanish Ñ
  FLChar c = [self getNearestCharForPoint:point];
  
  switch (c) {
    case 'Q':
      [self highlightAtPoint:[self getKeyboardPointForChar:'W'] origin:point];
      break;
    case 'W':
      [self highlightAtPoint:[self getKeyboardPointForChar:'Q'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'E'] origin:point];
      break;
    case 'E':
      [self highlightAtPoint:[self getKeyboardPointForChar:'W'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'R'] origin:point];
      break;
    case 'R':
      [self highlightAtPoint:[self getKeyboardPointForChar:'E'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'T'] origin:point];
      break;
    case 'T':
      [self highlightAtPoint:[self getKeyboardPointForChar:'R'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'Y'] origin:point];
      break;
    case 'Y':
      [self highlightAtPoint:[self getKeyboardPointForChar:'T'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'U'] origin:point];
      break;
    case 'U':
      [self highlightAtPoint:[self getKeyboardPointForChar:'Y'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'I'] origin:point];
      break;
    case 'I':
      [self highlightAtPoint:[self getKeyboardPointForChar:'U'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'O'] origin:point];
      break;
    case 'O':
      [self highlightAtPoint:[self getKeyboardPointForChar:'I'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'P'] origin:point];
      break;
    case 'P':
      [self highlightAtPoint:[self getKeyboardPointForChar:'O'] origin:point];
      break;
      
    case 'A':
      [self highlightAtPoint:[self getKeyboardPointForChar:'S'] origin:point];
      break;
    case 'Z':
      [self highlightAtPoint:[self getKeyboardPointForChar:'X'] origin:point];
      break;
    case 'S':
      [self highlightAtPoint:[self getKeyboardPointForChar:'A'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'D'] origin:point];
      break;
    case 'D':
      [self highlightAtPoint:[self getKeyboardPointForChar:'S'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'F'] origin:point];
      break;
    case 'F':
      [self highlightAtPoint:[self getKeyboardPointForChar:'D'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'G'] origin:point];
      break;
    case 'G':
      [self highlightAtPoint:[self getKeyboardPointForChar:'F'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'H'] origin:point];
      break;
    case 'H':
      [self highlightAtPoint:[self getKeyboardPointForChar:'G'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'J'] origin:point];
      break;
    case 'J':
      [self highlightAtPoint:[self getKeyboardPointForChar:'H'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'K'] origin:point];
      break;
    case 'K':
      [self highlightAtPoint:[self getKeyboardPointForChar:'J'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'L'] origin:point];
      break;
    case 'X':
      [self highlightAtPoint:[self getKeyboardPointForChar:'Z'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'C'] origin:point];
      break;
    case 'C':
      [self highlightAtPoint:[self getKeyboardPointForChar:'X'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'V'] origin:point];
      break;
    case 'V':
      [self highlightAtPoint:[self getKeyboardPointForChar:'C'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'B'] origin:point];
      break;
    case 'B':
      [self highlightAtPoint:[self getKeyboardPointForChar:'V'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'N'] origin:point];
      break;
    case 'N':
      [self highlightAtPoint:[self getKeyboardPointForChar:'B'] origin:point];
      [self highlightAtPoint:[self getKeyboardPointForChar:'M'] origin:point];
      break;
    case 'L': {
      [self highlightAtPoint:[self getKeyboardPointForChar:'K'] origin:point];
      
      NSNumber* key = [NSNumber numberWithChar:nn];
      UILabel* label = [keyLabels objectForKey:key];
      if (label) {
        [self highlightAtPoint:[self getKeyboardPointForChar:nn] origin:point];
      }
      break;
    }
    case 'M':
      [self highlightAtPoint:[self getKeyboardPointForChar:'N'] origin:point];
      break;
    case nn:
      [self highlightAtPoint:[self getKeyboardPointForChar:'L'] origin:point];
      break;
    default:
      break;
  }
}

- (void) doPopupForTouch:(UITouch*) touch {
  
  if (touch.didFeedback) {
    NSLog(@"touch.didFeedback already!");
    //return;
  }
  
  touch.didFeedback = YES;
  CGPoint pointToUse = [touch locationInView:self];
  [self doPopupForPoint:pointToUse];
}

- (void) doPopupForPoint:(CGPoint) point {
  
  //[self hidePopupWithDuration:0 delay:0];
  
  [self doRippleForPoint:point sharp:NO];
  
  if (deviceIsPad()) {
    return;
  }
  
  //double startTime = CFAbsoluteTimeGetCurrent();
  //[NSObject cancelPreviousPerformRequestsWithTarget:self];
  //NSLog(@"touch (%.1f, %.1f)", point.x, point.y);
  if (point.y >= 0 || [self keyIsEnabled:'@']) {
    //[self popupAtPoint:point];
    [self highlightAtPoint:point origin:point];
    [self doSidePopupForPoint:point];
  }
  //NSLog(@"processPopupTouches took %.6f", CFAbsoluteTimeGetCurrent() - startTime);
  
  //MyAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, @"Swipe Left test");
}


- (void) touchesBegan:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesBegan:touches withEvent:event];
  NSLog(@"touches began KeyboardImageView! %@", touches);
}

- (void) touchesMoved:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesMoved:touches withEvent:event];
  NSLog(@"touches moved KeyboardImageView! %@", touches);
}

- (void) touchesEnded:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesEnded:touches withEvent:event];
  NSLog(@"touches ended KeyboardImageView! %@", touches);
}

- (void) touchesCancelled:(NSSet *) touches withEvent:(UIEvent *) event {
  [super touchesCancelled:touches withEvent:event];
  NSLog(@"touches cancelled KeyboardImageView! %@", touches);
}

//- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
//  NSLog(@"accessibilityScroll %d", direction);
//}

- (void) layoutSubviews {
  
  NSLog(@"KeyboardImageView layoutSubviews (%@)", self);
  
  // changing the transform of the labels on popup triggers a layout that is uneccessary
  if (!CGAffineTransformIsIdentity(lastTransform) && CGAffineTransformEqualToTransform(lastTransform, self.superview.transform)) {
    //NSLog(@"skipping KeyboardImageView layout");
    return;
  }
  
  //NSLog(@"KeyboardImageView layout %x, self.superview: %@, self.superview.transform: %@", self, self.superview, NSStringFromCGAffineTransform(self.superview.transform));
  
  // invert potential stretch effect of parent, plus default size of labels is half scale to prevent aliasing when enlarged
  // seems that order of concat here does not make a difference?
  CGAffineTransform t = CGAffineTransformConcat(CGAffineTransformInvert(self.superview.transform), CGAffineTransformMakeScale(0.5, 0.5));
  for (UIView* subview in self.subviews) {
    if ([subview isKindOfClass:[UILabel class]]) {
      subview.transform = t;
    }
  }
  
  if (homeRowStripe) {
    CGPoint q = [self getKeyboardPointForChar:'Y'];
    CGPoint a = [self getKeyboardPointForChar:'A'];
    CGPoint z = [self getKeyboardPointForChar:'M'];
    float top = (q.y + a.y) * 0.5;
    float height = (a.y + z.y) * 0.5 - top;
    homeRowStripe.frame = CGRectMake(0, top, self.bounds.size.width, height);
  }
  
//  for (NSNumber* key in keyPopupLabels) {
//    UILabel* label = [keyPopupLabels objectForKey:key];
//    label.transform = CGAffineTransformInvert(self.superview.transform);
//  }
  
  
  lastTransform = self.superview.transform;
  
  //NSLog(@"KeyboardImageView layout %x DONE", self);
}

- (BOOL) keyIsEnabled:(FLChar) c {
  return (!FLPointEqualToPoint(keyPoints[c], FLPointInvalid));
}

- (void) highlightKeysForWord:(NSString*) wordString {

  NSArray* characters = [VariousUtilities explodeString:wordString];
  for (NSString* character in characters) {
    char c = [character characterAtIndex:0];
    FLKeyboard* keyboard = [FLKeyboardView sharedFLKeyboardView]->keyboard;
    if (keyboard->isalpha(c)) {
      c = keyboard->toupper(c);
      [self highlightKey:c off:NO];
    }
  }
}

- (void) unhighlightAllKeys {
  
//  for (int i = 'A'; i < 'Z'; i++) {
//    [self highlightKey:i off:YES];
//  }
}

- (void) highlightKey:(FLChar) c off:(BOOL) off {
  NSNumber* key = [NSNumber numberWithChar:c];
  UILabel* label = [keyLabels objectForKey:key];
  
  //label.textColor = off ? [UIColor whiteColor] : [UIColor colorWithRed:0.3 green:0.5 blue:0.9 alpha:1];
  
//  if (off) {
//    //label.textColor = [UIColor whiteColor];
//    label.outlineColor = [UIColor blackColor];
//    label.outlineWidth = 2;
//    [label setNeedsDisplay];
//  } else {
//    //label.textColor = [UIColor redColor];
//    label.outlineColor = [UIColor colorWithRed:0.3 green:0.5 blue:1 alpha:1];
//    label.outlineWidth = 6;
//    [label setNeedsDisplay];
//    [self performSelector:@selector(unhighlightAllKeys) withObject:nil afterDelay:0.4];
//  }
  
  [self doRippleForPoint:label.center sharp:YES];
  //[self highlightAtPoint:label.center origin:label.center];
}

- (void) disableKey:(FLChar) c {
  NSNumber* key = [NSNumber numberWithChar:c];
  UILabel* label = [keyLabels objectForKey:key];
  label.alpha = 0.0;
  
  CGPoint point = keyPoints[c];
  if (!FLPointEqualToPoint(point, FLPointInvalid)) {
    disabledKeyPoints[c] = point;
    keyPoints[c] = FLPointInvalid;
    [FLKeyboardView sharedFLKeyboardView]->keyboard->setPointForChar(FLPointInvalid, c, (FLKeyboardID) self.tag);
  }
}

- (void) enableKey:(FLChar) c {
  NSNumber* key = [NSNumber numberWithChar:c];
  UILabel* label = [keyLabels objectForKey:key];
  label.alpha = 1.0;
  
  CGPoint point = disabledKeyPoints[c];
  if (!FLPointEqualToPoint(point, FLPointInvalid)) {
    keyPoints[c] = point;
    disabledKeyPoints[c] = FLPointInvalid;
    [FLKeyboardView sharedFLKeyboardView]->keyboard->setPointForChar(point, c, (FLKeyboardID) self.tag);
  }
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
