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
@property (nonatomic, strong) NSMutableSet *activityObservers;
@end

@implementation MIJSONRequestManager{
    
    NSMutableSet *_requestsInProgress;
    
    unsigned long long _totalBytesToDownload;
    unsigned long long _totalDownloadedBytes;
    float              _totalProgress;
    
    NSUInteger iBefore;
}
@synthesize connected = connected, connected_before;
@synthesize hostStatus;
@synthesize loginSession = _loginSession;

-(void)dealloc{
	
	[self cancelAllRequests];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
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
                                 completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock{

    return [self startRequestWithJSONDictionary:reqestDictionary startBlock:nil progressBlock:nil completionBlock:completionBlock client:nil];
    
}
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
       // return nil;
    }
    
    MIJSONRequest *jsonRequest = [self requestWithJSONDictionary:reqestDictionary httpHeaders:httpHeaders httpMethod:httpMethod name:name];
    
    /*
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"request.name = %@", jsonRequest.name];
    NSSet *similarScheduled = [_requestsInProgress filteredSetUsingPredicate:predicate];
    
    if (similarScheduled && similarScheduled.count && jsonRequest.name) {
    
        MIJSONRequestManagerRequestObject *ro = [similarScheduled anyObject];
        if (ro) {
            
            NSLog(@"Similar request (name: %@) already scheduled already in progress: %@", name, ro.request.requestDictionary);
            return nil;
        }
    }
    
    */
    jsonRequest.startBlock      = startBlock;
    jsonRequest.progressBlock   = progressBlock;
    jsonRequest.completionBlock = completionBlock;
        
        if (!_requestsInProgress) {
        
            _requestsInProgress = [[NSMutableSet alloc] init];
        }
    
    MIJSONRequestManagerRequestObject *ro = [MIJSONRequestManagerRequestObject requestObjectWithRequest:jsonRequest
                                                                                                 client:client];
    
    iBefore = _requestsInProgress.count;
    [_requestsInProgress addObject:ro];
    
    [jsonRequest start];
    
    if (iBefore == 0) {
        //dispatch_async(dispatch_get_main_queue(), ^{
        
            [self resumed];
        //});
        
    }
    
    return jsonRequest;
}

-(MIJSONRequest *)requestWithJSONDictionary:(NSDictionary *)reqestDictionary
                                     httpHeaders:(NSDictionary *)httpHeaders
                                      httpMethod:(NSString *)httpMethod
                                            name:(NSString *)name{
    
    
    // Generate name:
    if (!name) {
        
        name = [self stringWithRequestDictionary:reqestDictionary];
        if (httpHeaders && httpHeaders != self.httpHeadersDefault) {
            NSString *nh = [self stringWithRequestDictionary:httpHeaders];
            name = [NSString stringWithFormat:@"%@_%@", nh, name];
        }
    }
    
    if(!httpMethod)httpMethod = self.httpMethodDefault;
    
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
    
    NSURL *url = self.webserviceUrl;
    
    if ([httpMethod isEqualToString:kMIJSONRequestManagerHttpMethodGET]) {
        
        finalRequestBody = nil;
        
        NSString *suffix = [self.urlEncoder encodeRequestDictionary:reqestDictionary];
        if (suffix) {
            url = [NSURL URLWithString:[[url absoluteString] stringByAppendingString:suffix]];
        }
    }

    
    MIJSONRequest *jsonRequest = nil;
    
    if ([[self.webserviceUrl absoluteString] hasPrefix:@"https:"] &&  self.authDelegate) {
        
        MIJSONRequestAuthenticate *jA = [MIJSONRequestAuthenticate requestWithUrl:url httpHeaders:finalHTTPHeaders httpMethod:httpMethod body:finalRequestBody delegate:self];
        jA.authDelegate    = self.authDelegate;
        jsonRequest = jA;
        
    }else{
        
        jsonRequest = [MIJSONRequest requestWithUrl:url httpHeaders:finalHTTPHeaders httpMethod:httpMethod body:finalRequestBody delegate:self];
        
    }
    jsonRequest.showProgress    = YES;
    jsonRequest.name            = name;

    return jsonRequest;
}

- (NSString *)stringWithRequestDictionary:(NSDictionary *)dictionary{
    
    NSMutableArray *arguments = [NSMutableArray arrayWithCapacity:[dictionary count]];
    
    [dictionary enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
        NSString *value = [object respondsToSelector:@selector(stringValue)] ? [object stringValue] : object;
        
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
    
    iBefore = _requestsInProgress.count;
    
    if (toCancel) {
        
        [_requestsInProgress removeObject:toCancel];
    }

    [self checkRequestsCount];

}
-(void)cancelRequestsWithName:(NSString *)name{

    NSAssert(name != nil, @"Name must not be nil");
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name = %@", name];
    NSSet *toCancel = [_requestsInProgress filteredSetUsingPredicate:predicate];
    
    iBefore = _requestsInProgress.count;
    
    for (MIJSONRequestManagerRequestObject *ro in toCancel) {
    
        MIJSONRequest *request = ro.request;
        [request cancel];
        [_requestsInProgress removeObject:ro];
    }
    
    
    [self checkRequestsCount];

    
}
-(void)cancelAllRequests{
	
	for (MIJSONRequestManagerRequestObject *ro in _requestsInProgress) {
		
        MIJSONRequest *request = ro.request;
        [request cancel];
	}
    
    iBefore = _requestsInProgress.count;
    [_requestsInProgress removeAllObjects];
    [self checkRequestsCount];
}
-(void)cancelAllRequestsForClient:(id)client{

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"client = %@", client];
    NSSet *toCancel = [_requestsInProgress filteredSetUsingPredicate:predicate];

    iBefore = _requestsInProgress.count;
    
    for (MIJSONRequestManagerRequestObject *ro in toCancel) {
        
        MIJSONRequest *request = ro.request;
        [request cancel];
        [_requestsInProgress removeObject:ro];
    }

    [self checkRequestsCount];

    
}
#pragma mark - Action Request delegate:

