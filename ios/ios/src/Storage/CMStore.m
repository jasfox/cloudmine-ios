//
//  CMStore.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMStore.h"
#import <objc/runtime.h>

#import "CMObjectDecoder.h"
#import "CMObjectEncoder.h"
#import "CMObjectSerialization.h"
#import "CMAPICredentials.h"
#import "CMObject.h"
#import "CMACL.h"
#import "CMMimeType.h"
#import "CMObjectFetchResponse.h"
#import "CMObjectUploadResponse.h"
#import "CMFileFetchResponse.h"
#import "CMFileUploadResponse.h"
#import "CMDeleteResponse.h"

#define _CMAssertAPICredentialsInitialized NSAssert([[CMAPICredentials sharedInstance] appSecret] != nil && [[[CMAPICredentials sharedInstance] appSecret] length] > 0 && [[CMAPICredentials sharedInstance] appIdentifier] != nil && [[[CMAPICredentials sharedInstance] appIdentifier] length] > 0, @"The CMAPICredentials singleton must be initialized before using a CloudMine Store")
#define _CMAssertUserConfigured NSAssert(user, @"You must set the user of this store to a CMUser before querying for user-level objects.")
#define _CMUserOrNil (userLevel ? user : nil)
#define _CMTryMethod(obj, method) (obj ? [obj method] : nil)

#define CM_TOKENEXPIRATION_HEADER @"X-CloudMine-TE"

#pragma mark - Notification strings

NSString * const CMStoreObjectDeletedNotification = @"CMStoreObjectDeletedNotification";

#pragma mark -

@implementation CMStore {
    NSMutableDictionary *_cachedAppObjects;
    NSMutableDictionary *_cachedUserObjects;
    NSMutableDictionary *_cachedACLs;
    NSMutableDictionary *_cachedAppFiles;
    NSMutableDictionary *_cachedUserFiles;
}

@synthesize user;
@synthesize lastError;

#pragma mark - Shared store

+ (CMStore *)defaultStore {
    static CMStore *_defaultStore;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultStore = [[CMStore alloc] init];
    });

    return _defaultStore;
}

#pragma mark - Initializers

+ (CMStore *)store {
    return [[CMStore alloc] init];
}

+ (CMStore *)storeWithUser:(CMUser *)theUser {
    return [[CMStore alloc] initWithUser:theUser];
}

- (id)init {
    return [self initWithUser:nil];
}

- (id)initWithUser:(CMUser *)theUser {
    if (self = [super init]) {
        self.user = theUser;

        lastError = nil;
        _cachedAppObjects = [[NSMutableDictionary alloc] init];
        _cachedACLs = theUser ? [[NSMutableDictionary alloc] init] : nil;
        _cachedUserObjects = theUser ? [[NSMutableDictionary alloc] init] : nil;
        _cachedAppFiles = [[NSMutableDictionary alloc] init];
        _cachedUserFiles = theUser ? [[NSMutableDictionary alloc] init] : nil;
    }
    return self;
}

#pragma mark - Store state

- (CMObjectOwnershipLevel)objectOwnershipLevel:(id)theObject {
    return CMObjectOwnershipAppLevel;
}

#pragma mark - Object retrieval

- (void)allObjectsWithOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    [self _allObjects:callback userLevel:NO additionalOptions:options];
}

- (void)allUserObjectsWithOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _allObjects:callback userLevel:YES additionalOptions:options];
    }];
}

- (void)_allObjects:(CMStoreObjectFetchCallback)callback userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options {
    [self _objectsWithKeys:nil callback:callback userLevel:userLevel additionalOptions:options];
}

