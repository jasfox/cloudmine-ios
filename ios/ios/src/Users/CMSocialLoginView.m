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

- (id)init
{
    if (self = [super init]) {
        _webView = [[UIWebView alloc] init];
        _webView.delegate = self;
    }
    return self;
}

#pragma mark - Workflow kickoff



#pragma mark - UIWebView Delegate Methods

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
}

@end
