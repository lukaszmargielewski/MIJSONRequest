#import "MIJSONRequest.h"

@implementation MIJSONRequest{

    NSTimer *_cancelTimer;
    NSTimeInterval startTime, sendTime, firstResponseTime, downloadStartTime, totalTime, downloadEndTime, timeoutInSeconds, totalResponseTime, totalDownloadTime, responseParseTimeEnd;

    
}

@synthesize connection = _connection;
@synthesize synchronyous = _synchronyous;
@synthesize progress = _progress;
@synthesize downloadedBytes = _downloadedBytes;
@synthesize responseRawData = _responseRawData;

#pragma mark

- (void)dealloc{
    
//DLog(@"AR dealloc: %@", self.actionName);

    //DLog(@"dealloc connection for action:%@", self.actionName);
	[self cancel];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_cancelTimer) {
        [_cancelTimer invalidate];
        _cancelTimer = nil;  
    }
    
}

+(dispatch_queue_t)queue{
    
    
    static dispatch_once_t pred;
    static dispatch_queue_t queue = NULL;
    
    dispatch_once(&pred, ^{
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *bid = infoDict[@"CFBundleIdentifier"];
        
        NSString *label = [NSString stringWithFormat:@"%@.MIJSONRequest", bid];
        NSUInteger maxBufferCount = sizeof(char) * (label.length + 1);
        
        char *label_char = (char *)malloc(maxBufferCount); // +1 for NULL termination
        
        BOOL ok = [label getCString:label_char maxLength:maxBufferCount encoding:NSUTF8StringEncoding];
        NSAssert(ok, @"Something wrong with ActionRequest queue label c string generation");
        
        queue = dispatch_queue_create(label_char, DISPATCH_QUEUE_SERIAL);
        
        free(label_char);
    });
    
    return queue;
}
-(void)addParameters:(NSDictionary *)parameters{
	
    if (parameters && [parameters allKeys].count) {
    
        [self.requestDictionary addEntriesFromDictionary:parameters];
    }
	
}

#pragma mark - init:

/*
-(id)init{
    
    NSAssert(NO, @"Direct init not allowed, use initWithUrl:... instead.");
    return nil;
}
*/

+(instancetype)requestWithUrl:(NSURL *)url httpHeaders:(NSDictionary *)httpHeaders httpMethod:(NSString *)httpMethod body:(NSDictionary *)requestDictionary delegate:(id<MIJSONRequestDelegate>)delegate{
	
	MIJSONRequest *a = [[MIJSONRequest alloc] initWithUrl:url httpHeaders:httpHeaders httpMethod:httpMethod body:requestDictionary delegate:delegate];
	return a;
}

-(instancetype)initWithUrl:(NSURL *)url httpHeaders:(NSDictionary *)httpHeaders httpMethod:(NSString *)httpMethod body:(NSDictionary *)requestDictionary delegate:(id<MIJSONRequestDelegate>)delegate{

    self = [super init];
    
    if (self) {
        _delegate = delegate;
        _httpHeaders        = [NSMutableDictionary dictionaryWithDictionary:httpHeaders];
        _requestDictionary  = [NSMutableDictionary dictionaryWithDictionary:requestDictionary];
        _httpMethod         = (httpMethod) ? httpMethod : @"GET";
        _url = url;

        _downloading = NO;
        startTime = sendTime = firstResponseTime = downloadStartTime = totalTime = downloadEndTime = 0;
        _showProgress = YES;
        timeoutInSeconds = 20;
    }
    
    return self;

}

#pragma mark - Public API:

