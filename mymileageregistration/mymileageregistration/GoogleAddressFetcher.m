#import "GoogleAddressFetcher.h"

#import "KMD/Errors.h"
#import "AFNetworking.h"
#import "KMD/NSString+URLEncode.h"


@implementation GoogleAddressFetcherAPIClient
{
    AFHTTPClient *_client;
    
    #define kBaseURL [NSURL URLWithString:@"http://maps.googleapis.com/"]
    #define kGeocodingAPIPath @"maps/api/geocode/json?sensor=true"
    #define kDistanceMatrixAPIPath @"maps/api/distancematrix/json?sensor=true"
}


- (id)init
{
    if (self = [super init])
    {
        _client = [[AFHTTPClient alloc] initWithBaseURL:kBaseURL];
    }
    
    return self;
}


- (void)fetchAddressWithLongitude:(NSString *) longitude AndLatitude: (NSString *) latitude success:(void (^)(NSString *address))successBlock failure:(void (^)(NSError *))failure 
{

    NSString* parameters = [NSString stringWithFormat:@"&latlng=%@,%@",latitude,longitude,nil];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",kBaseURL,kGeocodingAPIPath,parameters]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
        
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request 
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        NSString *address;
        NSArray *results = [JSON valueForKeyPath:@"results"];
        if ([results count] > 0)
            address = [[results objectAtIndex:0] valueForKeyPath:@"formatted_address"];

        if (successBlock) successBlock(address);
    }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        // Stop sending, we don't want to try to send anymore address request
        // before we have solved the issue.
        
        [_client cancelAllHTTPOperationsWithMethod:nil path:kGeocodingAPIPath];
        
        // Convay the error to the delegate.
        // TODO: We could use the common error handling here.
        
        NSError *clientError = [self createClientErrorFromResponse:response error:error jsonResponse:JSON];
        if (failure) failure(clientError);
    }];
    
    [_client enqueueHTTPRequestOperation:operation];
}


- (void)fetchDistanceWithOrigin:(NSString *) origin AndDestination: (NSString *) destination success:(void (^)(double distance))successBlock failure:(void (^)(NSError *))failureBlock 
{
    NSString *parameters = [NSString stringWithFormat:@"&origins=%@&destinations=%@",[NSString URLEncodeString:origin],[NSString URLEncodeString:destination],nil];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@%@",kBaseURL,kDistanceMatrixAPIPath,parameters,nil]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        double distance;
        NSError *error = [self distillEventualErrorsFromResponseBody:JSON AndOuterElementName:@"rows"];
        
        if (error)
        {
            if (failureBlock) failureBlock(error);
            return;
        }
        
        NSArray *rows = [JSON valueForKey:@"rows"];
        NSArray *elements = [[rows objectAtIndex:0] valueForKey:@"elements"];
        
        if (elements && [elements count] > 0) 
        {
            if ([[[elements objectAtIndex:0] valueForKeyPath:@"status"] isEqualToString:@"OK"]) 
            {
                distance = [[[elements objectAtIndex:0] valueForKeyPath:@"distance.value"] doubleValue];
                distance = round(distance / 1000);
            }
            else 
            {
                distance = 0;
                // TODO Google did like us. But returned an unsusccesfull answer
            }
        }
        else 
        {
            distance = 0;
             // TODO Google did like us. But they returned an unspecified and strange answer. Missing an "element"-element
        }
        
        if (successBlock) successBlock(distance);
    }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) 
    {
                                                                                    
        // Stop sending, we don't want to try to send anymore address request
        // before we have solved the issue.
                                                                                    
        [_client cancelAllHTTPOperationsWithMethod:nil path:kGeocodingAPIPath];
                                                                                    
        // Convay the error to the delegate.
                                                                                    
        NSError *clientError = [self createClientErrorFromResponse:response error:error jsonResponse:JSON];
        if (failureBlock) failureBlock(clientError);
    }];
    
    [_client enqueueHTTPRequestOperation:operation];
}


#define kGoogleAPITopLevelOK @"OK"
#define kGoogleAPITopLevelINVALID_REQUEST @"INVALID_REQUEST"
#define kGoogleAPITopLevelMAX_ELEMENTS_EXCEEDED @"MAX_ELEMENTS_EXCEEDED"
#define kGoogleAPITopLevelOVER_QUERY_LIMIT @"OVER_QUERY_LIMIT"
#define kGoogleAPITopLevelREQUEST_DENIED @"REQUEST_DENIED"
#define kGoogleAPITopLevelUNKNOWN_ERROR @"UNKNOWN_ERROR"

