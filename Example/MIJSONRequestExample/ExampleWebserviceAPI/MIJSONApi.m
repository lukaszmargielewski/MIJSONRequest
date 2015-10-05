//
//  MIJSONApi.m
//  Hillerod
//
//  Created by Lukasz Margielewski on 03/06/15.
//  Copyright (c) 2015 Mobile Fitness. All rights reserved.
//

#import "MIJSONApi.h"

#import "MIJSONRequestAuthenticationPinCertificateSHA256.h"
#import "MIJSONApiAuthenticateAll.h"

#define EXPECTED_CERTIFICATE_BASE64_SHA256 @"enter sha here"
#define WEBSERVICE_URL @"http://google.com"
#define HOST_NAME @"http://google.com"
#define SECURE_SESSION_NAME @"default_session"

NSString *kMIJSONApi_SessionKey = @"session_key";
NSString *kMIJSONApi_DeviceIdKey = @"deviceId";


@interface MIJSONApi()
@property (nonatomic, strong) MIJSONRequestManager *requestManager;

@property (nonatomic, strong) MIJSONRequestAuthenticationPinCertificateSHA256 *exampleSHA256CertificatePinAuthenticate;
@property (nonatomic, strong) MIJSONApiAuthenticateAll *allowAllDebugAuthenticate;
@end

@implementation MIJSONApi{

    NSString *_uniquePersistentDeviceID;
}
+(MIJSONRequestManager *)requestManager{

    return [MIJSONApi singleton].requestManager;
}
-(MIJSONRequestManager *)requestManager{

    if (!_requestManager) {
        
        // 2. Default webservice configuration:
        self.requestManager = [MIJSONRequestManager requestManagerWithUrlString:WEBSERVICE_URL hostName:HOST_NAME loginSessionName:SECURE_SESSION_NAME];
        
        self.requestManager.httpMethodDefault     = kMIJSONRequestManagerHttpMethodPOST;
        self.requestManager.sessionRequestKeys    = @[kMIJSONApi_SessionKey];
        self.requestManager.sessionType           = MIJSONRequestManagerLoginSession_AddedToRequestBody;
        
        
        /*
         
         self.requestManager = [MIJSONRequestManager requestManagerWithUrlString:WEBSERVICE_URL
         hostName:HOST_NAME
         loginSessionName:SECURE_SESSION_NAME];
         
         self.requestManager.httpMethodDefault   = kMIJSONRequestManagerHttpMethodPOST;
         self.exampleAuthenticate                = [[MIJSONRequestAuthenticationPinCertificateSHA256 alloc] init];
         self.exampleAuthenticate.certificateSha = EXPECTED_CERTIFICATE_BASE64_SHA256;
         self.requestManager.authDelegate        = self.exampleAuthenticate;
         */
        /*
        self.exampleSHA256CertificatePinAuthenticate                = [[MIJSONRequestAuthenticationPinCertificateSHA256 alloc] init];
        self.exampleSHA256CertificatePinAuthenticate.certificateSha = EXPECTED_CERTIFICATE_BASE64_SHA256;
        
        self.requestManager.authDelegate          = self.exampleSHA256CertificatePinAuthenticate;
        
        */
        self.allowAllDebugAuthenticate              = [[MIJSONApiAuthenticateAll alloc] init];
        self.requestManager.authDelegate            = self.allowAllDebugAuthenticate;
        
        _uniquePersistentDeviceID = [UIDevice currentDevice].identifierForVendor.UUIDString;
        
        self.requestManager.requestParametersDefault = [[NSMutableDictionary alloc] initWithDictionary: @{kMIJSONApi_DeviceIdKey: _uniquePersistentDeviceID}];

        
    }
    
    return _requestManager;

}
+(instancetype)singleton{
    
    static dispatch_once_t pred;
    static MIJSONApi *shared = nil;
    
    dispatch_once(&pred, ^{
        
        shared = [[MIJSONApi alloc] init];
        
        
    });
    return shared;
}
@end
