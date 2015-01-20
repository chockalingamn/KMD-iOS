#import "AFNetworking.h"

#import "KmdRestClient.h"
#import "User.h"
#import "Errors.h"

@implementation KmdRestClient

@synthesize httpClient = _httpClient;

- (id)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super init])
    {
        _httpClient = [[AFHTTPClient alloc] initWithBaseURL:baseURL];
    }
    return self;
}

-(NSMutableURLRequest*)kmdRequestWithMethod:(NSString *)method path:(NSString *)path parameters:(NSDictionary *)parameters error:(NSError**) error
{
    if (![self isLocalSessionValid]) {
        *error = [Errors errorWithReason:@"Sessionen timede ud." errorCode:KMDLocalSessionTimeoutErrorCode];
        return nil;
    }

    NSMutableURLRequest *request = [_httpClient requestWithMethod:method path:path parameters:parameters];
    [request setValue:User.currentUser.username forHTTPHeaderField:@"UserName"];
    [request setValue:User.currentUser.pin forHTTPHeaderField:@"Pincode"];
    [request setValue:User.currentUser.authenticationToken forHTTPHeaderField:@"Ticket"];
    
    NSLog(@"Sending request with URL: %@", [request URL]);
    NSLog(@"UserName: %@", [[request allHTTPHeaderFields] objectForKey:@"UserName"]);
    #ifdef DEBUG
    NSLog(@"Ticket: %@", [[request allHTTPHeaderFields] objectForKey:@"Ticket"]);
    NSLog(@"Pincode: %@", [[request allHTTPHeaderFields] objectForKey:@"Pincode"]);

    if (request.HTTPBody) {
    NSLog(@"%s %@",__PRETTY_FUNCTION__,[[NSString alloc ] initWithData:request.HTTPBody encoding:NSUTF8StringEncoding]);
    }
    #endif

    return request;
}

-(void)updateLocalSession
{
    User.currentUser.lastRequestToServer = [NSDate date];
}

-(BOOL)isLocalSessionValid
{
    NSDate *localSessionEnd = [User.currentUser.lastRequestToServer dateByAddingTimeInterval:KMDLocalSessionTimeoutInterval];
    NSDate *now = [NSDate date];
    return ([localSessionEnd timeIntervalSinceDate:now]>0);
}

@end
