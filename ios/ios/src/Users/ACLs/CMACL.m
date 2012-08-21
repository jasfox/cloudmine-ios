//
//  CMACL.m
//  cloudmine-ios
//
//  Created by Marc Weil on 7/2/12.
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//

#import "CMACL.h"
#import "CMObjectSerialization.h"

NSString * const CMACLTypeName = @"acl";

NSString * const CMACLReadPermission = @"r";
NSString * const CMACLUpdatePermission = @"u";
NSString * const CMACLDeletePermission = @"d";

NSString * const CMACLMembersKey = @"members";
NSString * const CMACLPermissionsKey = @"permissions";

@implementation CMACL

+ (NSString *)className {
    return nil;
}

#pragma mark - Initialization

- (id)init {
    if (self = [super init]) {
        _members = [NSSet set];
        _permissions = [NSSet set];
    }
    return self;
}

#pragma mark - Serialization

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _members = [NSMutableSet setWithArray:[aDecoder decodeObjectForKey:CMACLMembersKey]];
        _permissions = [NSMutableSet setWithArray:[aDecoder decodeObjectForKey:CMACLPermissionsKey]];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:[_members allObjects] forKey:CMACLMembersKey];
    [aCoder encodeObject:[_permissions allObjects] forKey:CMACLPermissionsKey];
    [aCoder encodeObject:CMACLTypeName forKey:CMInternalTypeStorageKey];
}

#pragma mark - Recursion breaking

// TODO: Do not allow setting/getting of ACLs

#pragma mark - Other

- (void)setPermissions:(NSSet *)permissions {
    if (permissions != _permissions) {
        NSSet *availablePermissions = [NSSet setWithObjects:CMACLReadPermission, CMACLUpdatePermission, CMACLDeletePermission, nil];
        
        // Reduce list of permissions to only valid values
        NSMutableSet *mutPermissions = [NSMutableSet setWithSet:permissions];
        [mutPermissions intersectSet:availablePermissions];
        permissions = [NSSet setWithSet:mutPermissions];
        
        _permissions = permissions;
    }
}

@end
