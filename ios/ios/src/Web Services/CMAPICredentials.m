//
//  CMAPICredentials.m
//  cloudmine-ios
//
//  Created by Conrad Kramer on 8/20/12.
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//

#import "CMWebService.h"

#import "CMAPICredentials.h"

static CMAPICredentials *sharedInstance;

@implementation CMAPICredentials

+ (id)sharedInstance {
    if (!sharedInstance) {
        sharedInstance = [[CMAPICredentials alloc] init];
    }
    
    return sharedInstance;
}

- (void)setAppSecret:(NSString *)appSecret {
    [[CMWebService sharedWebService] setApiKey:appSecret];
}

- (NSString *)appSecret {
    return [[CMWebService sharedWebService] apiKey];
}

- (void)setAppIdentifier:(NSString *)appIdentifier {
    [[CMWebService sharedWebService] setAppIdentifier:appIdentifier];
}

- (NSString *)appIdentifier {
    return [[CMWebService sharedWebService] appIdentifier];
}

@end
