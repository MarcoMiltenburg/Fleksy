//
//  FLTouch.m
//  GestureTest
//
//  Created by Kostas Eleftheriou on 11/13/12.
//  Copyright (c) 2012 Kostas Eleftheriou. All rights reserved.
//

#import "FLTouch.h"
#import "UITouchManager.h"
#import "MathFunctions.h"

@implementation FLTouch

- (id) initWithPath:(NSArray*) thePath kind:(UITouchKind) theKind {
  if (self = [super init]) {
    self->path = thePath;
    self.kind = theKind;
    self.useFirstPoint = YES;
    self.useLastPoint = YES;
  }
  return self;
}

- (float) travelDistance {
  float result = 0;
  for (int i = 1; i < self.path.count; i++) {
    PathPoint* pathPoint1  = [self.path objectAtIndex:i-1];
    PathPoint* pathPoint2  = [self.path objectAtIndex:i];
    result += distanceOfPoints(pathPoint1.location, pathPoint2.location);
  }
  return result;
}

- (id) initFromString:(NSString*) swipeString {
  int i = 0;
  NSMutableArray* tempPath = [[NSMutableArray alloc] init];
  for (NSString* line in [swipeString componentsSeparatedByString:@"\n"]) {
    //NSLog(@"line: %@", line);
    if (!line.length) {
      continue;
    }
    if (i == 0) {
      self.kind = (UITouchKind) [line intValue];
    } else {
      NSArray* components = [line componentsSeparatedByString:@"@"];
      UITouchPhase phase = (UITouchPhase) [[components objectAtIndex:0] intValue];
      CGPoint location = CGPointFromString([components objectAtIndex:1]);
      double timestamp = [[components objectAtIndex:2] doubleValue];
      PathPoint* point = [[PathPoint alloc] initWithLocation:location timestamp:timestamp phase:phase];
      [tempPath addObject:point];
    }
    i++;
  }
  
  if (self = [self initWithPath:tempPath kind:self.kind]) {
  }
  return self;
}


+ (NSString*) stringForPath:(NSArray*) path kind:(UITouchKind) kind {
  NSMutableString* string = [[NSMutableString alloc] initWithFormat:@"TOUCH_KIND: %d\n", kind];
  for (PathPoint* point in path) {
    [string appendFormat:@"%d @ %@ @ %.6f\n", point.phase, NSStringFromCGPoint(point.location), point.timestamp];
  }
  return string;
}

+ (NSString*) stringForTouch:(UITouch*) touch kind:(UITouchKind) kind {
  return [FLTouch stringForPath:touch.path kind:kind];
}

- (NSString*) description {
  return [FLTouch stringForPath:self.path kind:self.kind];
}

- (CGPoint) startPoint {
  assert(self.path.count);
  PathPoint* point = [self.path objectAtIndex:0];
  return point.location;
}

- (CGPoint) endPoint {
  assert(self.path.count);
  PathPoint* point = [self.path lastObject];
  return point.location;
}

- (float) endpointDistance {
  return distanceOfPoints(self.startPoint, self.endPoint);
}

- (float) dt {
  PathPoint* point1 = [self.path objectAtIndex:0];
  PathPoint* point2 = [self.path lastObject];
  return point2.timestamp - point1.timestamp;
}

- (float) firstDistance {
  PathPoint* point1 = [self.path objectAtIndex:0];
  PathPoint* point2 = [self.path objectAtIndex:1];
  return distanceOfPoints(point1.location, point2.location);
}

- (float) lastDistance {
  PathPoint* pointL = [self.path lastObject];
  PathPoint* pointLL = [self.path objectAtIndex:self.path.count-2];
  return distanceOfPoints(pointL.location, pointLL.location);
}

- (float) minimumDistance {
  float result = MAXFLOAT;
  for (int i = 1; i < self.path.count; i++) {
    PathPoint* pathPoint1  = [self.path objectAtIndex:i-1];
    PathPoint* pathPoint2  = [self.path objectAtIndex:i];
    float distance = distanceOfPoints(pathPoint1.location, pathPoint2.location);
    result = fminf(distance, result);
  }
  assert(result < MAXFLOAT);
  return result;
}


- (float) maximumDistance {
  float result = -1;
  for (int i = 1; i < self.path.count; i++) {
    PathPoint* pathPoint1  = [self.path objectAtIndex:i-1];
    PathPoint* pathPoint2  = [self.path objectAtIndex:i];
    float distance = distanceOfPoints(pathPoint1.location, pathPoint2.location);
    result = fmaxf(distance, result);
  }
  assert(result >= 0);
  return result;
}

- (void) setUseFirstPoint:(BOOL) b {
  
  int count = self->path.count;
  if (!self.useLastPoint) {
    count--;
  }
  
  if (count <= 2 && !b) {
    [NSException raise:@"setUseFirstPoint" format:@"count: %d", count];
  }
  
  self->_useFirstPoint = b;
}

- (void) setUseLastPoint:(BOOL) b {
  
  int count = self->path.count;
  if (!self.useFirstPoint) {
    count--;
  }
  
  if (count <= 2 && !b) {
    [NSException raise:@"setUseLastPoint" format:@"count: %d", count];
  }
  
  self->_useLastPoint = b;
}



- (NSArray*) path {

  int startIndex = 0;
  int endIndex = self->path.count;
  
  if (!self.useFirstPoint) {
    startIndex++;
  }
  if (!self.useLastPoint) {
    endIndex--;
  }
  //NSLog(@"startIndex: %d, endIndex: %d, count: %d", startIndex, endIndex, self->path.count);
  return [self->path subarrayWithRange:NSMakeRange(startIndex, endIndex-startIndex)];
}


@end