#define kGoogleAPIElementLevelOK @"OK"
#define kGoogleAPIElementLevelNOTFOUND @"NOT_FOUND"
#define kGoogleAPIElementLevelZERORESULTS @"ZERO_RESULTS"


- (NSError *)distillEventualErrorsFromResponseBody:(id)JSON AndOuterElementName:(NSString *)elementName
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

    NSString *statusCode = [JSON valueForKey:@"status"];
    
    NSString *errorReason;
    
    if ([kGoogleAPITopLevelOK isEqualToString:statusCode])
    {
        return nil;
    }
    else if ([kGoogleAPITopLevelINVALID_REQUEST isEqualToString:statusCode]) 
    {
        errorReason = @"Googles tjeneste kunne ikke forstå forespørgslen.";
    }
    else if ([kGoogleAPITopLevelMAX_ELEMENTS_EXCEEDED isEqualToString:statusCode]) 
    {
        errorReason = @"Googles tjeneste fandt for mange elementer i forespørgslen.";
    }
    else if ([kGoogleAPITopLevelOVER_QUERY_LIMIT isEqualToString:statusCode]) 
    {
        errorReason = @"Denne app har brugt Googles tjeneste mere end Google tillader.";
    }
    else if ([kGoogleAPITopLevelREQUEST_DENIED isEqualToString:statusCode]) 
    {
        errorReason = @"Google kunne ikke godkende brugen af deres tjeneste.";
    }
    else if ([kGoogleAPITopLevelUNKNOWN_ERROR isEqualToString:statusCode]) 
    {
        errorReason = @"Der skete en ukendt fejl hos Google.";
    }

    if (errorReason)
    {
        [userInfo setValue:errorReason forKey:NSLocalizedFailureReasonErrorKey]; 
        return [NSError errorWithDomain:@"KMD" code:GoogleAPIResponseServerFailure userInfo:userInfo];
    }
    
    NSArray *elements = [JSON valueForKeyPath:elementName];
    
    if (!elements && [elements count] <= 0) 
    {
        [userInfo setValue:@"Svaret fra Googles tjeneste er uforståeligt." forKey:NSLocalizedFailureReasonErrorKey]; 
        return [NSError errorWithDomain:@"KMD" code:GoogleAPIResponseValidationErrorCode userInfo:userInfo];
    }
        
    return nil;
}


- (NSError *) createClientErrorFromResponse:(NSHTTPURLResponse *)response error:(NSError *)error jsonResponse:(id)JSON
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    
    // Determine the type of error.
    
    // TODO: Account for BigIP errors.
    
    NSString *errorReason = @"Ukendt fejl.";
    NSInteger errorCode = GoogleAPIResponseOtherErrorCode;
    
    if (response.statusCode == 200)
    {
        // The request was fine but something went wrong when trying
        // to understand the response. Not much we can do but relay the error.
        
        errorReason = @"Ukendt fejl. Kan ikke forstå serverens svar.";
    }
    else if (response.statusCode == 500)
    {
        // An internal server error occured.
        
        errorReason = @"Der opstod en fejl hos serveren.";
        errorCode = GoogleAPIResponseServerFailure;
    }
    else if (response.statusCode == 400)
    {
        // The client has sent a bad request the reason for the error
        // should be in the response JSON.
        
        errorReason = (JSON) ? [JSON valueForKey:@"errorReason"] : @"Ukendt fejl. Kan ikke forstå svar fra serveren.";
        errorCode = GoogleAPIResponseValidationErrorCode;
    }
    else if (response.statusCode == 401)
    {
        // TODO: The client is unauthorized.
        errorCode = GoogleAPIResponseAuthenticationErrorCode;
    }
    else if (error) // TODO: Reachability problem.
    {
        if (error.code == 303)
        {
            errorReason = @"Serveren kan ikke nås fra din nuværende netværksforbindelse.";
            errorCode = GoogleAPIResponseNetworkFailure;
        }
        else if (error.code == -1009)
        {
            errorReason = @"Der er ikke adgang til internettet.";
            errorCode = GoogleAPIResponseNetworkFailure;
        }
    }
    
    // Log it if we don't know what is wrong.
    
    if (errorCode == GoogleAPIResponseOtherErrorCode)
    {
        NSLog(@"%@ %@", error, [error userInfo]);
    }
    
    [userInfo setValue:errorReason forKey:NSLocalizedFailureReasonErrorKey];
    [userInfo setValue:[error localizedDescription] forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"KMD" code:errorCode userInfo:userInfo];
}

@end
