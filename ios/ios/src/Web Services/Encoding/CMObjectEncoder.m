//
//  CMObjectEncoder.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMObjectEncoder.h"
#import "CMObjectSerialization.h"

#import "CMObject.h"
#import "CMObjectReference.h"

@interface CMObjectEncoder () {
    CMObjectEncoder *_master;
    NSMutableDictionary *_representation;
}
@end

@implementation CMObjectEncoder

+ (NSDictionary *)representationFromObject:(id)object {
    CMObjectEncoder *coder = [[CMObjectEncoder alloc] init];
    [coder encodeObject:object forKey:@"key"];
    return [[coder encodedRepresentation] objectForKey:@"key"];
}

- (id)init {
    self = [self initWithMasterCoder:self];
    return self;
}

- (id)initWithMasterCoder:(CMObjectEncoder *)master {
    if ((self = [super init])) {
        _master = master;
        _representation = [NSMutableDictionary dictionary];
    }
    return self;
}

- (BOOL)allowsKeyedCoding {
    return YES;
}

- (NSDictionary *)encodedRepresentation {
    return [_representation copy];
}

- (BOOL)containsValueForKey:(NSString *)key {
    return [_representation objectForKey:key] != nil;
}

- (void)encodeBool:(BOOL)value forKey:(NSString *)key {
    [_representation setObject:[NSNumber numberWithBool:value] forKey:key];
}

- (void)encodeDouble:(double)value forKey:(NSString *)key {
    [_representation setObject:[NSNumber numberWithDouble:value] forKey:key];
}

- (void)encodeFloat:(float)value forKey:(NSString *)key {
    [_representation setObject:[NSNumber numberWithFloat:value] forKey:key];
}

- (void)encodeInt:(int)value forKey:(NSString *)key {
    [_representation setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)encodeInteger:(NSInteger)value forKey:(NSString *)key {
    [_representation setObject:[NSNumber numberWithInteger:value] forKey:key];
}

- (void)encodeInt32:(int32_t)value forKey:(NSString *)key {
    [_representation setObject:[NSNumber numberWithInt:value] forKey:key];
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key {
    [NSException raise:NSInvalidArgumentException format:@"64-bit integers are not supported."];
}

- (void)encodeObject:(id)obj forKey:(NSString *)key {
    
    // Some reading on subclassing cluster classes: http://cocoawithlove.com/2008/12/ordereddictionary-subclassing-cocoa.html
    // (In regards to overriding NSCoding on NSDate, NSArray, and NSDictionary)
    // I believe subclasses and decorator classes will cause confusion and hassle, so I will handle them explicitly, here.
    
    // Replace nil object with NSNull
    obj = obj ? obj : [NSNull null];
    
    // Treat sets as arrays
    obj = [obj isKindOfClass:[NSSet class]] ? [obj allObjects] : obj;
    
    // Handle dates explicitly
    if ([obj isKindOfClass:[NSDate class]]) {
        NSDictionary *encodedObject = @{ CMInternalTypeStorageKey : CMDateTypeName,
                                         CMInternalClassStorageKey : CMDateTypeName, // For backwards compatibility
                                         CMDateTimestampKey : @([obj timeIntervalSince1970])
                                        };
        obj = encodedObject;
    }
    
    // Handle arrays explicitly
    if ([obj isKindOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        
        [obj enumerateObjectsUsingBlock:^(id member, NSUInteger idx, BOOL *stop) {
            CMObjectEncoder *encoder = [[CMObjectEncoder alloc] initWithMasterCoder:_master];
            [encoder encodeObject:member forKey:@"key"];
            id encodedObject = [[encoder encodedRepresentation] objectForKey:@"key"];
            
            [array addObject:encodedObject];
        }];
        
        obj = [NSArray arrayWithArray:array];
    }
    
    // Handle dictionaries explicitly
    if ([obj isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            NSAssert([key isKindOfClass:[NSString class]], @"Keys of dictionaries encoded for CloudMine must be strings.");
            
            CMObjectEncoder *encoder = [[CMObjectEncoder alloc] initWithMasterCoder:_master];
            [encoder encodeObject:value forKey:@"key"];
            id encodedObject = [[encoder encodedRepresentation] objectForKey:@"key"];
            
            [dictionary setObject:encodedObject forKey:key];
        }];
        
        obj = [NSDictionary dictionaryWithDictionary:dictionary];
    }
    
    // Flatten object map
    if ([obj isKindOfClass:[CMObject class]]) {
        CMObject *object = (CMObject *)obj;
        if (![self isEqual:_master]) {
            if (![_master containsValueForKey:object.objectId]) {
                [_master encodeObject:obj forKey:object.objectId];
            }
            obj = [[CMObjectReference alloc] initWithObjectId:object.objectId];
        } else {
            key = object.objectId;
        }
    }
    
    // Break any recursion that may come from further encoding
    [_representation setObject:obj forKey:key];
        
    // Determine if obj is one of the valid JSON data types
    __block BOOL value;
    NSSet *valueTypes = [NSSet setWithObjects:[NSDictionary class], [NSArray class], [NSString class], [NSNumber class], [NSNull class], nil];
    [valueTypes enumerateObjectsUsingBlock:^(Class class, BOOL *stop) {
        *stop = value = [obj isKindOfClass:class];
    }];
    
    // If it is a valid data type, we are done!
    if (value) return;
    
    // Further encode if obj is not one of those data types
    CMObjectEncoder *encoder = [[CMObjectEncoder alloc] initWithMasterCoder:_master];
    [obj encodeWithCoder:encoder];
    [_representation setObject:[encoder encodedRepresentation] forKey:key];
}

- (id)decodeObject {
    [NSException raise:NSInvalidArgumentException format:@"Cannot call decode methods on an encoder."];
    return nil;
}

@end
