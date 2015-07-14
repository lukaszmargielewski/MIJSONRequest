//
//  MIJSONRequestSelfSigned.h

//
//  Created by Lukasz Margielewski on 02/06/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "MIJSONRequest.h"

@protocol MIJSONRequestAuthenticationDelegate;
@interface MIJSONRequestAuthenticate : MIJSONRequest

@property (nonatomic, assign) id <MIJSONRequestAuthenticationDelegate> authDelegate;
@end


#pragma mark - Authentication Protocol:

@protocol MIJSONRequestAuthenticationDelegate <NSObject>
- (BOOL)action:(MIJSONRequest *)action connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;
@optional
- (void)action:(MIJSONRequest *)action connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end