- (void)allACLs:(CMStoreACLFetchCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        /*[webService getACLsForUser:user successHandler:^(NSDictionary *results, NSDictionary *errors, NSDictionary *meta, id snippetResult, NSNumber *count, NSDictionary *headers) {
            // Reset expiration date to the one received in the headers
            NSDate *expirationDate = [self.dateFormatter dateFromString:[headers objectForKey:CM_TOKENEXPIRATION_HEADER]];
            if (expirationDate)
                user.tokenExpiration = expirationDate;
            
            // Decode and cache objects
            NSSet *acls = [NSSet setWithArray:[CMObjectDecoder decodeObjects:results]];
            [acls enumerateObjectsUsingBlock:^(CMACL *acl, BOOL *stop) {
                [self addACL:acl];
            }];
            
            CMACLFetchResponse *response = [[CMACLFetchResponse alloc] initWithACLs:acls errors:errors];
            if (callback) {
                callback(response);
            }
        } errorHandler:^(NSError *error) {
            NSLog(@"CloudMine *** Error occurred retrieving ACLS for user: %@ with message: %@", user, [error description]);
            CMACLFetchResponse *response = [[CMACLFetchResponse alloc] initWithError:error];
            lastError = error;
            if (callback) {
                callback(response);
            }
        }];*/
    }];
}

- (void)objectsWithKeys:(NSArray *)keys additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    [self _objectsWithKeys:keys callback:callback userLevel:NO additionalOptions:options];
}

- (void)userObjectsWithKeys:(NSArray *)keys additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _objectsWithKeys:keys callback:callback userLevel:YES additionalOptions:options];
    }];
}
- (void)_objectsWithKeys:(NSArray *)keys callback:(CMStoreObjectFetchCallback)callback userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options {

    
}

#pragma mark Object querying by type

- (void)allObjectsOfClass:(Class)klass additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    [self _allObjects:callback ofClass:klass userLevel:NO additionalOptions:options];
}

- (void)allUserObjectsOfClass:(Class)klass additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    _CMAssertUserConfigured;

    [self _ensureUserLoggedInWithCallback:^{
        [self _allObjects:callback ofClass:klass userLevel:YES additionalOptions:options];
    }];
}

- (void)_allObjects:(CMStoreObjectFetchCallback)callback ofClass:(Class)klass userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options {
    NSParameterAssert(klass);
    NSAssert([klass respondsToSelector:@selector(className)], @"You must pass a class (%@) that extends CMObject and responds to +className.", klass);
    
}

#pragma mark General object querying

- (void)searchObjects:(NSString *)query additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    [self _searchObjects:callback query:query userLevel:NO additionalOptions:options];
}

- (void)searchUserObjects:(NSString *)query additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectFetchCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _searchObjects:callback query:query userLevel:YES additionalOptions:options];
    }];
}

- (void)_searchObjects:(CMStoreObjectFetchCallback)callback query:(NSString *)query userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options {

    if (!query || [query length] == 0) {
        NSLog(@"CloudMine *** No query provided, so executing standard all-object retrieval");
        return [self _allObjects:callback userLevel:userLevel additionalOptions:options];
    }

}

- (void)searchACLs:(NSString *)query callback:(CMStoreACLFetchCallback)callback {

}

#pragma mark Object uploading

- (void)saveAll:(CMStoreObjectUploadCallback)callback {
    [self saveAllWithOptions:nil callback:callback];
}

- (void)saveAllWithOptions:(CMStoreOptions *)options callback:(CMStoreObjectUploadCallback)callback {
    __unsafe_unretained CMStore *selff = self;
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    dispatch_async(queue, ^{
        [selff saveAllAppObjectsWithOptions:options callback:callback];
    });

    if (user) {
        dispatch_async(queue, ^{
            [selff saveAllUserObjectsWithOptions:options callback:callback];
        });
        dispatch_async(queue, ^{
            [selff saveAllACLs:callback];
        });
    }
}

- (void)saveAllAppObjects:(CMStoreObjectUploadCallback)callback {
    [self saveAllAppObjectsWithOptions:nil callback:callback];
}

- (void)saveAllAppObjectsWithOptions:(CMStoreOptions *)options callback:(CMStoreObjectUploadCallback)callback {
    [self _saveObjects:[_cachedAppObjects allValues] userLevel:NO callback:callback additionalOptions:options];
}

- (void)saveAllUserObjects:(CMStoreObjectUploadCallback)callback {
    [self saveAllUserObjectsWithOptions:nil callback:callback];
}

