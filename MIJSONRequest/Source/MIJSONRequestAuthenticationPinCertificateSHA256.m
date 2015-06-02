//
//  MIJSONRequestAuthenticateSimple.m
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 01/06/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "MIJSONRequestAuthenticationPinCertificateSHA256.h"
#import <CommonCrypto/CommonDigest.h>
#import "NSData+Base64.h"

@implementation MIJSONRequestAuthenticationPinCertificateSHA256

/**
 * Computes a SHA256 hash of the string.
 * @return A SHA256 hash in hexadecimal representation (64 chars)
 */
+ (NSString*) SHA256L:(NSString *)string {
    
    const char *cStr = [string UTF8String];
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    
    CC_LONG lenght = (CC_LONG)strlen(cStr);
    CC_SHA256(cStr, lenght, result);
    
    NSString *s = [NSString  stringWithFormat:
                   @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                   result[0], result[1], result[2], result[3], result[4],
                   result[5], result[6], result[7],
                   result[8], result[9], result[10], result[11], result[12],
                   result[13], result[14], result[15],
                   result[16], result[17], result[18], result[19],
                   result[20], result[21], result[22], result[23], result[24],
                   result[25], result[26], result[27],
                   result[28], result[29], result[30], result[31]
                   ];
    return [s lowercaseString];
}

- (BOOL)action:(MIJSONRequest *)action connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    
    
    SecTrustRef trust = [protectionSpace serverTrust];
    
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(trust, 0);
    
    NSData* serverCertificateData = (__bridge NSData*)SecCertificateCopyData(certificate);
    
    NSString *serverCertificateDataHash = [MIJSONRequestAuthenticationPinCertificateSHA256 SHA256L:[serverCertificateData base64EncodedString]];
    
    NSLog(@"Implement auth cert hwith hash: %@", serverCertificateDataHash);
    
    // Check if the certificate returned from the server is identical to the saved certificate in
    // the main bundle
    BOOL areCertificatesEqual = ([serverCertificateDataHash isEqualToString:self.certificateSha]);
    
    if (!areCertificatesEqual)
    {
        DLog(@"Bad Certificate, canceling request: %@", serverCertificateDataHash);
        //[connection cancel];
    }else{
        DLog(@"Good Certificate, allowing request: %@", serverCertificateDataHash);
    }
    // If the certificates are not equal we should not talk to the server;
    return areCertificatesEqual;
}
- (void)action:(MIJSONRequest *)action connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
    }
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}


@end
