//
//  CMGeoPoint.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMGeoPoint.h"
#import "CMObjectSerialization.h"

NSString * const CMGeoPointTypeName = @"geopoint";

NSString * const CMGeoPointLatitudeKey = @"latitude";
NSString * const CMGeoPointLongitudeKey = @"latitude";

@implementation CMGeoPoint

#pragma mark - Initialization

- (id)initWithCoordinate:(CLLocationCoordinate2D)coordinate {
    if (!CLLocationCoordinate2DIsValid(coordinate)) {
        self = nil;
        return self;
    }
    
    if ((self = [super init])) {
        _coordinate = coordinate;
    }
    return self;
}

#pragma mark - Serialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    CLLocationDegrees latitude = [aDecoder decodeDoubleForKey:CMGeoPointLatitudeKey];
    CLLocationDegrees longitude = [aDecoder decodeDoubleForKey:CMGeoPointLongitudeKey];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    
    self = [self initWithCoordinate:coordinate];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeDouble:_coordinate.latitude forKey:CMGeoPointLatitudeKey];
    [aCoder encodeDouble:_coordinate.longitude forKey:CMGeoPointLongitudeKey];
    [aCoder encodeObject:CMGeoPointTypeName forKey:CMInternalTypeStorageKey];
}

@end
