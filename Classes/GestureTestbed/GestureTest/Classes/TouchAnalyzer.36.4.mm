//
//  SwipeTester.m
//  GestureTest
//
//  Created by Kostas Eleftheriou on 11/13/12.
//  Copyright (c) 2012 Kostas Eleftheriou. All rights reserved.
//

#import "TouchAnalyzer.h"
#import "UITouchManager.h"
#import "MathFunctions.h"
#import "SynthesizeSingleton.h"
#import "DebugGestureRecognizer.h"
#import "AppDelegate.h"

#define NSLog(format,...) if (print) {NSLog(format, ##__VA_ARGS__);}

#define FIRST_LAST_DISTANCE_THRESHOLD 15

static NSMutableArray* touchTests;

@implementation TouchAnalyzer

SYNTHESIZE_SINGLETON_FOR_CLASS(TouchAnalyzer);

- (void) initialize {
  touchTests = [[NSMutableArray alloc] init];
}

- (void) loadTestsFromFile:(NSString*) filename {
  
  NSString* filePath = [[NSBundle mainBundle] pathForResource:filename ofType:@"txt"];
  NSError* error;
  NSString* contents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
  
  //NSLog(@"contents: %@, error: %@", contents, error);
  
  for (NSString* touchString in [contents componentsSeparatedByString:@"TOUCH_KIND: "]) {
    if (!touchString.length) {
      continue;
    }
    //NSLog(@"swipe:\n%@", swipe);
    FLTouch* touch = [[FLTouch alloc] initFromString:touchString];
    [touchTests addObject:touch];
  }
  
  currentTest = -1;
  
  //NSLog(@"Loaded %d tests", touchTests.count);
}

- (void) runAllTests {
  int totalPositives = 0;
  int totalNegatives = 0;
  int falsePositives = 0;
  int falseNegatives = 0;
  for (int i = 0; i < touchTests.count; i++) {
    FLTouch* touch = [touchTests objectAtIndex:i];
    if (![self checkTouchPassedTest:touch print:NO]) {
      if (touch.kind == UITouchKindSwipe) {
        falseNegatives++;
      } else {
        falsePositives++;
      }
    }
    if (touch.kind == UITouchKindSwipe) {
      totalPositives++;
    } else {
      totalNegatives++;
    }
  }
  printf("Run %d tests, falsePositives: %d (%.2f%%), falseNegatives: %d (%.2f%%), ERROR RATE: %.2f%%\n",
        touchTests.count, falsePositives, 100.0 * falsePositives / totalNegatives, falseNegatives, 100.0 * falseNegatives / totalPositives, 100.0 * (falsePositives + falseNegatives) / touchTests.count);

}

- (void) runNextTestUntilFail {
  while ([self runNextTest]) {}
}

- (void) runPreviousTestUntilFail {
  while ([self runPreviousTest]) {}
}

- (BOOL) runNextTest {
  currentTest++;
  return [self runCurrentTest];
}

- (BOOL) runPreviousTest {
  currentTest--;
  return [self runCurrentTest];
}

- (BOOL) runCurrentTest {
  if (currentTest < 0) {
    printf(" > Reached beginning of tests\n");
    currentTest = 0;
    return NO;
  }
  if (currentTest > touchTests.count-1) {
    printf(" > Reached end of tests\n");
    currentTest = touchTests.count - 1;
    return NO;
  }
  
  DebugGestureRecognizer* recognizer = [DebugGestureRecognizer sharedDebugGestureRecognizer];
  FLTouch* touch = [touchTests objectAtIndex:currentTest];
  [recognizer showTouch:touch inView:[[UIApplication sharedApplication].windows objectAtIndex:0]];
  return [self checkTouchPassedTest:touch print:YES];
}



