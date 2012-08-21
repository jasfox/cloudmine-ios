//
//  CMNullStore.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMNullStore.h"

#define THROW_NULLSTORE_EXCEPTION [[NSException exceptionWithName:@"CMInvalidStoreException" reason:$sprintf(@"You cannot call %@ on a null store.", NSStringFromSelector(_cmd)) userInfo:nil] raise];

@implementation CMNullStore

#pragma mark - Shared store

+ (CMNullStore *)nullStore {
    static CMNullStore *_defaultStore;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultStore = [[CMNullStore alloc] init];
    });

    return _defaultStore;
}

+ (CMStore *)defaultStore {
    return [self nullStore];
}

+ (CMStore *)store {
    [[NSException exceptionWithName:@"CMInvalidStoreException" reason:@"Use +defaultStore instead. The +store method isn't valid." userInfo:nil] raise];
    __builtin_unreachable();
}

// TODO: Dynamically generate exception code from CMStore model

@end
