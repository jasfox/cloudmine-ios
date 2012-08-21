//
//  CMFile.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMObject.h"

extern NSString * const CMFileTypeName;

@interface CMFile : CMObject

@property (strong, nonatomic) NSString *name;

@property (strong, nonatomic) NSString *contentType;

@end