- (void)saveAllUserObjectsWithOptions:(CMStoreOptions *)options callback:(CMStoreObjectUploadCallback)callback {
    [self _ensureUserLoggedInWithCallback:^{
        [self _saveObjects:[_cachedUserObjects allValues] userLevel:YES callback:callback additionalOptions:options];
    }];
}

- (void)saveAllACLs:(CMStoreObjectUploadCallback)callback {
    [self saveACLs:[_cachedACLs allValues] callback:callback];
}

- (void)saveUserObject:(CMObject *)theObject callback:(CMStoreObjectUploadCallback)callback {
    [self saveUserObject:theObject additionalOptions:nil callback:callback];
}

- (void)saveUserObject:(CMObject *)theObject additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectUploadCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _saveObjects:@[theObject] userLevel:YES callback:callback additionalOptions:options];
    }];
}

- (void)saveACL:(CMACL *)acl callback:(CMStoreObjectUploadCallback)callback {
    [self saveACLs:[NSArray arrayWithObject:acl] callback:callback];
}

- (void)saveObject:(CMObject *)theObject callback:(CMStoreObjectUploadCallback)callback {
    [self saveObject:theObject additionalOptions:nil callback:callback];
}

- (void)saveObject:(CMObject *)theObject additionalOptions:(CMStoreOptions *)options callback:(CMStoreObjectUploadCallback)callback {
    [self _saveObjects:@[theObject] userLevel:NO callback:callback additionalOptions:options];
}

- (void)_saveObjects:(NSArray *)objects userLevel:(BOOL)userLevel callback:(CMStoreObjectUploadCallback)callback additionalOptions:(CMStoreOptions *)options {
    NSParameterAssert(objects);
    [self cacheObjectsInMemory:objects atUserLevel:userLevel];
    
    NSMutableArray *cleanObjects = [NSMutableArray array];
    NSMutableArray *dirtyObjects = [NSMutableArray array];
    [objects enumerateObjectsUsingBlock:^(CMObject* obj, NSUInteger idx, BOOL *stop) {
        obj.dirty ? [dirtyObjects addObject:obj] : [cleanObjects addObject:obj];
    }];
}

- (void)saveACLsOnObject:(CMObject *)object callback:(CMStoreObjectUploadCallback)callback {
    NSMutableArray *acls = [NSMutableArray array];
    /*
    [object.aclIds enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        id obj = [_cachedACLs objectForKey:key];
        if (obj)
            [acls addObject:obj];
    }];*/
    
    [self saveACLs:acls callback:callback];
}

- (void)saveACLs:(NSArray *)acls callback:(CMStoreObjectUploadCallback)callback {
    if (!acls.count) {
        callback([[CMObjectUploadResponse alloc] init]);
        return;
    }
    
    [self _ensureUserLoggedInWithCallback:^{
        [acls enumerateObjectsUsingBlock:^(CMACL *acl, NSUInteger idx, BOOL *stop) {
            [self addACL:acl];
        }];
        
        /*
        __block CMWebServiceObjectFetchSuccessCallback successHandler;
        
        CMWebServiceFetchFailureCallback errorHandler = ^(NSError *error) {
            successHandler(nil, [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:[[acls objectAtIndex:index] objectId]], nil, nil, nil, nil);
        };
        
        successHandler = ^(NSDictionary *results, NSDictionary *errors, NSDictionary *meta, id snippetResult, NSNumber *count, NSDictionary *headers) {
            CMACL *acl = [[CMObjectDecoder decodeObjects:results] lastObject];
            if (acl) {
                [self addACL:acl];
                acl.dirty = NO;
                [uploadStatuses setObject:@"updated" forKey:acl.objectId];
            } else {
                [uploadStatuses addEntriesFromDictionary:errors];
            }
            
            index++;
            if (index < acls.count) {
                acl = [acls objectAtIndex:index];
                NSDictionary *aclDict = [[CMObjectEncoder encodeObjects:[NSSet setWithObject:acl]] objectForKey:acl.objectId];
                if (acl.dirty)
                    [webService updateACL:aclDict user:user successHandler:successHandler errorHandler:errorHandler];
                else
                    successHandler([NSDictionary dictionaryWithObject:aclDict forKey:acl.objectId], nil, nil, nil, [NSNumber numberWithUnsignedInt:1], nil);
            } else {
                CMObjectUploadResponse *response = [[CMObjectUploadResponse alloc] initWithUploadStatuses:uploadStatuses];
                if (callback)
                    callback(response);
            }
        };
        
        CMACL *acl = [acls objectAtIndex:index];
        NSDictionary *aclDict = [[CMObjectEncoder encodeObjects:[NSSet setWithObject:acl]] objectForKey:acl.objectId];
        if (acl.dirty)
            [webService updateACL:aclDict user:user successHandler:successHandler errorHandler:errorHandler];
        else
            successHandler([NSDictionary dictionaryWithObject:aclDict forKey:acl.objectId], nil, nil, nil, [NSNumber numberWithUnsignedInt:1], nil);*/
    }];
}