+ (FLTouch*) OLD_deltas:(FLTouch*) touch allowSkipFirst:(BOOL) allowSkipFirst allowSkipLast:(BOOL) allowSkipLast {
  
  BOOL print = YES;
  
  NSMutableArray* result = [[NSMutableArray alloc] init];
  
  if (touch.path.count) {
    
    // if A then include first v
    if (!allowSkipFirst && !allowSkipLast) {
      [result addObject:[touch.path objectAtIndex:0]];
    }
    for (int i = 0; i < touch.path.count-1; i++) {
      PathPoint* point1 = [touch.path objectAtIndex:i];
      PathPoint* point2 = [touch.path objectAtIndex:i+1];
      UITouchPhase phase = UITouchPhaseMoved;
      if (i == touch.path.count-2) {
        phase = UITouchPhaseEnded;
      }
      CGPoint delta = subtractPoints(point2.location, point1.location);
      if (phase == UITouchPhaseEnded && magnitude(delta) <= FIRST_LAST_DISTANCE_THRESHOLD && allowSkipLast) {
        NSLog(@"skipping last point");
      } else if (i == 0 && magnitude(delta) <= FIRST_LAST_DISTANCE_THRESHOLD && allowSkipFirst) {
        NSLog(@"skipping first point");
      } else {
        PathPoint* deltaPoint = [[PathPoint alloc] initWithLocation:delta timestamp:0 phase:phase];
        [result addObject:deltaPoint];
      }
    }
  }
  
  return [[FLTouch alloc] initWithPath:result kind:touch.kind];
}

+ (FLTouch*) deltas:(FLTouch*) touch skipFirst:(BOOL) skipFirst skipLast:(BOOL) skipLast addFirstRaw:(BOOL) addFirstRaw {
  
  assert(!(skipFirst && addFirstRaw));
  
  BOOL print = YES;
  
  NSMutableArray* result = [[NSMutableArray alloc] init];
  
  if (addFirstRaw) {
    PathPoint* point1 = [touch.path objectAtIndex:0];
    CGPoint location = multiplyPoint(point1.location, 0.7);
    PathPoint* point2 = [[PathPoint alloc] initWithLocation:location timestamp:0 phase:UITouchPhaseStationary];
    [result addObject:point2];
  }
  
  int startIndex = 1;
  int endIndex = touch.path.count;
  if (skipFirst) {
    startIndex++;
  }
  if (skipLast) {
    endIndex--;
  }
  
  assert(startIndex <= endIndex);
  
  for (int i = startIndex; i < endIndex; i++) {
    PathPoint* point1 = [touch.path objectAtIndex:i-1];
    PathPoint* point2 = [touch.path objectAtIndex:i];
    CGPoint delta = subtractPoints(point2.location, point1.location);
    PathPoint* deltaPoint = [[PathPoint alloc] initWithLocation:delta timestamp:0 phase:UITouchPhaseStationary];
    [result addObject:deltaPoint];
  }
  
  return [[FLTouch alloc] initWithPath:result kind:UITouchKindUnknown];
}

- (BOOL) checkTouchPassedTest:(FLTouch*) touch print:(BOOL)print {
  
  UITouchKind kind = [TouchAnalyzer getKindForTouch:touch print:print];
  BOOL passedTest = kind == touch.kind;
  
  //  if (print) {
  //    AppDelegate* appDelegate = [UIApplication sharedApplication].delegate;
  //    [appDelegate setSwipeOk:isOkSwipe];
  //    [appDelegate setPassedTest:passedTest];
  //    [appDelegate setLabel:[NSString stringWithFormat:@"%d/%d", currentTest+1, swipeTests.count]];
  //  }
  
  NSLog(@"Test %d/%d, calculated kind: %d, actual kind: %d, dt: %.3f, %@",
        currentTest+1, touchTests.count, kind, touch.kind, touch.dt, passedTest ? @"passed" : @" !! FAILED !!");
  
  return passedTest;
}