-(void)action:(MIJSONRequest *)request sentRequest:(NSDictionary *)requestDictionary toUrl:(NSURL *)url{

}

-(void)action:(MIJSONRequest *)request succededWithResponse:(NSDictionary *)response{
	
    [self removeRequest:request];
}
-(void)actionProgressed:(MIJSONRequest *)action{

    //TODO: Calculate average progress:
    [self updateTotalProgress];
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
    
    iBefore = _requestsInProgress.count;
    
    if (toRemove) {
    
        [_requestsInProgress removeObject:toRemove];
    }

    [self checkRequestsCount];
    
    
}

#pragma mark - Reachability:

- (void) checkNetworkStatus:(NSNotification *)notice{
	// called after network status changes
    
    hostStatus      = [_hostReachable currentReachabilityStatus];
    
        
        connected           = (hostStatus == NotReachable) ? NO : YES;
        connected_before    = (hs_before == NotReachable) ? NO : YES;
    
DMIJSONRLog(@"MIJSONRequestManager connection status changed from: %i to: %i\n\n", connected_before, connected);
    
    if (connected_before != connected || !status_known) {
        
        
        
        NSDictionary *ui = @{@"connected": @(connected),
                            @"before": @(connected_before), 
                            @"hostStatus": [NSNumber numberWithInt:hostStatus], 
                            @"hostStatusBefore": [NSNumber numberWithInt:hs_before]};
DMIJSONRLog(@"MIJSONRequestManager -> App connection status changed to: %i  hostStatus: %li", connected, (long)hostStatus);
        [[NSNotificationCenter defaultCenter] postNotificationName:kMIJSONRequestManagerConnectionToHostChangedNotification object:ui userInfo:ui];
        
        for (id<MIJSONRequestManagerActivityObserver>observer in _activityObservers) {
            
            if ([observer respondsToSelector:@selector(MIJSONRequestManager:connectionToHostChanged:)]) {
            
                [observer MIJSONRequestManager:self connectionToHostChanged:connected];
            }
            
        }
    }
        

    status_known = YES;
    hs_before = hostStatus;
	    
}



#pragma mark - Activity observers:

-(void)checkRequestsCount{

    NSUInteger iAfter = _requestsInProgress.count;
    
    if (iBefore > 0 && iAfter == 0) {
        //dispatch_async(dispatch_get_main_queue(), ^{
        
            [self finishedAll];
        //});
        
    }
}
-(void)resumed{

    _totalBytesToDownload = _totalDownloadedBytes = 0;
    
    for (id<MIJSONRequestManagerActivityObserver>observer in _activityObservers) {
        
        if ([observer respondsToSelector:@selector(MIJSONRequestManagerDidResumeRequests:)]) {
        
            [observer MIJSONRequestManagerDidResumeRequests:self];
        }
        
    }
    
}
-(void)updateTotalProgress{

    _totalBytesToDownload = _totalDownloadedBytes = 0;
    for (MIJSONRequestManagerRequestObject *ro in _requestsInProgress) {
        
        MIJSONRequest *request = ro.request;
        _totalBytesToDownload += request.expectedResponseSize;
        _totalDownloadedBytes += request.downloadedBytes;
    }
    _totalProgress = _totalBytesToDownload ? (double)_totalDownloadedBytes / (double)_totalBytesToDownload : 0;
    
    for (id<MIJSONRequestManagerActivityObserver>observer in _activityObservers) {
        
        if([observer respondsToSelector:@selector(MIJSONRequestManager:didUpdateTotalProgress:downloadedBytes:totalBytesToDownload:requestsCount:)]){
        
            [observer MIJSONRequestManager:self didUpdateTotalProgress:_totalProgress downloadedBytes:_totalDownloadedBytes totalBytesToDownload:_totalBytesToDownload requestsCount:_requestsInProgress.count];
        }
        
    }
}
-(void)finishedAll{
    
    for (id<MIJSONRequestManagerActivityObserver>observer in _activityObservers) {
        
        if ([observer respondsToSelector:@selector(MIJSONRequestManagerDidFinishAllRequests:downloadedBytes:)]) {
        
            [observer MIJSONRequestManagerDidFinishAllRequests:self downloadedBytes:_totalBytesToDownload];
        }
        
    }
}

-(NSMutableSet *)activityObservers{

    if (!_activityObservers) {
        _activityObservers = [[NSMutableSet alloc] initWithCapacity:5];
    }
    return _activityObservers;
}
-(void)addActivityObserver:(id<MIJSONRequestManagerActivityObserver>)activityObserver{

    [self.activityObservers addObject:activityObserver];
}
-(void)removeActivityObserver:(id<MIJSONRequestManagerActivityObserver>)activityObserver{

    [self.activityObservers removeObject:activityObserver];
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
