//
//  CMObjectReference.m
//  cloudmine-ios
//
//  Created by Conrad Kramer on 8/10/12.
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//

#import "CMObjectReference.h"
#import "CMObjectSerialization.h"

NSString * const CMObjectReferenceTypeName = @"ref";

@implementation CMObjectReference

#pragma mark - Initialization

- (id)initWithObjectId:(NSString *)objectId {
    if ((self = [super init])) {
        _objectId = objectId;
    }
    return self;
}

#pragma mark - Serialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSString *objectId = [aDecoder decodeObjectForKey:CMInternalObjectIdKey];
    self = [self initWithObjectId:objectId];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_objectId forKey:CMInternalObjectIdKey];
    [aCoder encodeObject:CMObjectReferenceTypeName forKey:CMInternalTypeStorageKey];
}

@end