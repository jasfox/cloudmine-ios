//
//  CMObject.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMObject.h"
#import "CMACL.h"

#import "CMObjectSerialization.h"
#import "CMObjectDecoder.h"

#import "CMNullStore.h"

@interface CMObject ()
@property (readwrite, getter = isDirty) BOOL dirty;
@property (readwrite, strong, nonatomic) CMUser *owner;
@end

@implementation CMObject

+ (NSString *)className {
    return NSStringFromClass(self);
}

#pragma mark - Initialization

- (id)init {
    self = [self initWithObjectId:nil];
    return self;
}

- (id)initWithObjectId:(NSString *)objectId {
    if (!objectId) {
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        objectId = [[(__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid) stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
        CFRelease(uuid);
    }
    
    if ((self = [super init])) {
        _objectId = objectId;
        _dirty = YES;
    }
    return self;
}

#pragma mark - Serialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSString *objectId = [aDecoder decodeObjectForKey:CMInternalObjectIdKey];
    if ((self = [self initWithObjectId:objectId])) {
        if ([[aDecoder class] isEqual:[CMObjectDecoder class]]) {
            _dirty = NO;
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_objectId forKey:CMInternalObjectIdKey];
    
    NSString *className;
    if ((className = [[self class] className])) {
        [aCoder encodeObject:className forKey:CMInternalClassStorageKey];
    }
}

#pragma mark - Dirty tracking

// TODO: Dirty tracking
// Implement -didChangeValueForKey

#pragma mark - Store interactions

// TODO: Interact with the store

#pragma mark - ACLs

// TODO: Integrate ACLs

@end