#pragma mark File uploading

- (void)saveFileAtURL:(NSURL *)url additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    [self _saveFileAtURL:url named:nil userLevel:NO additionalOptions:options callback:callback];
}

- (void)saveFileAtURL:(NSURL *)url named:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    [self _saveFileAtURL:url named:name userLevel:NO additionalOptions:options callback:callback];
}

- (void)saveUserFileAtURL:(NSURL *)url additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _saveFileAtURL:url named:nil userLevel:YES additionalOptions:options callback:callback];
    }];
}

- (void)saveUserFileAtURL:(NSURL *)url named:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _saveFileAtURL:url named:name userLevel:YES additionalOptions:options callback:callback];
    }];
}

- (void)_saveFileAtURL:(NSURL *)url named:(NSString *)name userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    NSParameterAssert(url);
/*
    [webService uploadFileAtPath:[url path]
              serverSideFunction:_CMTryMethod(options, serverSideFunction)
                           named:name
                      ofMimeType:[self _mimeTypeForFileAtURL:url withCustomName:name]
                            user:_CMUserOrNil
                 extraParameters:_CMTryMethod(options, buildExtraParameters)
                  successHandler:^(CMFileUploadResult result, NSString *fileKey, id snippetResult, NSDictionary *headers) {
                      CMSnippetResult *sResult = [[CMSnippetResult alloc] initWithData:snippetResult];
                      CMFileUploadResponse *response = [[CMFileUploadResponse alloc] initWithResult:result key:fileKey snippetResult:sResult];

                      NSDate *expirationDate = [self.dateFormatter dateFromString:[headers objectForKey:CM_TOKENEXPIRATION_HEADER]];
                      if (expirationDate && userLevel) {
                          user.tokenExpiration = expirationDate;
                      }

                      if (callback) {
                          callback(response);
                      }
                  } errorHandler:^(NSError *error) {
                      NSLog(@"CloudMine *** Error occurred uploading streamed file with URL: %@ name: %@ for user: %@ with message: %@", [url absoluteString], name, _CMUserOrNil, [error description]);
                      CMFileUploadResponse *response = [[CMFileUploadResponse alloc] initWithError:error];
                      lastError = error;
                      if (callback) {
                          callback(response);
                      }
                  }
     ];*/
}

- (void)saveFileWithData:(NSData *)data additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    [self _saveFileWithData:data named:nil userLevel:NO additionalOptions:options callback:callback];
}

- (void)saveFileWithData:(NSData *)data named:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    [self _saveFileWithData:data named:name userLevel:NO additionalOptions:options callback:callback];
}

- (void)saveUserFileWithData:(NSData *)data additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _saveFileWithData:data named:nil userLevel:YES additionalOptions:options callback:callback];
    }];
}

- (void)saveUserFileWithData:(NSData *)data named:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _saveFileWithData:data named:name userLevel:YES additionalOptions:options callback:callback];
    }];
}

