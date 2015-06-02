//
//  MIJSONRequestManager.m
//  MobileFitness
//
//  Created by Lukasz Margielewski on 12/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MIJSONRequestManager.h"
#define kReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"

NSString *kMIJSONRequestManagerConnectionToHostChangedNotification = @"kMIJSONRequestManagerConnectionToHostChangedNotification";
NSString *kMIJSONRequestManagerHttpMethodGET = @"GET";
NSString *kMIJSONRequestManagerHttpMethodPOST = @"POST";

@interface MIJSONRequestManager()

@end

@implementation MIJSONRequestManager{
    
    NSMutableSet *_requestsInProgress;

}
@synthesize connected = connected, connected_before;
@synthesize hostStatus;
@synthesize loginSession = _loginSession;

-(void)dealloc{
	
	[self cancelAllRequests];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
}

/*
-(id)init{
	
    NSAssert(NO, @"Direct init not allowed, use initWithUrlString:hostName: instead...");
    self = [super init];
    return nil;
}
 */

#pragma mark - Default Manager:

NSString *_urlString;
NSString *_hostName;
NSString *_loginSessionName;
NSArray *_sessionRequestKeys;

MIJSONRequestManagerLoginSessionType _sessionType;

+(void)configureDefaultManagerWithUrlString:(NSString *)urlString
                                   hostName:(NSString *)hostName
                           loginSessionName:(NSString *)loginSessionName{
    
    NSAssert1(_urlString == nil, @"MIHWebservices can be configred once only. _urlStrin already present = %@", _urlString);
    
    _urlString = urlString;
    _hostName = hostName;
    _loginSessionName = loginSessionName;

}

+(instancetype)defaultManager{
    
    static dispatch_once_t pred;
    static MIJSONRequestManager *shared = nil;
    
    dispatch_once(&pred, ^{

        NSAssert1(_urlString != nil, @"MIHWebservices must be configured, before calling its request manager! call configureWithUrlString.... first", _urlString);
        
        shared = [MIJSONRequestManager requestManagerWithUrlString:_urlString hostName:_hostName loginSessionName:_loginSessionName];
        
        
    });
    return shared;
    
    
}



#pragma mark - Designated initializer:

+(instancetype)requestManagerWithUrlString:(NSString *)urlString
                                  hostName:(NSString *)hostName
                          loginSessionName:(NSString *)loginSessionName{

    MIJSONRequestManager *rm = [[MIJSONRequestManager alloc] initWithUrlString:urlString hostName:hostName loginSessionName:loginSessionName];
    return rm;
}

-(instancetype)initWithUrlString:(NSString *)urlString
                        hostName:(NSString *)hostName
                loginSessionName:(NSString *)loginSessionName{

    NSAssert(urlString != nil, @"urlString must not be nil");
    NSAssert(hostName != nil, @"hostName must not be nil");
    
    self = [super init];
    
    if (self) {
        _webserviceUrl = [NSURL URLWithString:urlString];
        _hostName = hostName;
        // check for internet connection
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkNetworkStatus:) name:kReachabilityChangedNotification object:nil];
        hostStatus = NotReachable;        // Unknown
        hs_before = NotReachable;
        status_known = NO;
        _httpMethodDefault = kMIJSONRequestManagerHttpMethodGET;

        
        if (loginSessionName) {
            _loginSession = [MIJSONRequestSecureSession sessionWithIdentifier:loginSessionName];
        }
        
        _hostReachable = [Reachability reachabilityWithHostName:self.hostName];
        [_hostReachable startNotifier];

        hostStatus      = [_hostReachable currentReachabilityStatus];
        connected       = connected_before = (hostStatus == NotReachable) ? NO : YES;
        
    }
    return self;
}


#pragma mark - Scheduling requests:

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                           startBlock:(MIJSONRequestManagerRequestStartBlock)startBlock
                        progressBlock:(MIJSONRequestManagerRequestProgressBlock)progressBlock
                      completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock
                               client:(id)client{

    return [self startRequestWithJSONDictionary:reqestDictionary
                                    httpHeaders:nil
                                     httpMethod:self.httpMethodDefault
                                           name:nil startBlock:startBlock
                                  progressBlock:progressBlock
                                completionBlock:completionBlock
                                         client:client];
}

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                                 name:(NSString *)name
                           startBlock:(MIJSONRequestManagerRequestStartBlock)startBlock
                        progressBlock:(MIJSONRequestManagerRequestProgressBlock)progressBlock
                      completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock
                               client:(id)client{
    
    return [self startRequestWithJSONDictionary:reqestDictionary
                                    httpHeaders:nil
                                     httpMethod:self.httpMethodDefault
                                           name:name
                                     startBlock:startBlock
                                  progressBlock:progressBlock
                                completionBlock:completionBlock
                                         client:client];
}

