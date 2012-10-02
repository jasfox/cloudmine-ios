//
//  CMSocialLoginViewDelegate.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import <UIKit/UIKit.h>
#import "CMUserAccountResult.h"

@class CMUser;

@interface CMSocialLoginView : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) CMUser *user;

- (id)initWithUser:(CMUser *)user;
- (void)beginLoginForNetwork:(NSString *)networkName callback:(CMUserOperationCallback)callback;

@end
