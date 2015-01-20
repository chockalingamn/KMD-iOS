#import <UIKit/UIKit.h>

#import "AFNetworking.h"

#import "KMD/KMDLoginViewController.h"
#import "KMD/Errors.h"
#import "KMD/Dates.h"
#import "KMD/User.h"

#import "RegistrationRestClient.h"
#import "TripDistanceUtil.h"

#define kRegistrationsPath @"KMD.LPE.Mobile.MileageRegistration/MyMileageRegistration/ReportMileage"

@implementation RegistrationRestClient

- (id)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super initWithBaseURL:baseURL])
    {
        // Initialize fields here
    }
    return self;
}

- (void)sendRegistrations:(NSArray *)registrations done:(void (^)(NSArray *, NSArray *))doneBlock
{
    NSMutableArray *errors = [NSMutableArray array];
    NSMutableArray *sentRegistrations = [NSMutableArray array];
    NSMutableArray *unhandledRegistrations = [NSMutableArray arrayWithArray:registrations];

    if ([unhandledRegistrations count] == 0)
        if (doneBlock) doneBlock(sentRegistrations, errors);
    
    // Define general operation for handling sent registrations
    void (^handleRegistrationFinished)(Registration *, NSError *) = ^(Registration *registration, NSError *error) {
        @synchronized(unhandledRegistrations)
        {
            [unhandledRegistrations removeObject:registration];
            if (error) [errors addObject:error];
            if (!error) [sentRegistrations addObject:registration];
            if ([unhandledRegistrations count] == 0) {
                // OK to execute doneBlock in sync block, since this must be the last job
                if (doneBlock) doneBlock(sentRegistrations, errors);
            }
        }
    };

    for (Registration *registration in registrations) {
        [self sendRegistration:registration success:^
        {
            handleRegistrationFinished(registration, nil);
        }
        failure:^(NSError *error)
        {
            handleRegistrationFinished(registration, error);
        }];
    }
}

- (void)sendRegistration:(Registration *)registration success:(void (^)(void))successBlock failure:(void (^)(NSError *))failureBlock
{
    NSError *error;
    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"POST" path:kRegistrationsPath parameters:nil error:&error];
    if (error) {
        if (failureBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{ failureBlock(error); });
        }
        return;
    }
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    [request setHTTPBody:[self serializeRegistrationToJSON:registration]];
    
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        [self updateLocalSession];
        if (successBlock) successBlock();
    }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
    {
        NSLog(@"%@ %@ JSON: %@", error, [error userInfo], JSON);
        
        error = [Errors errorFromResponse:response connectionError:error json:JSON];
        
        if (failureBlock) failureBlock(error);
    }];

    [self.httpClient enqueueHTTPRequestOperation:operation];
}


#pragma mark - JSON Helpers


- (NSData *)serializeRegistrationToJSON:(Registration *)registration
{
//    NSMutableDictionary *json = [NSMutableDictionary dictionary];
//    
//    NSString *date = [Dates RFC3339DateTimeStringFromDate:registration.tripDate];
//    NSString *tripDistance = [TripDistanceUtil formatDecimalNumberWithDot:registration.tripDistanceInKilometers];
//    
//    [json setValue:registration.origin forKey:KMDTripRegistrationFieldStartAddress];
//    [json setValue:registration.destination forKey:KMDTripRegistrationFieldEndAddress];
//    [json setValue:date forKey:KMDTripRegistrationFieldDate];
//    [json setValue:tripDistance forKey:KMDTripRegistrationFieldDistance];
//    [json setValue:registration.vehicleRegistrationNumber forKey:KMDTripRegistrationFieldVehicleRegistrationNumber];
//    [json setValue:registration.templateID forKey:KMDTripRegistrationFieldTemplateID];
//    [json setValue:registration.reason forKey:KMDTripRegistrationFieldReason];
//    
//    NSLog(@"%@", json);
//    
//    // The generation of a request should never go wrong. The server might
//    // complain that something is missing, but the JSON should be valid.
//    
//    NSError *error;
//    NSData *data = [NSJSONSerialization dataWithJSONObject:json options:0 error:&error];
//    
//    if (error) [Errors fatalError:error];
//    
//    return data;
    return nil;
}

@end

