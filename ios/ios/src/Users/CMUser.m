//
//  CMUserCredentials.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMUser.h"
#import "CMObjectSerialization.h"
#import "CMWebService.h"
#import "CMObjectEncoder.h"

NSString * const CMUserTypeName = @"user";

@interface CMWebService (Private)
@property (readwrite, strong, nonatomic) CMUser *user;
@end

@interface CMUser ()
@property (strong, nonatomic) NSString *token;
@property (readwrite, strong, nonatomic) NSDate *tokenExpiration;
@end

@implementation CMUser

+ (NSString *)className {
    return nil;
}

#pragma mark - Serialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        _token = [aDecoder decodeObjectForKey:@"token"];
        _tokenExpiration = [aDecoder decodeObjectForKey:@"tokenExpiration"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    
    // Do not send the token over the wire
    if (![aCoder isKindOfClass:[CMObjectEncoder class]]) {
        [aCoder encodeObject:_token forKey:@"token"];
        [aCoder encodeObject:_tokenExpiration forKey:@"tokenExpiration"];
    }
    
    [aCoder encodeObject:CMUserTypeName forKey:CMInternalTypeStorageKey];
}

#pragma mark - Recursion breaking

- (CMUser *)owner {
    [NSException raise:NSInternalInconsistencyException format:@"A user object cannot have an owner."];
    return nil;
}

- (void)setOwner:(CMUser *)user {
    [NSException raise:NSInternalInconsistencyException format:@"A user object cannot have an owner."];
}

#pragma mark - Authentication

- (void)setToken:(NSString *)token {
    _token = token;
    _password = nil;
}

- (BOOL)isAuthenticated {
    // If token exists and expiration date is in the future
    return (_token != nil && [_tokenExpiration compare:[NSDate date]] == NSOrderedDescending);
}

// TODO: Web service integration

@end
