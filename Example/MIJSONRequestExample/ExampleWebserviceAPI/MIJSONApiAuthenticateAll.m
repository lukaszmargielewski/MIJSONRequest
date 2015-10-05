//
//  MIJSONApiAuthenticateAll.m
//  Hillerod
//
//  Created by Lukasz Margielewski on 06/06/15.
//  Copyright (c) 2015 Mobile Fitness. All rights reserved.
//

#import "MIJSONApiAuthenticateAll.h"

@implementation MIJSONApiAuthenticateAll

- (BOOL)action:(MIJSONRequest *)action connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{

    return YES;
}

- (void)action:(MIJSONRequest *)action connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


@end


