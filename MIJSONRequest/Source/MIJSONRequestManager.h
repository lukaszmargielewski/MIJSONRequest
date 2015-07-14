//
//  RequestManager.h
//  MobileFitness
//
//  Created by Lukasz Margielewski on 12/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIJSONRequestAuthenticate.h"
#import "Reachability.h"
#import "MIJSONRequestSecureSession.h"

extern NSString *kMIJSONRequestManagerConnectionToHostChangedNotification;
extern NSString *kMIJSONRequestManagerHttpMethodGET;
extern NSString *kMIJSONRequestManagerHttpMethodPOST;

@protocol MIJSONRequestManagerURLEncoder <NSObject>

-(NSString *)encodeRequestDictionary:(NSDictionary *)requestDictionary;

@end

typedef NS_ENUM(NSUInteger, MIJSONRequestManagerLoginSessionType){

    MIJSONRequestManagerLoginSession_AddedToRequestBody = 0,
    MIJSONRequestManagerLoginSession_AddedToRequestHTTPHeaders,
};

@protocol MIJSONRequestManagerActivityObserver;

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
@property (nonatomic, assign) id<MIJSONRequestManagerURLEncoder>urlEncoder;

@property (nonatomic, strong, readonly) MIJSONRequestSecureSession *loginSession;
@property (nonatomic, strong) NSArray *sessionRequestKeys;
@property (nonatomic) MIJSONRequestManagerLoginSessionType sessionType;

#pragma mark - Init:

+(instancetype)requestManagerWithUrlString:(NSString *)urlString
                                  hostName:(NSString *)hostName
                          loginSessionName:(NSString *)loginSessionName;

-(instancetype)initWithUrlString:(NSString *)urlString
                        hostName:(NSString *)hostName
                loginSessionName:(NSString *)loginSessionName NS_DESIGNATED_INITIALIZER;


#pragma mark - API:

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                                 completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock;

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

-(MIJSONRequest *)requestWithJSONDictionary:(NSDictionary *)reqestDictionary
                                httpHeaders:(NSDictionary *)httpHeaders
                                 httpMethod:(NSString *)httpMethod
                                       name:(NSString *)name;


-(void)cancelRequest:(MIJSONRequest *)request;
-(void)cancelRequestsWithName:(NSString *)name;
-(void)cancelAllRequests;
-(void)cancelAllRequestsForClient:(id)client;

-(void)addActivityObserver:(id<MIJSONRequestManagerActivityObserver>)activityObserver;
-(void)removeActivityObserver:(id<MIJSONRequestManagerActivityObserver>)activityObserver;

@end

@protocol MIJSONRequestManagerActivityObserver <NSObject>
@optional
-(void)MIJSONRequestManagerDidResumeRequests:(MIJSONRequestManager *)manager;
-(void)MIJSONRequestManagerDidFinishAllRequests:(MIJSONRequestManager *)manager
                                downloadedBytes:(unsigned long long)downloadedBytes;

-(void)MIJSONRequestManager:(MIJSONRequestManager *)manager
     didUpdateTotalProgress:(float)progress
            downloadedBytes:(unsigned long long)downloadedBytes
       totalBytesToDownload:(unsigned long long)totalBytesToDownload
              requestsCount:(NSUInteger)requestsCount;



-(void)MIJSONRequestManager:(MIJSONRequestManager *)manager connectionToHostChanged:(BOOL)connected;

@end

#pragma mark - Internal object:

@interface MIJSONRequestManagerRequestObject : NSObject

@property (nonatomic, strong) MIJSONRequest *request;
@property (nonatomic, assign) id client;

@property (nonatomic, assign) id<MIJSONRequestDelegate>delegate;

+(instancetype)requestObjectWithRequest:(MIJSONRequest *)request
                                 client:(id)client;

@end