- (void)_saveFileWithData:(NSData *)data named:(NSString *)name userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileUploadCallback)callback {
    NSParameterAssert(data);
/*
    [webService uploadBinaryData:data
              serverSideFunction:_CMTryMethod(options, serverSideFunction)
                           named:name
                      ofMimeType:[self _mimeTypeForFileAtURL:nil withCustomName:name]
                            user:_CMUserOrNil
                 extraParameters:_CMTryMethod(options, buildExtraParameters)
                  successHandler:^(CMFileUploadResult result, NSString *fileKey, id snippetResult, NSDictionary *headers) {
                      CMSnippetResult *sResult = [[CMSnippetResult alloc] initWithData:snippetResult];
                      CMFileUploadResponse *response = [[CMFileUploadResponse alloc] initWithResult:result key:fileKey snippetResult:sResult];

                      NSDate *expirationDate = [self.dateFormatter dateFromString:[headers objectForKey:CM_TOKENEXPIRATION_HEADER]];
                      if (expirationDate && userLevel) {
                          user.tokenExpiration = expirationDate;
                      }

                      if (callback) {
                          callback(response);
                      }
                  } errorHandler:^(NSError *error) {
                      NSLog(@"CloudMine *** Error occurred uploading data as file with name: %@ for user: %@ with message: %@", name, _CMUserOrNil, [error description]);
                      CMFileUploadResponse *response = [[CMFileUploadResponse alloc] initWithError:error];
                      lastError = error;
                      if (callback) {
                          callback(response);
                      }
                  }
     ];*/
}

- (NSString *)_mimeTypeForFileAtURL:(NSURL *)url withCustomName:(NSString *)name {
    NSString *mimeType = nil;
    NSArray *components = nil;

    if (url != nil) {
        components = [[url lastPathComponent] componentsSeparatedByString:@"."];
        if ([components count] > 1) {
            mimeType = [CMMimeType mimeTypeForExtension:[components objectAtIndex:1]];
        }
    }

    if (mimeType == nil && name != nil) {
        components = [name componentsSeparatedByString:@"."];
        if ([components count] > 1) {
            mimeType = [CMMimeType mimeTypeForExtension:[components objectAtIndex:1]];
        }
    }

    return mimeType;
}

#pragma mark Object and file deletion

- (void)deleteObject:(CMObject *)theObject additionalOptions:(CMStoreOptions *)options callback:(CMStoreDeleteCallback)callback {
    NSParameterAssert(theObject);
    [self _deleteObjects:@[theObject] additionalOptions:options userLevel:NO callback:callback];
}

- (void)deleteUserObject:(CMObject *)theObject additionalOptions:(CMStoreOptions *)options callback:(CMStoreDeleteCallback)callback {
    NSParameterAssert(theObject);
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _deleteObjects:@[theObject] additionalOptions:options userLevel:YES callback:callback];
    }];
}

- (void)deleteACL:(CMObject *)acl callback:(CMStoreDeleteCallback)callback {
    [self deleteACLs:[NSArray arrayWithObject:acl] callback:callback];
}

- (void)deleteObjects:(NSArray *)objects additionalOptions:(CMStoreOptions *)options callback:(CMStoreDeleteCallback)callback {
    [self _deleteObjects:objects additionalOptions:options userLevel:NO callback:callback];
}

- (void)deleteUserObjects:(NSArray *)objects additionalOptions:(CMStoreOptions *)options callback:(CMStoreDeleteCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _deleteObjects:objects additionalOptions:options userLevel:YES callback:callback];
    }];
}

- (void)deleteFileNamed:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreDeleteCallback)callback {
    [self _deleteFileNamed:name additionalOptions:options userLevel:NO callback:callback];
}

- (void)deleteUserFileNamed:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreDeleteCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _deleteFileNamed:name additionalOptions:options userLevel:YES callback:callback];
    }];
}