+ (BOOL) isTap:(FLTouch*) touch {
  
  float pairThreshold = 20;
  float startThreshold = 20;
  
  float maxPairDistance = -1;
  float maxStartDistance = -1;
  
  for (int i = 1; i < touch.path.count; i++) {
    PathPoint* point1 = [touch.path objectAtIndex:i-1];
    PathPoint* point2 = [touch.path objectAtIndex:i];
    float pairDistance = distanceOfPoints(point1.location, point2.location);
    float startDistance = distanceOfPoints(point2.location, touch.startPoint);
    maxPairDistance = fmaxf(maxPairDistance, pairDistance);
    maxStartDistance = fmaxf(maxStartDistance, startDistance);
  }

  BOOL result = maxStartDistance < startThreshold && maxPairDistance < pairThreshold;
  //BOOL print = YES; NSLog(@"isTap: %d, maxPairDistance: %.3f, maxStartDistance: %.3f", result, maxPairDistance, maxStartDistance);
  return result;
}


+ (float) getDirectionErrorForTouch:(FLTouch*) touch threshold:(float) threshold normalize:(BOOL) normalize {
  float result = 0;
  float totalWeights = 0;
  for (int i = 2; i < touch.path.count; i++) {
    
    PathPoint* pathPoint0 = [touch.path objectAtIndex:i-2];
    PathPoint* pathPoint1 = [touch.path objectAtIndex:i-1];
    PathPoint* pathPoint2 = [touch.path objectAtIndex:i];
    
    //double dt = pathPoint2.timestamp - pathPoint1.timestamp;
    CGPoint translation = subtractPoints(pathPoint2.location, pathPoint1.location);
    //CGPoint velocity = dividePoint(translation, dt);
    //NSLog(@"%d. translation: %.3f, dt: %.6f, t1: %.6f, t2: %.6f", i, magnitude(translation), dt, previousPoint.timestamp, pathPoint.timestamp);
    //double previousDt = pathPoint1.timestamp - pathPoint0.timestamp;
    CGPoint previousTranslation = subtractPoints(pathPoint1.location, pathPoint0.location);
    //CGPoint previousVelocity = dividePoint(previousTranslation, previousDt);
    //CGPoint acceleration = dividePoint(subtractPoints(velocity, previousVelocity), dt);
    
    float slope1 = slopeOfPoint(translation);
    float slope2 = slopeOfPoint(previousTranslation);
    float slopeError = fabsf(differenceOfAngles(slope1, slope2));
    
    slopeError *= magnitude(translation) * magnitude(previousTranslation) / (powf(touch.travelDistance / touch.path.count-1, 2));
    if (slopeError < threshold) {
      slopeError = 0;
    }
    
    float slopeWeight = 1;
    if (i == 2 || i == touch.path.count-1) {
      slopeWeight = 0.45;
    }
    
    result += slopeError * slopeWeight;
    
    totalWeights += slopeWeight;
  }
  
  if (normalize) {
    result /= totalWeights;
  }
  
  assert(isfinite(result));
  return result;
}

