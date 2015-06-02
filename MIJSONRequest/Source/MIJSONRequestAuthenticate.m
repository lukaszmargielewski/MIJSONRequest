//
//  MIJSONRequestSelfSigned.m
//  Hillerod
//
//  Created by Lukasz Margielewski on 02/06/15.
//  Copyright (c) 2015 Mobile Fitness. All rights reserved.
//

#import "MIJSONRequestAuthenticate.h"

@implementation MIJSONRequestAuthenticate

#pragma mark - Authentication:

+(instancetype)requestWithUrl:(NSURL *)url httpHeaders:(NSDictionary *)httpHeaders httpMethod:(NSString *)httpMethod body:(NSDictionary *)requestDictionary delegate:(id<MIJSONRequestDelegate>)delegate{
    
    MIJSONRequestAuthenticate *a = [[MIJSONRequestAuthenticate alloc] initWithUrl:url httpHeaders:httpHeaders httpMethod:httpMethod body:requestDictionary delegate:delegate];
    return a;
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    
    if (_authDelegate) {
        return [_authDelegate action:self connection:connection canAuthenticateAgainstProtectionSpace:protectionSpace];
    }
    
    return YES;
}
- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    
    
    if (_authDelegate && [_authDelegate respondsToSelector:@selector(action:connection:didReceiveAuthenticationChallenge:)]) {
        
        [_authDelegate action:self connection:connection didReceiveAuthenticationChallenge:challenge];
        
    }else{
        
        [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
    
}
@end
