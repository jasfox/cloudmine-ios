//
//  CMWebService.m
//  cloudmine-ios
//
//  Copyright (c) 2012 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMWebService.h"

NSString * const CMErrorDomain = @"CMErrorDomain";

static CMWebService *sharedWebService;

@interface CMUser (Private)
@property (strong, nonatomic) NSString *token;
@property (readwrite, strong, nonatomic) NSDate *tokenExpiration;
@end

@interface CMWebService ()
@property (readwrite, strong, nonatomic) CMUser *user;
@end

@implementation CMWebService

+ (CMWebService *)sharedWebService {
    if (!sharedWebService) {
        sharedWebService = [[CMWebService alloc] init];
    }
    return sharedWebService;
}

- (id)init {
    if ((self = [super initWithBaseURL:[NSURL URLWithString:@"https://api.cloudmine.me/v1"]])) {
        // Let's use JSON!
        self.parameterEncoding = AFJSONParameterEncoding;
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        
        // Create date formatter
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.dateFormat = @"EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'";
        _dateFormatter.lenient = YES;
        
        // Create UUID to default on if no active user exists
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        CFUUIDRef uuid = CFUUIDCreate(NULL);
        NSString *uuidString = [[(__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid) stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];
        [defaults registerDefaults:@{ @"CMActiveUser" : uuidString }];
        CFRelease(uuid);
        
        // Load active user
        NSString *activeUser = [[NSUserDefaults standardUserDefaults] objectForKey:@"CMActiveUser"];
        [self setDefaultHeader:@"X-CloudMine-UT" value:activeUser];

        // Save the active user
        [defaults setObject:activeUser forKey:@"CMActiveUser"];
        [defaults synchronize];
        
        // Set other default headers
        [self setDefaultHeader:@"X-CloudMine-Agent" value:[NSString stringWithFormat:@"CM-iOS/%@", CM_VERSION]];
        
        // Reachability handling
        __weak CMWebService *blockSelf = self;
        [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            [blockSelf.operationQueue setSuspended:(status == AFNetworkReachabilityStatusNotReachable)];
        }];
    }
    return self;
}

- (void)setApiKey:(NSString *)apiKey {
    if (_apiKey != apiKey) {
        _apiKey = apiKey;
        
        [self setDefaultHeader:@"X-CloudMine-ApiKey" value:_apiKey];
    }
}

- (void)setUser:(CMUser *)user {
    // This is only to be called once the user is successfully logged in
    if (!user.authenticated)
        return;
    
    if (_user.authenticated) {
        // Log them out! Not of utmost importance
    }
    
    _user = user;
    
    [self setDefaultHeader:@"X-CloudMine-SessionToken" value:_user.token];
}

#pragma mark - Error construction

- (NSError *)errorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *mutUserInfo = [NSMutableDictionary dictionaryWithDictionary:userInfo];
    
    if (![mutUserInfo objectForKey:NSLocalizedDescriptionKey]) {
        switch (code) {
            case CMErrorInternalServer:
                [mutUserInfo setObject:@"Unknown internal server error." forKey:NSLocalizedDescriptionKey];
                break;
            
            case CMErrorInvalidResponse:
                [mutUserInfo setObject:@"The response data returned from the server was not in the proper format." forKey:NSLocalizedDescriptionKey];
                break;
                
            case CMErrorConnectionFailed:
                [mutUserInfo setObject:@"The connection to CloudMine's servers failed. See the underlying error for more information." forKey:NSLocalizedDescriptionKey];
                
            case CMErrorUnknown:
                [mutUserInfo setObject:@"An unknown error occured. See the underlying error for more information." forKey:NSLocalizedDescriptionKey];
                
            default:
                break;
        }
    }
    
    userInfo = [NSDictionary dictionaryWithDictionary:mutUserInfo];
    NSError *error = [NSError errorWithDomain:CMErrorDomain code:code userInfo:userInfo];
    
    NSLog(@"CloudMine *** %@\n%@\n", [error localizedDescription], error);
    
    return error;
}

#pragma mark - Operation construction

- (AFHTTPRequestOperation *)HTTPRequestOperationWithRequest:(NSURLRequest *)request success:(void (^)(AFHTTPRequestOperation *, id))success failure:(void (^)(AFHTTPRequestOperation *, NSError *))failure {
    NSAssert(_apiKey, @"You must provide an API key before attempting to use the web service.");
    return [super HTTPRequestOperationWithRequest:request
                                          success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                              NSDate *expirationDate = [_dateFormatter dateFromString:[[operation.response allHeaderFields] objectForKey:@"X-CloudMine-TE"]];
                                              if (expirationDate) {
                                                  _user.tokenExpiration = expirationDate;
                                              }
                                              
                                              success(operation, responseObject);
                                          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                              if (error) {
                                                  NSDictionary *userInfo = [NSDictionary dictionaryWithObject:error forKey:NSUnderlyingErrorKey];
                                                  NSInteger code = CMErrorUnknown;
                                                  
                                                  // Map existing error codes to 
                                                  if ([error.domain isEqualToString:AFNetworkingErrorDomain]) {
                                                      if (error.code == NSURLErrorBadServerResponse) {
                                                          switch ([operation.response statusCode]) {
                                                              case 500:
                                                                  code = CMErrorInternalServer;
                                                                  break;
                                                                  
                                                              case 401:
                                                                  code = CMErrorAuthenticationFailed;
                                                                  break;
                                            
                                                              // TODO: Handle other error codes
                                                                  
                                                              default:
                                                                  break;
                                                          }
                                                      } else if (error.code == NSURLErrorCannotDecodeContentData) {
                                                          code = CMErrorInvalidResponse;
                                                      }
                                                  } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
                                                      if (error.code == NSURLErrorUserAuthenticationRequired) {
                                                          code = CMErrorAuthenticationFailed;
                                                      } else {
                                                          code = CMErrorConnectionFailed;
                                                      }
                                                  }
                                                  
                                                  error = [self errorWithCode:code userInfo:userInfo];
                                              }
                                              
                                              failure(operation, error);
                                          }];
}

