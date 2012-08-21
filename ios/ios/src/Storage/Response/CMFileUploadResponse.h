//
//  CMFileUploadResponse.h
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import <Foundation/Foundation.h>
#import "CMStoreResponse.h"

/**
 * Response object returned after a file upload request.
 */
@interface CMFileUploadResponse : CMStoreResponse

/**
 * A result indicating whether or not the upload operation was successful.
 */
@property int result;
/**
 * The key of the newly created file.
 */
@property (strong, nonatomic) NSString *key;

- (id)initWithResult:(int)result key:(NSString *)key;
- (id)initWithResult:(int)result key:(NSString *)key snippetResult:(CMSnippetResult *)snippetResult;
- (id)initWithResult:(int)result key:(NSString *)key snippetResult:(CMSnippetResult *)snippetResult responseMetadata:(CMResponseMetadata *)metadata;

@end
