//
//  CMSocialLoginViewDelegate.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMSocialLoginView.h"

@implementation CMSocialLoginView
@synthesize webView = _webView;
@synthesize user = _user;

- (id)initWithUser:(CMUser *)user {
    if (self = [super init]) {
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
        _user = user;
    }
    return self;
}

#pragma mark - Workflow kickoff

- (void)beginLoginForNetwork:(NSString *)networkName callback:(CMUserOperationCallback)callback {
    
}

#pragma mark - UIWebView Delegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

@end
