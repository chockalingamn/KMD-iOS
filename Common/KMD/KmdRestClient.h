
@class AFHTTPClient, AFJSONRequestOperation, AFImageRequestOperation;

@interface KmdRestClient : NSObject

@property (nonatomic, readonly) AFHTTPClient *httpClient;

- (id)initWithBaseURL:(NSURL *)baseURL;

-(NSMutableURLRequest*)kmdRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters error:(NSError**) error;

-(void)updateLocalSession;

@end
