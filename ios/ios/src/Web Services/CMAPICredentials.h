//
//  CMAPICredentials.h
//  cloudmine-ios
//
//  Created by Conrad Kramer on 8/20/12.
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMAPICredentials : NSObject

+ (id)sharedInstance;

@property (strong, nonatomic) NSString *appSecret;
@property (strong, nonatomic) NSString *appIdentifier;

@end