- (void)_deleteFileNamed:(NSString *)name additionalOptions:(CMStoreOptions *)options userLevel:(BOOL)userLevel callback:(CMStoreDeleteCallback)callback {
    NSParameterAssert(name);
/*
    [webService deleteValuesForKeys:$array(name)
                 serverSideFunction:_CMTryMethod(options, serverSideFunction)
                               user:_CMUserOrNil
                    extraParameters:_CMTryMethod(options, buildExtraParameters)
                     successHandler:^(NSDictionary *results, NSDictionary *errors, NSDictionary *meta, NSDictionary *snippetResult, NSNumber *count, NSDictionary *headers) {
                         CMSnippetResult *result = [[CMSnippetResult alloc] initWithData:snippetResult];
                         CMDeleteResponse *response = [[CMDeleteResponse alloc] initWithSuccess:results errors:errors snippetResult:result];

                         NSDate *expirationDate = [self.dateFormatter dateFromString:[headers objectForKey:CM_TOKENEXPIRATION_HEADER]];
                         if (expirationDate && userLevel) {
                             user.tokenExpiration = expirationDate;
                         }

                         if (callback) {
                             callback(response);
                         }
                     } errorHandler:^(NSError *error) {
                         NSLog(@"CloudMine *** Error occurred deleting file with name: %@ for user: %@ with message: %@", name, _CMUserOrNil, [error description]);
                         CMDeleteResponse *response = [[CMDeleteResponse alloc] initWithError:error];
                         lastError = error;
                         if (callback) {
                             callback(response);
                         }
                     }
     ];*/
}

- (void)_deleteObjects:(NSArray *)objects additionalOptions:(CMStoreOptions *)options userLevel:(BOOL)userLevel callback:(CMStoreDeleteCallback)callback {
    NSParameterAssert(objects);

    // Remove the objects from the cache first.
    NSMutableDictionary *deletedObjects = [NSMutableDictionary dictionaryWithCapacity:objects.count];
    [objects enumerateObjectsUsingBlock:^(CMObject *obj, NSUInteger idx, BOOL *stop) {
        SEL delMethod = userLevel ? @selector(removeUserObject:) : @selector(removeObject:);
        [deletedObjects setObject:obj forKey:obj.objectId];
        [self performSelector:delMethod withObject:obj];
    }];
/*
    NSArray *keys = [deletedObjects allKeys];
    [webService deleteValuesForKeys:keys
                 serverSideFunction:_CMTryMethod(options, serverSideFunction)
                               user:_CMUserOrNil
                    extraParameters:_CMTryMethod(options, buildExtraParameters)
                     successHandler:^(NSDictionary *results, NSDictionary *errors, NSDictionary *meta, NSDictionary *snippetResult, NSNumber *count, NSDictionary *headers) {
                         CMSnippetResult *result = [[CMSnippetResult alloc] initWithData:snippetResult];
                         CMDeleteResponse *response = [[CMDeleteResponse alloc] initWithSuccess:results errors:errors snippetResult:result];

                         NSDate *expirationDate = [self.dateFormatter dateFromString:[headers objectForKey:CM_TOKENEXPIRATION_HEADER]];
                         if (expirationDate && userLevel) {
                             user.tokenExpiration = expirationDate;
                         }

                         if (callback) {
                             callback(response);
                         }
                     } errorHandler:^(NSError *error) {
                         NSLog(@"CloudMine *** Error occurred deleting objects %@ for user: %@ with message: %@", objects, _CMUserOrNil, [error description]);
                         CMDeleteResponse *response = [[CMDeleteResponse alloc] initWithError:error];
                         lastError = error;
                         if (callback) {
                             callback(response);
                         }
                     }
     ];*/

    [[NSNotificationCenter defaultCenter] postNotificationName:CMStoreObjectDeletedNotification
                                                        object:self
                                                      userInfo:deletedObjects];
}