-(MIJSONRequest *)startRequestWithJSONDictionary:(NSDictionary *)reqestDictionary
                          httpHeaders:(NSDictionary *)httpHeaders
                           httpMethod:(NSString *)httpMethod
                                 name:(NSString *)name
                           startBlock:(MIJSONRequestManagerRequestStartBlock)startBlock
                        progressBlock:(MIJSONRequestManagerRequestProgressBlock)progressBlock
                      completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock
                               client:(id)client{
    
    if (!self.connected) {
        return nil;
    }
    
    // Generate name:
    if (!name) {
        
        name = [self stringWithRequestDictionary:reqestDictionary];
        if (httpHeaders && httpHeaders != self.httpHeadersDefault) {
            NSString *nh = [self stringWithRequestDictionary:httpHeaders];
            name = [NSString stringWithFormat:@"%@_%@", nh, name];
        }
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    NSSet *similarScheduled = [_requestsInProgress filteredSetUsingPredicate:predicate];
    
    if (similarScheduled && similarScheduled.count) {
    
        MIJSONRequestManagerRequestObject *ro = [similarScheduled anyObject];
        if (ro) {
            
            NSLog(@"Similar request (name: %@) already scheduled already in progress: %@", name, ro.request.requestDictionary);
            return nil;
        }
    }
    
    NSMutableDictionary *finalRequestBody = [NSMutableDictionary dictionaryWithCapacity:10];
    NSMutableDictionary *finalHTTPHeaders = [NSMutableDictionary dictionaryWithCapacity:10];
    
    NSDictionary *sessionDictionary = _loginSession.sessionDictionary;
    
    // 1. Add Login session parameters:
    if(sessionDictionary && sessionDictionary.allKeys.count){
        
        NSDictionary *loginSessionRequestValues = _sessionRequestKeys ? [sessionDictionary dictionaryWithValuesForKeys:_sessionRequestKeys] : sessionDictionary;
        if (loginSessionRequestValues) {
            
            switch (_sessionType) {
                case MIJSONRequestManagerLoginSession_AddedToRequestBody:
                    [finalRequestBody addEntriesFromDictionary:loginSessionRequestValues];
                    break;
                case MIJSONRequestManagerLoginSession_AddedToRequestHTTPHeaders:
                    [finalHTTPHeaders addEntriesFromDictionary:loginSessionRequestValues];
                    break;
                    
                default:
                    break;
            }
            
        }
    }
    
    // 2. Add default request parameters (if specified), f.x: login session, etc...
    if (self.requestParametersDefault && self.requestParametersDefault.allKeys.count) {
        
            [finalRequestBody addEntriesFromDictionary:_requestParametersDefault];
    }
    
    if (reqestDictionary && reqestDictionary.allKeys.count) {
        
        [finalRequestBody addEntriesFromDictionary:reqestDictionary];
    }
    
    // 3. Add default http headers (if specified), f.ex: login session or auth secrets, etc...
    if (self.httpHeadersDefault && self.httpHeadersDefault.allKeys.count) {
        
        [finalHTTPHeaders addEntriesFromDictionary:_httpHeadersDefault];
    }
    
    if (httpHeaders && httpHeaders.allKeys.count) {
        
        [finalHTTPHeaders addEntriesFromDictionary:httpHeaders];
    }

    
    MIJSONRequestAuthenticate *jsonRequest = nil;
    
    if (self.authDelegate) {
    
        jsonRequest = [MIJSONRequestAuthenticate requestWithUrl:self.webserviceUrl httpHeaders:finalHTTPHeaders httpMethod:httpMethod body:finalRequestBody delegate:self];
            jsonRequest.authDelegate    = self.authDelegate;
        
    }else{
    
        jsonRequest = [MIJSONRequest requestWithUrl:self.webserviceUrl httpHeaders:finalHTTPHeaders httpMethod:httpMethod body:finalRequestBody delegate:self];
        
    }
    
    jsonRequest.name            = name;
    jsonRequest.startBlock      = startBlock;
    jsonRequest.progressBlock   = progressBlock;
    jsonRequest.completionBlock = completionBlock;
        
        if (!_requestsInProgress) {
        
            _requestsInProgress = [[NSMutableSet alloc] init];
        }
    
    MIJSONRequestManagerRequestObject *ro = [MIJSONRequestManagerRequestObject requestObjectWithRequest:jsonRequest
                                                                                                 client:client];
    [_requestsInProgress addObject:ro];
    
    [jsonRequest start];
    
    return jsonRequest;
}

- (NSString *)stringWithRequestDictionary:(NSDictionary *)dictionary{
    
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:[dictionary count]];
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *value = [object isKindOfClass:[NSString class]] ? object : [object stringValue];
        
        [arguments addObject:[NSString stringWithFormat:@"%@=%@",
                              key,
                              value]];
    }];
    
    return [arguments componentsJoinedByString:@","];
}


