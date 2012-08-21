//
//  CMObject.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

@class CMUser;
@class CMStore;

/**
  The base class for all CloudMine objects. Anything inheriting from this class can be easily persisted to CloudMine's data store.
 */
@interface CMObject : NSObject <NSCoding>

/**
  The unique ID of the object. This is automatically generated when an object is instantiated
 */
@property (strong, readonly) NSString *objectId;

/**
  The owner of the object. It is nil if the object is app-level.
 
  @see CMUser
 */
@property (readonly, strong, nonatomic) CMUser *owner;

/**
 
  @see CMStore
  */
@property (weak) CMStore *store;

/**
  This indicates whether or not the object is 'dirty'.
 
  If the object is dirty, it will be uploaded upon a save, and if it is clean, it will not be uploaded. Upon initialization, objects as dirty, unless they are loaded from the web service, in which case they are marked as clean. By default, an object is marked as dirty when a KVO notification is sent, and it is marked as clean when it is successfully uploaded to CloudMine. Subclasses may modify this property as they see fit, to account for internal state changes.
 */
@property (readonly, getter=isDirty) BOOL dirty;

/**
  The name of the class, to be used by CloudMine. This is for cross-platform compatibility purposes. The default implementation returns the name of the class.
 
  @returns The name of the class to be used for encoding the object
 */
+ (NSString *)className;

/**
  This initializes an object with the specified ID. If no ID is specified, one is automatically generated.
 
  @param objectId The ID to create the object with
  @returns An initialized instance of CMObject with the specified ID
 */
- (id)initWithObjectId:(NSString *)objectId;

@end