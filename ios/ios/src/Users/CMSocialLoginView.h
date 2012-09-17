//
//  CMSocialLoginViewDelegate.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import <UIKit/UIKit.h>

@class CMUser;

@interface CMSocialLoginView : NSObject <UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;

- (void)beginLoginForUser:(CMUser *)user onNetwork:(NSString *)networkName;

@end