#pragma mark - Cancelling:


-(void)cancelRequest:(MIJSONRequest *)request{
	
	[request cancel];
    MIJSONRequestManagerRequestObject *toCancel = nil;
    for (MIJSONRequestManagerRequestObject *ro in _requestsInProgress) {
        
        if (ro.request == request) {
            toCancel = ro;
            break;
        }
    }
    
    if (toCancel) {
        
        [_requestsInProgress removeObject:toCancel];
    }
    
    
}
-(void)cancelRequestsWithName:(NSString *)name{

    NSAssert(name != nil, @"Name must not be nil");
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    NSSet *toCancel = [_requestsInProgress filteredSetUsingPredicate:predicate];
    
    for (MIJSONRequestManagerRequestObject *ro in toCancel) {
    
        MIJSONRequest *request = ro.request;
        [request cancel];
        [_requestsInProgress removeObject:ro];
    }
    
    
}
-(void)cancelAllRequests{
	
	for (MIJSONRequestManagerRequestObject *ro in _requestsInProgress) {
		
        MIJSONRequest *request = ro.request;
        [request cancel];
	}
	
    [_requestsInProgress removeAllObjects];
}
-(void)cancelAllRequestsForClient:(id)client{

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"client = %@", client];
    NSSet *toCancel = [_requestsInProgress filteredSetUsingPredicate:predicate];
    
    for (MIJSONRequestManagerRequestObject *ro in toCancel) {
        
        MIJSONRequest *request = ro.request;
        [request cancel];
        [_requestsInProgress removeObject:ro];
    }
    
}
#pragma mark - Action Request delegate:

-(void)action:(MIJSONRequest *)request sentRequest:(NSDictionary *)requestDictionary toUrl:(NSURL *)url{

}

-(void)action:(MIJSONRequest *)request succededWithResponse:(NSDictionary *)response{
	
    [self removeRequest:request];
}
-(void)actionProgressed:(MIJSONRequest *)action{

    //TODO: Calculate average progress:
}
-(void)action:(MIJSONRequest *)request failedWithError:(NSError *)error{

    [self removeRequest:request];
}

-(void)removeRequest:(MIJSONRequest *)request{

    MIJSONRequestManagerRequestObject *toRemove = nil;
    for (MIJSONRequestManagerRequestObject *ro in _requestsInProgress) {
        
        if (ro.request == request) {
            toRemove = ro;
            break;
        }
    }
    
    if (toRemove) {
    
        [_requestsInProgress removeObject:toRemove];
    }
    
}

#pragma mark - Reachability:

- (void) checkNetworkStatus:(NSNotification *)notice{
	// called after network status changes
    
    hostStatus      = [_hostReachable currentReachabilityStatus];
    
        
        connected           = (hostStatus == NotReachable) ? NO : YES;
        connected_before    = (hs_before == NotReachable) ? NO : YES;
    
DLog(@"MIJSONRequestManager connection status changed from: %i to: %i\n\n", connected_before, connected);
    
    if (connected_before != connected || !status_known) {
        
        
        
        NSDictionary *ui = @{@"connected": @(connected),
                            @"before": @(connected_before), 
                            @"hostStatus": [NSNumber numberWithInt:hostStatus], 
                            @"hostStatusBefore": [NSNumber numberWithInt:hs_before]};
DLog(@"MIJSONRequestManager -> App connection status changed to: %i  hostStatus: %li", connected, (long)hostStatus);
        [[NSNotificationCenter defaultCenter] postNotificationName:kMIJSONRequestManagerConnectionToHostChangedNotification object:ui userInfo:ui];
    }
        

    status_known = YES;
    hs_before = hostStatus;
	    
}

@end

@implementation MIJSONRequestManagerRequestObject

+(instancetype)requestObjectWithRequest:(MIJSONRequest *)request
                                 client:(id)client{

    MIJSONRequestManagerRequestObject *ro = [[MIJSONRequestManagerRequestObject alloc] init];
    ro.request = request;
    ro.client = client;
    
    return ro;
}

@end