- (void)deleteACLs:(NSArray *)acls callback:(CMStoreDeleteCallback)callback {
    _CMAssertUserConfigured;
    if (!acls.count) {
        callback([[CMDeleteResponse alloc] init]);
        return;
    }
    
    [self _ensureUserLoggedInWithCallback:^{
        [acls enumerateObjectsUsingBlock:^(CMACL *acl, NSUInteger idx, BOOL *stop) {
            [self removeACL:acl];
        }];
        
        /*
        __block CMWebServiceObjectFetchSuccessCallback successHandler;
        
        CMWebServiceFetchFailureCallback errorHandler = ^(NSError *error) {
            successHandler(nil, [NSDictionary dictionaryWithObject:[error localizedDescription] forKey:[[acls objectAtIndex:index] objectId]], nil, nil, nil, nil);
        };
        
        successHandler = ^(NSDictionary *results, NSDictionary *errors, NSDictionary *meta, id snippetResult, NSNumber *count, NSDictionary *headers) {
            if (results) {
                // Remove all references to ACL in cached objects (this is actually performed server side)
                [[_cachedUserObjects allValues] enumerateObjectsUsingBlock:^(CMObject *obj, NSUInteger idx, BOOL *stop) {
                    NSMutableArray *objectIds = [obj.aclIds mutableCopy];
                    [objectIds removeObjectsInArray:[results allKeys]];
                    obj.aclIds = [objectIds copy];
                }];
                
                [allSuccess addEntriesFromDictionary:results];
            } else if (errors) {
                [allErrors addEntriesFromDictionary:errors];
            }
            
            index++;
            if (index < acls.count) {
                CMACL *acl = [acls objectAtIndex:index];
                [webService deleteACLWithKey:acl.objectId user:user successHandler:successHandler errorHandler:errorHandler];
            } else {
                CMDeleteResponse *response = [[CMDeleteResponse alloc] initWithSuccess:allSuccess errors:allErrors];
                if (callback)
                    callback(response);
            }
        };
        
        CMACL *acl = [acls objectAtIndex:index];
        //[webService deleteACLWithKey:acl.objectId user:user successHandler:successHandler errorHandler:errorHandler];
         */
    }];
}

#pragma mark Binary file loading

- (void)fileWithName:(NSString *)name additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileFetchCallback)callback {
    [self _fileWithName:name userLevel:NO additionalOptions:options callback:callback];
}

- (void)userFileWithName:(NSString *)name additionalOptions:options callback:(CMStoreFileFetchCallback)callback {
    _CMAssertUserConfigured;
    [self _ensureUserLoggedInWithCallback:^{
        [self _fileWithName:name userLevel:YES additionalOptions:options callback:callback];
    }];
}

- (void)_fileWithName:(NSString *)name userLevel:(BOOL)userLevel additionalOptions:(CMStoreOptions *)options callback:(CMStoreFileFetchCallback)callback {
    NSParameterAssert(name);
    /*
    [webService getBinaryDataNamed:name
                serverSideFunction:_CMTryMethod(options, serverSideFunction)
                              user:_CMUserOrNil
                   extraParameters:_CMTryMethod(options, buildExtraParameters)
                    successHandler:^(NSData *data, NSString *mimeType, NSDictionary *headers) {
                        CMFile *file = [[CMFile alloc] initWithData:data
                                                              named:name
                                                    belongingToUser:userLevel ? user : nil
                                                           mimeType:mimeType];
                        [file writeToCache];
                        CMFileFetchResponse *response = [[CMFileFetchResponse alloc] initWithFile:file];

                        NSDate *expirationDate = [self.dateFormatter dateFromString:[headers objectForKey:CM_TOKENEXPIRATION_HEADER]];
                        if (expirationDate && userLevel) {
                            user.tokenExpiration = expirationDate;
                        }

                        if (callback) {
                            callback(response);
                        }
                    } errorHandler:^(NSError *error) {
                        NSLog(@"CloudMine *** Error occurred downloading file with name: %@ for user: %@ with message: %@", name, _CMUserOrNil, [error description]);
                        CMFileFetchResponse *response = [[CMFileFetchResponse alloc] initWithError:error];
                        lastError = error;
                        if (callback) {
                            callback(response);
                        }
                    }
     ];*/
}

#pragma mark - In-memory caching

- (void)cacheObjectsInMemory:(NSArray *)objects atUserLevel:(BOOL)userLevel {
    NSAssert(userLevel ? (user != nil) : true, @"Failed trying to cache remote objects in-memory for user when user is not configured (%@)", self);

    @synchronized(self) {
        SEL addMethod = userLevel ? @selector(addUserObject:) : @selector(addObject:);
        for (CMObject *obj in objects) {
            [self performSelector:addMethod withObject:obj];
        }
    }
}

- (void)addACL:(CMACL *)acl {
    NSAssert(user != nil, @"Attempted to add ACL (%@) to store (%@) belonging to user when user is not set.", acl, self);
    NSAssert([acl isKindOfClass:[CMACL class]], @"Attempted to add object (%@) to store (%@) as an ACL.", acl, self);
    @synchronized(self) {
        [_cachedACLs setObject:acl forKey:acl.objectId];
    }
    
    if (acl.store != self) {
        acl.store = self;
    }
}