+ (UITouchKind) getKindForTouch:(FLTouch*) touch print:(BOOL) print {
  
  if ([TouchAnalyzer isTap:touch]) {
    return UITouchKindTap;
  }
  
  if (touch.endpointDistance > 120) {
    return UITouchKindSwipe;
  }
  
  BOOL isOkSwipe = YES;
  
  float firstDistance = touch.firstDistance;
  float lastDistance = touch.lastDistance;
  
  BOOL useFirstForDeviation = firstDistance > FIRST_LAST_DISTANCE_THRESHOLD;
  BOOL useLastForDeviation = lastDistance > FIRST_LAST_DISTANCE_THRESHOLD;
  
  if (touch.path.count < 4) {
    //NSLog(@"swipe.path.count: %d", swipe.path.count);
    useFirstForDeviation = YES;
    useLastForDeviation = YES;
  }

  float directionError1 = [TouchAnalyzer getDirectionErrorForTouch:touch threshold:0.2 normalize:NO];
  //return directionError1 > 3.15 ? UITouchKindPhantomSwipeI : UITouchKindSwipe;
  //float directionError2 = [TouchAnalyzer getDirectionErrorForTouch:touch threshold:0.2 normalize:YES];
  //return directionError2 > 1.02 ? UITouchKindPhantomSwipeI : UITouchKindSwipe;

  
  int startIndex = useFirstForDeviation ? 0 : 1;
  int endIndex = touch.path.count - (useLastForDeviation ? 1 : 2);
  int n = endIndex - startIndex;
  
  float numbers1[n];
  
  for (int i = startIndex; i < endIndex; i++) {
    PathPoint* point1 = [touch.path objectAtIndex:i];
    PathPoint* point2 = [touch.path objectAtIndex:i+1];
    CGPoint vector = subtractPoints(point2.location, point1.location);
    //vector = dividePoint(vector, point2.timestamp - point1.timestamp);
    numbers1[i - startIndex] = magnitude(vector);
  }
  
  //for (int i = 0; i < n; i++) {
  //  NSLog(@"numbers1[%d]: %.3f", i, numbers1[i]);
  //}
  
  float center1 = average(numbers1, n);
  float sum1 = sum(numbers1, n);
  float deviation1 = standardDeviation(numbers1, n);
  float normalizedDeviation1 = deviation1 / center1;
  
  NSLog(@"nPointsUsed: %d, useFirstForDeviation: %d, useLastForDeviation: %d, startIndex: %d, endIndex: %d",
        n+1, useFirstForDeviation, useLastForDeviation, startIndex, endIndex);
  NSLog(@"center1: %.3f, deviation1: %.6f, normalizedDeviation1: %.3f, sum1: %.3f", center1, deviation1, normalizedDeviation1, sum1);

    
  float travelDistance = touch.travelDistance;
  
  
  assert(isfinite(normalizedDeviation1));
  

  if (travelDistance < 120) {
    if (directionError1 > 3.2) {
      isOkSwipe = NO;
    }
    if (normalizedDeviation1 > 0.6) {
      isOkSwipe = NO;
    }

    if (n > 1) {
      float* numbers2 = deltas(numbers1, n);
//      for (int i = 0; i < n-1; i++) {
//        NSLog(@"numbers2[%d]: %.3f", i, numbers2[i]);
//      }
//      float* numbers2Abs = abs(numbers2, n-1);
//      float sum2 = sum(numbers2, n-1);
//      float sum2Abs = sum(numbers2Abs, n-1);
      float center2 = average(numbers2, n-1);
//      float deviation2 = standardDeviation(numbers2, n-1);
//      float normalizedDeviation2 = deviation2 / center2;
//      NSLog(@"center2: %.3f, deviation2: %.6f, normalizedDeviation2: %.3f, sum2: %.3f, sum2Abs: %.3f", center2, deviation2, normalizedDeviation2, sum2, sum2Abs);
      
      if (n > 2) {
        float* numbers3 = deltas(numbers2, n-1);
//        for (int i = 0; i < n-2; i++) {
//          NSLog(@"numbers3[%d]: %.3f", i, numbers3[i]);
//        }
//        float* numbers3Abs = abs(numbers3, n-2);
        float sum3 = sum(numbers3, n-2);
//        float sum3Abs = sum(numbers3Abs, n-2);
//        float center3 = average(numbers3, n-2);
//        float deviation3 = standardDeviation(numbers3, n-2);
//        float normalizedDeviation3 = deviation3 / center3;
//        NSLog(@"center3: %.3f, deviation3: %.6f, normalizedDeviation3: %.3f, sum3: %.3f, sum3Abs: %.3f", center3, deviation3, normalizedDeviation3, sum3, sum3Abs);
//        NSLog(@"F: %.3f, numberOfPeaks: %d", sum2Abs / (fabs(sum2) * fabs(sum3)), numberOfPeaks(numbers3, n-2, 3));
        
        if (center2 < -3 && sum3 > 9) {
          isOkSwipe = NO;
        }
        
//        if (sum3 > 25) {
//          isOkSwipe = NO;
//        }
      }
      
    }
  }
  

  
  FLTouch* vs = [TouchAnalyzer deltas:touch skipFirst:!useFirstForDeviation skipLast:!useLastForDeviation addFirstRaw:NO];
  FLTouch* as = [TouchAnalyzer deltas:vs skipFirst:NO skipLast:NO addFirstRaw:YES];
  
  int i = 0;
  for (PathPoint* pathPoint in vs.path) {
    NSLog(@"%d vs: %@", i++, NSStringFromCGPoint(pathPoint.location));
  }
  i = 0;
  for (PathPoint* pathPoint in as.path) {
    NSLog(@"%d as: %@", i++, NSStringFromCGPoint(pathPoint.location));
  }
  

  float travelDistanceA = 0;
  float totalDotA = 0;
  float totalPositiveDotA = 0;
  float totalNegativeDotA = 0;
  float totalWeights = 0;
  for (int i = 0; i < as.path.count; i++) {
    PathPoint* point1 = [as.path objectAtIndex:i];
    travelDistanceA += magnitude(point1.location);
    if (i < as.path.count-1) {
      PathPoint* point2 = [as.path objectAtIndex:i+1];
      float dot = dotProduct(point1.location, point2.location);
      if (dot < 0) {
        dot = -powf(fabs(dot), 1.1);
      } else {
        //dot = powf(dot, 0.5);
      }
      NSLog(@"%d as dot: %.3f, sum: %.3f", i, dot, magnitude(point1.location) + magnitude(point2.location));
      
      float weight = 1;
      
      dot *= weight;
      totalWeights += weight;
      
      if (fabs(dot) < 0.02) {
        //dot = 0;
      }
      
      totalDotA += dot;

      if (dot > 0) {
        totalPositiveDotA += dot;
      } else {
        totalNegativeDotA += dot;
      }
    }
  }
  
  float normalizer = travelDistanceA; // * as.path.count;
  //float normalizer = as.path.count;
  //float normalizer = totalWeights;
  totalDotA /= normalizer;
  totalNegativeDotA /= normalizer;
  totalPositiveDotA /= normalizer;
  
  
  
  
  float totalDotV = 0;
  float totalNegativeDotV = 0;
  float totalPositiveDotV = 0;
  for (int i = 1; i < vs.path.count; i++) {
    PathPoint* point1 = [vs.path objectAtIndex:i-1];
    PathPoint* point2 = [vs.path objectAtIndex:i];
    float dot = dotProduct(point1.location, point2.location);
    //dot -= dotProduct(point1.location, point1.location);
    //dot = fabsf(dot);
    
    totalDotV += dot;
    if (dot > 0) {
      totalPositiveDotV += dot;
    } else {
      totalNegativeDotV += dot;
    }
  }
  float norm = 1; //touch.travelDistance;// * as.path.count;
  totalDotV /= norm;
  totalNegativeDotV /= norm;
  totalPositiveDotV /= norm;
  
  
  
  //isOkSwipe = YES;
  if (totalDotA < -4.5) {
    isOkSwipe = NO;
  }
  
  if (totalNegativeDotV < 0) {
    //isOkSwipe = NO;
  }
  
  if (totalDotV < 3) {
    //isOkSwipe = NO;
  }
  
  
  NSLog(@"directionError1: %.3f, travelDistanceA: %.3f, totalDotA: %.3f, totalDotAN: %.3f, totalPositiveDotA: %.3f, totalNegativeDotA: %.3f, totalDotV: %.3f, totalPositiveDotV: %.3f, totalNegativeDotV: %.3f, ",
        directionError1, travelDistanceA, totalDotA, totalDotA / travelDistanceA, totalPositiveDotA, totalNegativeDotA, totalDotV, totalPositiveDotV, totalNegativeDotV);
  
  
  //
  int count = touch.path.count;
  if (!useFirstForDeviation) {
    count--;
  }
  if (!useLastForDeviation) {
    count--;
  }
  float averageDistance = touch.endpointDistance / count;
  NSLog(@"firstDistance: %.3f, lastDistance: %.3f, averageDistance: %.3f", firstDistance, lastDistance, averageDistance);
  if (averageDistance > 25 /*&& minDistance but not first or last?*/) {
    return UITouchKindSwipe;
  }
    
  return isOkSwipe ? UITouchKindSwipe : UITouchKindPhantomSwipeI;
}

@end
