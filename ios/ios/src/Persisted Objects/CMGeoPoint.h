//
//  CMGeoPoint.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import <CoreLocation/CoreLocation.h>

extern NSString * const CMGeoPointTypeName;

/**
  The object representing the CloudMine's geopoint data type.
 */
@interface CMGeoPoint : NSObject

/**
  The coordinate of the geopoint
  */
@property (readonly, nonatomic) CLLocationCoordinate2D coordinate;

/**
  Initializes a CMGeoPoint object with the given coordinate
  
  @param coordinate The coordinate to initialize the object with
  @returns A newly initialized CMGeoPoint object with the coordinate set.
 */
- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate;

@end