- (void)start{
	
    dispatch_async([MIJSONRequest queue], ^{
    
        NSURLRequest *request = [self request];
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            _synchronyous = NO;
    
            _connection             = [NSURLConnection connectionWithRequest:request delegate:self];
            sendTime                = [[NSDate date] timeIntervalSince1970];
            
            if (_connection) {
            
                _responseRawData    = [NSMutableData data];
                [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
                _downloading = YES;
                startTime = [[NSDate date] timeIntervalSince1970];
                
            }else{
                
                [self connection:nil didFailWithError:[NSError errorWithDomain:@"NSURLCnnection failed to init" code:999 userInfo:nil]];
            }
        
        });

    });
	
}
-(NSURLRequest *)request{

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.url];
    [request setHTTPMethod:self.httpMethod];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:self.requestDictionary options:0 error:nil];
    [request setHTTPBody:data];
    [request setTimeoutInterval:timeoutInSeconds];
    
    return request;
}

- (NSDictionary *)synchronyousRequest{
    
    NSURLRequest *request = [self request];
    
    _synchronyous = YES;
    _downloading = YES;
    sendTime = [[NSDate date] timeIntervalSince1970];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
		//////////
		NSHTTPURLResponse *aResponse = NULL;
		NSError *error = nil;
		_responseRawData  = (NSMutableData *)[NSURLConnection sendSynchronousRequest:request returningResponse:&aResponse error:&error];
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (_responseRawData && !error) {
        
        NSError *jsonError = nil;
		_jsonResponse = [NSJSONSerialization JSONObjectWithData:_responseRawData options:0 error:&jsonError];
        
        if (jsonError) {
            //DLog(@"ActionRequest: %@ JSON Error in sync request: %@", self.actionName, jsonError);
        }
        
        _downloading = NO;

		return self.jsonResponse;
    }
	
	return nil;
}

- (void)cancel{
	
    [_cancelTimer invalidate];
    _cancelTimer = nil;
    
    //DLog(@"Cancelling connection for action:%@", self.actionName);
    [_connection cancel];
    
    _connection = nil;
    _responseRawData = nil;
    _jsonResponse = nil;
	_downloading = NO;
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (_completionBlock) {
        __block MIJSONRequest *rrr = self;
            
        _completionBlock(rrr, MIJSONRequestResultCancelled, nil, nil);
        _completionBlock = nil;
    }
    
}