- (void)addUserObject:(CMObject *)theObject {
    NSAssert(user != nil, @"Attempted to add object (%@) to store (%@) belonging to user when user is not set.", theObject, self);
    NSAssert((![theObject isKindOfClass:[CMACL class]] && [theObject isKindOfClass:[CMObject class]]), @"Attempted to add ACL (%@) to store (%@) as a user-level object.", theObject, self);
    @synchronized(self) {
        [_cachedUserObjects setObject:theObject forKey:theObject.objectId];
    }

    if (theObject.store != self) {
        theObject.store = self;
    }
}

- (void)addObject:(CMObject *)theObject {
    NSAssert((![theObject isKindOfClass:[CMACL class]] && [theObject isKindOfClass:[CMObject class]]), @"Attempted to add ACL (%@) to store (%@) as an app-level object.", theObject, self);
    @synchronized(self) {
        [_cachedAppObjects setObject:theObject forKey:theObject.objectId];
    }

    if (theObject.store != self) {
        theObject.store = self;
    }
}

- (void)removeObject:(CMObject *)theObject {
    @synchronized(self) {
        [_cachedAppObjects removeObjectForKey:theObject.objectId];
    }

    if (theObject.store) {
        theObject.store = nil;
    }
}

- (void)removeUserObject:(CMObject *)theObject {
    @synchronized(self) {
        [_cachedUserObjects removeObjectForKey:theObject.objectId];
    }

    if (theObject.store) {
        theObject.store = nil;
    }
}

- (void)removeACL:(CMACL *)acl {
    @synchronized(self) {
        [_cachedACLs removeObjectForKey:acl.objectId];
    }
    
    if (acl.store) {
        acl.store = nil;
    }
}

- (void)addUserFile:(CMFile *)theFile {
    NSAssert(user != nil, @"Attempted to add File (%@) to store (%@) belonging to user when user is not set.", theFile, self);
    NSAssert([theFile isKindOfClass:[CMFile class]], @"Attempted to add object (%@) to store (%@) as a file.", theFile, self);
    @synchronized(self) {
        //[_cachedUserFiles setObject:theFile forKey:theFile.uuid];
    }
    
    if (theFile.store != self) {
        theFile.store = self;
    }
}

- (void)addFile:(CMFile *)theFile {
    NSAssert([theFile isKindOfClass:[CMFile class]], @"Attempted to add object (%@) to store (%@) as a file.", theFile, self);
    @synchronized(self) {
        //[_cachedAppFiles setObject:theFile forKey:theFile.uuid];
    }
    
    if (theFile.store != self) {
        theFile.store = self;
    }
}

- (void)removeFile:(CMFile *)theFile {
    @synchronized(self) {
        //[_cachedAppFiles removeObjectForKey:theFile.uuid];
    }
    
    if (theFile.store) {
        theFile.store = nil;
    }
}

- (void)removeUserFile:(CMFile *)theFile {
    @synchronized(self) {
        //[_cachedUserFiles removeObjectForKey:theFile.uuid];
    }
    
    if (theFile.store) {
        theFile.store = nil;
    }
}

#pragma mark - Helper functions

- (void)_ensureUserLoggedInWithCallback:(void (^)(void))callback {
    NSAssert(user != nil, @"CloudMine *** Attemping to log user in when user is not set on store. This is from an internal function and should never happen unless you are doing bad things!");
    if (!user.authenticated) {
        /*[user loginWithCallback:^(CMUserAccountResult resultCode, NSArray *messages) {
            if (CMUserAccountOperationFailed(resultCode)) {
                NSLog(@"CloudMine *** Failed to login user during store operation");
                lastError = $makeErr(@"CloudMineUserLoginErrorDomain", 0, $dict(@"user", user, @"resultCode", $num(resultCode)));
            } else {
                callback();
            }
        }];*/
    } else {
        callback();
    }
}

#pragma mark - New stuff

@end
