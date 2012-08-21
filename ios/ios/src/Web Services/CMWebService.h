//
//  CMWebService.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

/** @file */

#import <AFNetworking/AFNetworking.h>

#import "CMUser.h"

extern NSString * const CMErrorDomain;

enum {
    CMErrorUnknown = -1,
    
    CMErrorConnectionFailed = -1000,
    CMErrorInternalServer = -1001,
    CMErrorInvalidResponse = -1002,
    
    CMErrorAuthenticationFailed = -2000
};

@interface CMWebService : AFHTTPClient

@property (strong, nonatomic) NSString *apiKey;
@property (strong, nonatomic) NSString *appIdentifier;

@property (readonly, strong, nonatomic) NSDateFormatter *dateFormatter;

@property (readonly, strong, nonatomic) CMUser *user;

+ (id)sharedWebService;

// Text
- (NSString *)textPathWithParameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel;
- (NSString *)textPathWithQuery:(NSString *)query parameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel;

// Binary
- (NSString *)binaryPathWithKey:(NSString *)key parameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel;

// Data
- (NSString *)dataPathWithParameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel;

// Access control
- (NSString *)accessPathWithParameters:(NSDictionary *)parameters;
- (NSString *)accessPathWithKey:(NSString *)key parameters:(NSDictionary *)parameters;
- (NSString *)accessPathWithQuery:(NSString *)query parameters:(NSDictionary *)parameters;

// Account
- (NSString *)accountPathWithParameters:(NSDictionary *)parameters;
- (NSString *)accountPathWithKey:(NSString *)key parameters:(NSDictionary *)parameters;
- (NSString *)accountPathWithQuery:(NSString *)query parameters:(NSDictionary *)parameters;

// Account operations
- (NSString *)accountCreatePathWithParameters:(NSDictionary *)parameters;
- (NSString *)accountLoginPathWithParameters:(NSDictionary *)parameters;
- (NSString *)accountLogoutPathWithParameters:(NSDictionary *)parameters;
- (NSString *)accountPasswordChangePathWithParameters:(NSDictionary *)parameters;
- (NSString *)accountPasswordResetPathWithParameters:(NSDictionary *)parameters;

@end