#pragma mark - Download support (NSURLConnectionDelegate):

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
	
    downloadStartTime = firstResponseTime = [[NSDate date] timeIntervalSince1970];
    totalResponseTime = firstResponseTime - sendTime;
    
    
    NSHTTPURLResponse *HTTPResponse = (NSHTTPURLResponse *)response;
    NSDictionary *fields = [HTTPResponse allHeaderFields];

    _expectedResponseSize = [response expectedContentLength];
    if (_expectedResponseSize <= 0) {
    
//DLog(@"%@ -> Tryng to get response expected lenght from headers: %@", self.actionName, fields);
        _expectedResponseSize = [[fields valueForKey:@"Content-Length-Unzipped"] longLongValue];
    }
    
    

    NSString *senc = [fields valueForKey:@"Content-Encoding"];
    _responseZipped  = (senc && [senc isEqualToString:@"gzip"]);

    //if ([self.actionName isEqualToString:@"bulk"])
        //DLog(@"%@ Connection didReceiveResponse with gzip: %i expected size: %lli", self.actionName, isResponseGzipped, expectedResponseSize);
    
    _downloadedBytes = 0;
    
    if (_cancelTimer) {
        [_cancelTimer invalidate];
        _cancelTimer = nil;  
    }
    
    _showProgress = (_showProgress && _expectedResponseSize > 50000);
    _downloading = YES;
    
    if(_startBlock){
    
        __block MIJSONRequest *rrr = self;
        _startBlock(rrr, YES);
    }
    
    if (_delegate && [_delegate respondsToSelector:@selector(action:sentRequest:toUrl:)]) {
    
        [_delegate action:self sentRequest:self.requestDictionary toUrl:self.url];
    }
    
    if(_progressBlock){
        
        __block MIJSONRequest *rrr = self;
        _progressBlock(rrr, 0);
    }
    
    if (_showProgress){
     
        if(_delegate && [_delegate respondsToSelector:@selector(actionProgressed:)]) {
            [_delegate actionProgressed:self];
        }
    }
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
	//
    
    if (_downloadedBytes == 0) {
        
        
    }
    [_responseRawData appendData:data];
    _downloadedBytes = [_responseRawData length];
    
    if (_expectedResponseSize > 0) {

        _progress = (float)_downloadedBytes / (float)_expectedResponseSize;

        if(_progressBlock){
            
            __block MIJSONRequest *rrr = self;
            _progressBlock(rrr, _progress);
        }
        
        if (_showProgress){

            if(_delegate && [_delegate respondsToSelector:@selector(actionProgressed:)]) {
                [_delegate actionProgressed:self];
            }
        }

    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    
    if (_cancelTimer) {
        [_cancelTimer invalidate];
        _cancelTimer = nil;  
    }
    
    _jsonResponse = nil;
    _responseRawData = nil;
    _connection = nil;
	_downloading = NO;
	
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    if (_completionBlock) {
        __block MIJSONRequest *rrr = self;
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            _completionBlock(rrr, MIJSONRequestResultFailed, nil, error);
            _completionBlock = nil;
        });
        
    }
    
    if(_delegate && [_delegate respondsToSelector:@selector(action:failedWithError:)]){
        [_delegate action:self failedWithError:error];
    }
	
}
- (void)logTimes{

   //DLog(@"=== Action %@ timing logs: === start =", self.actionName);
   //DLog(@"Request: %@", self.requestDictionary);
   //DLog(@"Response size: %lli (in bytes)", responseSize);
   //DLog(@"Total time:                 %.4fsec", totalTime);
   //DLog(@"Request generation time:    %.4fsec (local cost of generating JSON string)", totalRequestgenerationTime);
   //DLog(@"Response time:              %.4fsec (server lag: time between sent request and 1st server response - data will start downlaoding)", totalResponseTime);
   //DLog(@"Download time (pure):       %.4fsec (measured from 1st response time to the moment when last bytes arrive)", totalDownloadTime);
   //DLog(@"Response parse:             %.4fsec (JSON respone parsing)", totalResponseParseTime);
   //DLog(@"Summary | download speed:   %.3f bytes per second (only transfer itself)", ((float)responseSize / totalDownloadTime));
   //DLog(@"Summary | total speed:      %.3f bytes per second (includes all: 1. download,  2. server response lag, 3. costs of local JSON processing - requset and response)", ((float)responseSize / totalTime));
    
   //DLog(@"=== Action %@ timing logs: ===  end  =", self.actionName);
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    
    if (_cancelTimer) {
        [_cancelTimer invalidate];
        _cancelTimer = nil;  
    }
    
    downloadEndTime = [[NSDate date] timeIntervalSince1970];
    totalDownloadTime = downloadEndTime - downloadStartTime;
    _responseSize = [_responseRawData length];
    
	[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
   // Tell delegate theat data has been downloaded:
    
    dispatch_async([MIJSONRequest queue], ^{
    
        // Parsing in background queue:
        NSError *jsonError = NULL;
        _jsonResponse = (NSDictionary*)[NSJSONSerialization JSONObjectWithData:_responseRawData options:0 error:&jsonError];
        
        dispatch_async(dispatch_get_main_queue(), ^{
        
            responseParseTimeEnd = [[NSDate date] timeIntervalSince1970];
            totalTime = responseParseTimeEnd - startTime;
                
                // Inform delegate that response has been received
            
            if (_completionBlock) {
                
                __block MIJSONRequest *rrr = self;
                _completionBlock(rrr, MIJSONRequestResultSuccess, _jsonResponse, jsonError);
                _completionBlock = nil;
            }
            
            
            if(_delegate){
                    [_delegate action:self succededWithResponse:_jsonResponse];
                }
            
            _connection = nil;
            _downloading = NO;
            
        });
    });
        
}


#pragma mark - Authentication:


- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace{
    
    if (_authDelegate && [_authDelegate respondsToSelector:@selector(action:connection:canAuthenticateAgainstProtectionSpace:)]) {
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