#pragma mark - Request construction

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters {
    NSAssert(_appIdentifier, @"You must provide an application identifier before attempting to use the web service.");
    path = [NSString stringWithFormat:@"/app/%@%@", _appIdentifier, path];
    return [super requestWithMethod:method path:path parameters:parameters];
}

#pragma mark - Path construction

#pragma mark User Level

- (NSString *)pathWithEndpoint:(NSString *)endpoint parameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel {
    endpoint = [endpoint stringByAppendingFormat:[endpoint rangeOfString:@"?"].location == NSNotFound ? @"?%@" : @"&%@", AFQueryStringFromParametersWithEncoding(parameters, self.stringEncoding)];
    if (userLevel) {
        endpoint = [@"/user" stringByAppendingString:endpoint];
    }
    return endpoint;
}

#pragma mark Text

- (NSString *)textPathWithParameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel {
    return [self pathWithEndpoint:@"/text" parameters:parameters userLevel:userLevel];
}

- (NSString *)textPathWithQuery:(NSString *)query parameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel {
    if (query) {
        NSMutableDictionary *mutParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutParams setObject:query forKey:@"q"];
        parameters = [mutParams copy];
        
        return [self pathWithEndpoint:@"/search" parameters:parameters userLevel:userLevel];
    }
    
    return [self textPathWithParameters:parameters userLevel:userLevel];
}

#pragma mark Binary

- (NSString *)binaryPathWithKey:(NSString *)key parameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel {
    NSString *endpoint = @"/binary";
    if (key) {
        endpoint = [endpoint stringByAppendingFormat:@"/%@", key];
    }
    return [self pathWithEndpoint:endpoint parameters:parameters userLevel:userLevel];
}

#pragma mark Data

- (NSString *)dataPathWithParameters:(NSDictionary *)parameters userLevel:(BOOL)userLevel {
    return [self pathWithEndpoint:@"/data" parameters:parameters userLevel:userLevel];
}

#pragma mark Access Control

- (NSString *)accessPathWithParameters:(NSDictionary *)parameters {
    return [self accessPathWithKey:nil parameters:parameters];
}

- (NSString *)accessPathWithKey:(NSString *)key parameters:(NSDictionary *)parameters {
    NSString *endpoint = @"/access";
    if (key) {
        endpoint = [endpoint stringByAppendingFormat:@"/%@", key];
    }
    return [self pathWithEndpoint:endpoint parameters:parameters userLevel:YES];
}

- (NSString *)accessPathWithQuery:(NSString *)query parameters:(NSDictionary *)parameters {
    NSString *endpoint = @"/access";
    if (query) {
        NSMutableDictionary *mutParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutParams setObject:query forKey:@"q"];
        parameters = [mutParams copy];
        
        endpoint = [endpoint stringByAppendingString:@"/search"];
    }
    return [self pathWithEndpoint:endpoint parameters:parameters userLevel:YES];
}

#pragma mark User Accounts

- (NSString *)accountPathWithParameters:(NSDictionary *)parameters {
    return [self accessPathWithKey:nil parameters:parameters];
}

- (NSString *)accountPathWithKey:(NSString *)key parameters:(NSDictionary *)parameters {
    NSString *endpoint = @"/account";
    if (key) {
        endpoint = [endpoint stringByAppendingFormat:@"/%@", key];
    }
    return [self pathWithEndpoint:endpoint parameters:parameters userLevel:NO];
}

- (NSString *)accountPathWithQuery:(NSString *)query parameters:(NSDictionary *)parameters {
    NSString *endpoint = @"/account";
    if (query) {
        NSMutableDictionary *mutParams = [NSMutableDictionary dictionaryWithDictionary:parameters];
        [mutParams setObject:query forKey:@"p"];
        parameters = [mutParams copy];
        
        endpoint = [endpoint stringByAppendingString:@"/search"];
    }
    return [self pathWithEndpoint:endpoint parameters:parameters userLevel:NO];
}

- (NSString *)accountCreatePathWithParameters:(NSDictionary *)parameters {
    return [self pathWithEndpoint:@"/account/create" parameters:parameters userLevel:NO];
}

- (NSString *)accountLoginPathWithParameters:(NSDictionary *)parameters {
    return [self pathWithEndpoint:@"/account/login" parameters:parameters userLevel:NO];
}

- (NSString *)accountLogoutPathWithParameters:(NSDictionary *)parameters {
    return [self pathWithEndpoint:@"/account/logout" parameters:parameters userLevel:NO];
}

- (NSString *)accountPasswordChangePathWithParameters:(NSDictionary *)parameters {
    return [self pathWithEndpoint:@"/account/password/change" parameters:parameters userLevel:NO];
}

- (NSString *)accountPasswordResetPathWithParameters:(NSDictionary *)parameters {
    return [self pathWithEndpoint:@"/account/password/reset" parameters:parameters userLevel:NO];
}

@end