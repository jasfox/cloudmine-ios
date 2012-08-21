//
//  CMObjectReference.h
//  cloudmine-ios
//
//  Created by Conrad Kramer on 8/10/12.
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//

#import "CMObject.h"

extern NSString * const CMObjectReferenceTypeName;

@interface CMObjectReference : NSObject

@property (strong, nonatomic) NSString *objectId;

- (id)initWithObjectId:(NSString *)objectId;

@end