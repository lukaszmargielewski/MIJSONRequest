//
//  AppDelegate.m
//  MIJSONRequestExample
//
//  Created by Lukasz Margielewski on 29/05/15.
//  Copyright (c) 2015 Lukasz Margielewski. All rights reserved.
//

#import "AppDelegate.h"
#import "MIJSONRequestAuthenticationPinCertificateSHA256.h"
#import "MIJSONRequestManager.h"

#define EXPECTED_CERTIFICATE_BASE64_SHA256 @"a09eab79b96bde078eebc8dc5875bddbf8744e80b678412fb44517dae6d1d3ec"
#define WEBSERVICE_URL @"https://webservice.mobile-identity.com/plugins/mflife/json"
#define HOST_NAME @"http://www.mobile-identity.com"
#define SECURE_SESSION_NAME @"default_session"

@interface AppDelegate ()
@property (nonatomic, strong) MIJSONRequestAuthenticationPinCertificateSHA256 *exampleAuthenticate;
@property (nonatomic, strong) MIJSONRequestManager *requestManager;
@end

@implementation AppDelegate

+ (MIJSONRequestManager *)requestManager{

    AppDelegate *appDel = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDel.requestManager;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.requestManager = [MIJSONRequestManager requestManagerWithUrlString:WEBSERVICE_URL
                                                                   hostName:HOST_NAME
                                                           loginSessionName:SECURE_SESSION_NAME];
    
    self.requestManager.httpMethodDefault   = kMIJSONRequestManagerHttpMethodPOST;
    self.exampleAuthenticate                = [[MIJSONRequestAuthenticationPinCertificateSHA256 alloc] init];
    self.exampleAuthenticate.certificateSha = EXPECTED_CERTIFICATE_BASE64_SHA256;
    self.requestManager.authDelegate        = self.exampleAuthenticate;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
