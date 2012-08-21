//
//  CMUserCredentials.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMObject.h"

extern NSString * const CMUserTypeName;

@interface CMUser : CMObject

/**
  The login identifier of the user. This is usually an email address. The value of this property is only used for authentication purposes, and is only stored server-side in case the user needs to reset their password.
 */
@property (strong, nonatomic) NSString *userId;

/**
  The password of the user. This is only used for authentication purposes. This will be nullified after a successful login request, because the returned token can be used for further authentication. The value of this property is never stored.
  */
@property (strong, nonatomic) NSString *password;

/**
  The expiration date of the user's token. The expiration date is automatically extended to two weeks after every successful user-level API call.
  */
@property (readonly, strong, nonatomic) NSDate *tokenExpiration;

/**
  Whether or not the user is authenticated. This checks to see whether or not the user has a token, and that the expiration date is the future.
  */
@property (readonly, getter = isAuthenticated) BOOL authenticated;

@end
