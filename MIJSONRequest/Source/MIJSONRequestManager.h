//
//  RequestManager.h
//  MobileFitness
//
//  Created by Lukasz Margielewski on 12/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIJSONRequest.h"
#import "Reachability.h"
#import "MIJSONRequestSecureSession.h"

extern NSString *kMIJSONRequestManagerConnectionToHostChangedNotification;
extern NSString *kMIJSONRequestManagerHttpMethodGET;
extern NSString *kMIJSONRequestManagerHttpMethodPOST;


typedef NS_ENUM(NSUInteger, MIJSONRequestManagerLoginSessionType){

    MIJSONRequestManagerLoginSession_AddedToRequestBody = 0,
    MIJSONRequestManagerLoginSession_AddedToRequestHTTPHeaders,
};
@interface MIJSONRequestManager : NSObject <MIJSONRequestDelegate> {

	// Actions:
	NSMutableArray *actionsInProgress;
	
	Reachability* _hostReachable;
    
	NetworkStatus hostStatus;
    NetworkStatus hs_before;
    
	BOOL hostActive, connected, connected_before;

    BOOL status_known;
	
}

@property (nonatomic, strong, readonly) NSString     *hostName;
@property (nonatomic, strong, readonly) NSURL       *webserviceUrl;

@property (nonatomic, strong)           NSString               *httpMethodDefault;
@property (nonatomic, strong)           NSMutableDictionary    *httpHeadersDefault;
@property (nonatomic, strong)           NSMutableDictionary    *requestParametersDefault;

@property (nonatomic, readonly) BOOL connected, connected_before;
@property (nonatomic, readonly) NetworkStatus hostStatus;
@property (nonatomic, assign) id<MIJSONRequestAuthenticationDelegate>authDelegate;

@property (nonatomic, strong, readonly) MIJSONRequestSecureSession *loginSession;
@property (nonatomic, strong) NSArray *sessionRequestKeys;
@property (nonatomic) MIJSONRequestManagerLoginSessionType sessionType;


#pragma mark - Default Manager:

+(void)configureDefaultManagerWithUrlString:(NSString *)urlString
                                   hostName:(NSString *)hostName
                           loginSessionName:(NSString *)loginSessionName;


+(instancetype)defaultManager;


#pragma mark - Init:

+(instancetype)requestManagerWithUrlString:(NSString *)urlString
                                  hostName:(NSString *)hostName
                          loginSessionName:(NSString *)loginSessionName;

-(instancetype)initWithUrlString:(NSString *)urlString
                        hostName:(NSString *)hostName
                loginSessionName:(NSString *)loginSessionName NS_DESIGNATED_INITIALIZER;


#pragma mark - API:

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                           startBlock:(MIJSONRequestManagerRequestStartBlock)startBlock
                        progressBlock:(MIJSONRequestManagerRequestProgressBlock)progressBlock
                      completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock
                               client:(id)client;

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                                 name:(NSString *)name
                           startBlock:(MIJSONRequestManagerRequestStartBlock)startBlock
                        progressBlock:(MIJSONRequestManagerRequestProgressBlock)progressBlock
                      completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock
                               client:(id)client;

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                          httpHeaders:(NSDictionary *)httpHeaders
                           httpMethod:(NSString *)httpMethod
                                 name:(NSString *)name
                           startBlock:(MIJSONRequestManagerRequestStartBlock)startBlock
                        progressBlock:(MIJSONRequestManagerRequestProgressBlock)progressBlock
                      completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock
                               client:(id)client;



-(void)cancelRequest:(MIJSONRequest *)request;
-(void)cancelRequestsWithName:(NSString *)name;
-(void)cancelAllRequests;
-(void)cancelAllRequestsForClient:(id)client;


@end
#pragma mark - Interbla object:

@interface MIJSONRequestManagerRequestObject : NSObject

@property (nonatomic, strong) MIJSONRequest *request;
@property (nonatomic, assign) id client;

@property (nonatomic, assign) id<MIJSONRequestDelegate>delegate;

+(instancetype)requestObjectWithRequest:(MIJSONRequest *)request
                                 client:(id)client;

@end


