//
//  STTwitterWeb.h
//  STTwitterRequests
//
//  Created by Nicolas Seriot on 9/13/12.
//  Copyright (c) 2012 Nicolas Seriot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STTwitterHTML : NSObject

- (void)getLoginForm:(void(^)(NSString *authenticityToken))successBlock
            errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postLoginFormWithUsername:(NSString *)username
                                 password:(NSString *)password
                        authenticityToken:(NSString *)authenticityToken
                             successBlock:(void(^)())successBlock
                               errorBlock:(void(^)(NSError *error))errorBlock;


/**/

- (void)getAuthorizeFormAtURL:(NSURL *)url
                   successBlock:(void(^)(NSString *authenticityToken, NSString *oauthToken))successBlock
                     errorBlock:(void(^)(NSError *error))errorBlock;

- (void)postAuthorizeFormResultsAtURL:(NSURL *)url
                    authenticityToken:(NSString *)authenticityToken
                           oauthToken:(NSString *)oauthToken
                         successBlock:(void(^)(NSString *PIN))successBlock
                           errorBlock:(void(^)(NSError *error))errorBlock;

@end

@interface NSString (STTwitterHTML)
- (NSString *)extractFirstMatchWithRegex:(NSString *)regex error:(NSError **)e;
@end
