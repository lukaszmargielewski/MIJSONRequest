#import <UIKit/UIKit.h>

#ifdef DEBUG
#define DLog NSLog
#else
#define DLog while(0){}
#endif

typedef NS_ENUM(NSInteger, MIJSONRequestResult){
    
    MIJSONRequestResultFailed = 0,
    MIJSONRequestResultSuccess,
    MIJSONRequestResultCancelled,
};

@class MIJSONRequest;

typedef void(^MIJSONRequestManagerRequestStartBlock)(MIJSONRequest *action, BOOL started);
typedef void(^MIJSONRequestManagerRequestProgressBlock)(MIJSONRequest *action, float progress);
typedef void(^MIJSONRequestManagerRequestCompletionBlock)(MIJSONRequest *action, enum MIJSONRequestResult result, NSDictionary *response, NSError *error);
// Use: completionBlock:(MIJSONRequestManagerRequestCompletionBlock)completionBlock;

@protocol MIJSONRequestDelegate;


@interface MIJSONRequest : NSObject<NSURLConnectionDelegate>
{

	
}
@property (nonatomic, strong) NSString *name;

@property (nonatomic, assign) id <MIJSONRequestDelegate> delegate;

@property (nonatomic, strong, readonly) NSURL *url;
@property (nonatomic, strong) NSString *httpMethod;
@property (nonatomic, strong) NSMutableDictionary *requestDictionary;
@property (nonatomic, strong) NSMutableDictionary *httpHeaders;

@property (nonatomic, strong, readonly) NSMutableData *responseRawData;
@property (nonatomic, strong, readonly) id jsonResponse;

@property (nonatomic, strong) id identifierObject;
@property (nonatomic, strong, readonly) NSURLConnection *connection;

@property (nonatomic) BOOL showProgress;
@property (nonatomic, readonly) float progress;

@property (nonatomic, readonly)  long long expectedResponseSize, responseSize, downloadedBytes;

@property (nonatomic, readonly, getter=isDownloading) BOOL downloading;
@property (nonatomic, readonly, getter=isSynchronyous) BOOL synchronyous;
@property (nonatomic, readonly, getter=isResponseGzipped) BOOL responseZipped;

@property (nonatomic, strong) MIJSONRequestManagerRequestStartBlock startBlock;
@property (nonatomic, strong) MIJSONRequestManagerRequestProgressBlock progressBlock;
@property (nonatomic, strong) MIJSONRequestManagerRequestCompletionBlock completionBlock;

+(instancetype)requestWithUrl:(NSURL *)url httpHeaders:(NSDictionary *)httpHeaders httpMethod:(NSString *)httpMethod body:(NSDictionary *)requestDictionary delegate:(id<MIJSONRequestDelegate>)delegate;

-(instancetype)initWithUrl:(NSURL *)url httpHeaders:(NSDictionary *)httpHeaders httpMethod:(NSString *)httpMethod body:(NSDictionary *)requestDictionary delegate:(id<MIJSONRequestDelegate>)delegate NS_DESIGNATED_INITIALIZER;


-(void)addParameters:(NSDictionary *)parameters;

- (void)start;
- (void)cancel;
- (NSDictionary *)synchronyousRequest;

@end

#pragma mark - Delegate Protocol:

@protocol MIJSONRequestDelegate <NSObject>

-(void)action:(MIJSONRequest *)action succededWithResponse:(NSDictionary *)response;
@optional
-(void)action:(MIJSONRequest *)action sentRequest:(NSDictionary *)request toUrl:(NSURL *)url;
-(void)action:(MIJSONRequest *)action failedWithError:(NSError *)error;

@optional
-(void)actionProgressed:(MIJSONRequest *)action;
@end
