//
//  MIJSONRequestManager.m
//  MobileFitness
//
//  Created by Lukasz Margielewski on 12/4/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MIJSONRequestManager.h"
#define kReachabilityChangedNotification @"kNetworkReachabilityChangedNotification"

@implementation MIJSONRequestManager{
    
    NSMutableSet *_requestsInProgress;

}
@synthesize connected = connected, connected_before;
@synthesize hostStatus;

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


#pragma mark - Designated initializer:

+(instancetype)requestManagerWithUrlString:(NSString *)urlString hostName:(NSString *)hostName{

    MIJSONRequestManager *rm = [[MIJSONRequestManager alloc] initWithUrlString:urlString hostName:hostName];
    return rm;
}
-(instancetype)initWithUrlString:(NSString *)urlString hostName:(NSString *)hostName{

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
    
    
    // Add default request parameters (if specified), f.x: login session, etc...
    if (self.requestParametersDefault && self.requestParametersDefault.allKeys.count) {
        
        NSMutableDictionary *ddd = [NSMutableDictionary dictionaryWithDictionary:self.requestParametersDefault];
        if (reqestDictionary) {
        
            [ddd addEntriesFromDictionary:reqestDictionary];
        }
        
        reqestDictionary = (NSDictionary *)ddd;
    }
    
    // Add default http headers (if specified), f.ex: login session or auth secrets, etc...
    if (self.httpHeadersDefault && self.httpHeadersDefault.allKeys.count) {
        
        NSMutableDictionary *ddd = [NSMutableDictionary dictionaryWithDictionary:self.httpHeadersDefault];
        if (httpHeaders) {
        
            [ddd addEntriesFromDictionary:httpHeaders];
        }
        
        httpHeaders = (NSDictionary *)ddd;
    }
    
    MIJSONRequest *jsonRequest = [MIJSONRequest requestWithUrl:self.webserviceUrl httpHeaders:httpHeaders httpMethod:httpMethod body:reqestDictionary delegate:self];
    
    jsonRequest.name = name;
    
        
        if (!_requestsInProgress) {
        
            _requestsInProgress = [[NSMutableSet alloc] init];
        }
    
    MIJSONRequestManagerRequestObject *ro = [MIJSONRequestManagerRequestObject requestObjectWithRequest:jsonRequest
                                                                                                 client:client];
    [_requestsInProgress addObject:ro];
    jsonRequest.startBlock = startBlock;
    jsonRequest.progressBlock = progressBlock;
    jsonRequest.completionBlock = completionBlock;
    
    jsonRequest.authDelegate = self.authDelegate;
    
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
