//
//  CMFile.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMFile.h"
#import "CMObjectSerialization.h"

NSString * const CMFileTypeName = @"file";

NSString * const CMFileNameKey = @"filename";
NSString * const CMFileContentTypeKey = @"content_type";

@implementation CMFile

+ (NSString *)className {
    return nil;
}

#pragma mark - Serialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _contentType = [aDecoder decodeObjectForKey:CMFileContentTypeKey];
        _name = [aDecoder decodeObjectForKey:CMFileNameKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_contentType forKey:CMFileContentTypeKey];
    [aCoder encodeObject:_name forKey:CMFileNameKey];
    [aCoder encodeObject:CMFileTypeName forKey:CMInternalTypeStorageKey];
}

// TODO: Data saving and downloading methods

@end
