//
//  CMObjectDecoder.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMObjectSerialization.h"

#import "CMObjectEncoder.h"
#import "CMObjectDecoder.h"

#import "CMGeoPoint.h"
#import "CMObjectReference.h"

#import "CMUser.h"
#import "CMFile.h"
#import "CMACL.h"

#import <objc/runtime.h>

@interface CMObjectDecoder () {
    NSDictionary *_representation;
}
@end

static NSDictionary *_classMapping;
static NSDictionary *_typeMapping;

@implementation CMObjectDecoder

+ (void)initialize {
    if (!_classMapping) {
        Class * allClasses = NULL;
        int count = objc_getClassList(NULL, 0);
        
        allClasses = (Class *)malloc(sizeof(Class) * count);
        count = objc_getClassList(allClasses, count);
        
        NSMutableDictionary *classMapping = [NSMutableDictionary dictionary];;
        for (int i = 0; i < count; i++) {
            Class class = allClasses[i];
            if ([class isSubclassOfClass:[CMObject class]]) {
                NSString *className = [class className];
                if (className) {
                    [classMapping setObject:class forKey:className];
                }
            }
        }
        
        [classMapping setObject:[NSDictionary class] forKey:@"map"];
        [classMapping setObject:[NSDate class] forKey:CMDateTypeName];
        
        free(allClasses);
        
        _classMapping = [NSDictionary dictionaryWithDictionary:classMapping];
    }
    
    if (!_typeMapping) {
        _typeMapping = @{ CMACLTypeName : [CMACL class], CMFileTypeName : [CMFile class], CMUserTypeName : [CMUser class], CMGeoPointTypeName : [CMGeoPoint class], CMObjectReferenceTypeName : [CMObjectReference class], CMDateTypeName : [NSDate class] };
    }
}

+ (Class)klassFromRepresentation:(id)representation {
    
    if ([representation isKindOfClass:[NSDictionary class]]) {
        
        // Class mappings go *before* type mappings because the base types can be subclassed. Order is important!
        NSString *className = [representation objectForKey:CMInternalClassStorageKey];
        Class klass = [_classMapping objectForKey:className];
        if (klass) return klass;
        
        NSString *typeName = [representation objectForKey:CMInternalTypeStorageKey];
        klass = [_typeMapping objectForKey:typeName];
        if (klass) return klass;        
    }
    
    return [representation class];
}

+ (id)objectFromRepresentation:(NSDictionary *)representation {
    CMObjectDecoder *coder = [[CMObjectDecoder alloc] initWithSerializedRepresentation:@{ @"key" : representation }];
    return [coder decodeObjectForKey:@"key"];
}

- (id)init {
    self = [self initWithSerializedRepresentation:nil];
    return self;
}

- (id)initWithSerializedRepresentation:(NSDictionary *)representation {
    if (!representation) {
        self = nil;
        return self;
    }
    
    if ((self = [super init])) {
        
        // A rescursive block to remove NSNull instances
        __block id (^removeNull)(id) = ^(id rootObject) {
            // Recurse through dictionaries
            if ([rootObject isKindOfClass:[NSDictionary class]]) {
                NSMutableDictionary *sanitizedDictionary = [NSMutableDictionary dictionaryWithDictionary:rootObject];
                [rootObject enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                    id sanitized = removeNull(obj);
                    if (!sanitized) {
                        [sanitizedDictionary removeObjectForKey:key];
                    } else {
                        [sanitizedDictionary setObject:sanitized forKey:key];
                    }
                }];
                
                return [NSDictionary dictionaryWithDictionary:sanitizedDictionary];
            }
            
            // Recurse through arrays
            if ([rootObject isKindOfClass:[NSArray class]]) {
                NSMutableArray *sanitizedArray = [NSMutableArray arrayWithArray:rootObject];
                [rootObject enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    id sanitized = removeNull(obj);
                    if (!sanitized) {
                        [sanitizedArray removeObjectIdenticalTo:obj];
                    } else {
                        [sanitizedArray replaceObjectAtIndex:[sanitizedArray indexOfObject:obj] withObject:sanitized];
                    }
                }];
                
                return [NSArray arrayWithArray:sanitizedArray];
            }
            
            // Base case
            if ([rootObject isKindOfClass:[NSNull class]]) {
                return (id)nil;
            } else {
                return rootObject;
            }
        };
        
        _representation = removeNull(representation);
    }
    
    return self;
}

- (BOOL)allowsKeyedCoding {
    return YES;
}

#pragma mark - Keyed archiving methods defined by NSCoder

- (BOOL)containsValueForKey:(NSString *)key {
    return [_representation objectForKey:key] != nil;
}

- (BOOL)decodeBoolForKey:(NSString *)key {
    return [[_representation objectForKey:key] boolValue];
}

- (double)decodeDoubleForKey:(NSString *)key {
    return [[_representation objectForKey:key] doubleValue];
}

- (float)decodeFloatForKey:(NSString *)key {
    return [[_representation objectForKey:key] floatValue];
}

- (int)decodeIntForKey:(NSString *)key {
    return [[_representation objectForKey:key] intValue];
}

- (NSInteger)decodeIntegerForKey:(NSString *)key {
    return [[_representation objectForKey:key] integerValue];
}

- (int32_t)decodeInt32ForKey:(NSString *)key {
    return [[_representation objectForKey:key] intValue];
}

- (int64_t)decodeInt64ForKey:(NSString *)key {
    [NSException raise:NSInvalidArgumentException format:@"64-bit integers are not supported. Decode as 32-bit."];
    return (int64_t)0;
}

- (id)decodeObjectForKey:(NSString *)key {
    id obj = [_representation objectForKey:key];
    Class klass = [CMObjectDecoder klassFromRepresentation:obj];
    
    // Handle dates explicitly
    if ([klass isSubclassOfClass:[NSDate class]]) {
        NSTimeInterval timestamp = [[_representation objectForKey:CMDateTimestampKey] doubleValue];
        return [NSDate dateWithTimeIntervalSince1970:timestamp];
    }
    
    // Handle arrays explicitly
    if ([klass isSubclassOfClass:[NSArray class]]) {
        NSMutableArray *array = [NSMutableArray array];
        [obj enumerateObjectsUsingBlock:^(id member, NSUInteger idx, BOOL *stop) {
            id decodedObject = [[self class] objectFromRepresentation:member];
            
            [array addObject:decodedObject];
        }];
        
        return [NSArray arrayWithArray:array];
    }
    
    // Handle dictionaries explicitly
    if ([klass isSubclassOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
        
        [obj enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
            id decodedObject = [[self class] objectFromRepresentation:value];
            
            [dictionary setObject:decodedObject forKey:key];
        }];
        
        return [NSDictionary dictionaryWithDictionary:dictionary];
    }
    
    CMObjectDecoder *decoder = [[CMObjectDecoder alloc] initWithSerializedRepresentation:obj];
    id decodedObject = [[klass alloc] initWithCoder:decoder];
    
    if ([klass isSubclassOfClass:[CMObjectReference class]]) {
        // TODO: Untangle references in a sane manner
    }
    
    return decodedObject;
}

- (void)encodeObject:(id)object {
    [NSException raise:NSInvalidArgumentException format:@"Cannot call encode methods on an decoder"];
}

@end
