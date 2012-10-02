//
//  CMSocialLoginViewDelegate.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMSocialLoginView.h"

@interface CMSocialLoginView ()
- (void)configureWebviewForDisplay;
@property (nonatomic, strong) UIWebView *webView;
@end

@implementation CMSocialLoginView
@synthesize webView = _webView;
@synthesize user = _user;

- (id)initWithUser:(CMUser *)user {
    if (self = [super init]) {
        _webView = [[UIWebView alloc] init];
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

#pragma mark - Private helper methods

- (void)configureWebviewForDisplay {
    CGRect appFrame = [UIScreen mainScreen].applicationFrame;
    _webView.frame = appFrame;
    _webView.scalesPageToFit = YES;
    _webView.delegate = self;
    self.view = _webView;
}

@end
