//
//  KMDWorkInjuryREST.m
//  leaverequest
//
//  Created by Per Friis on 12/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDWorkInjuryREST.h"
#import "KMD/User.h"

static NSString *const getWorkInjuries = @"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/GetWorkInjuryList";


@interface KMDWorkInjuryREST ()
@property (nonatomic, strong) NSArray *workInjuries;
@end

@implementation KMDWorkInjuryREST

#pragma mark - class methods
#pragma mark public

+ (id)sharedInstance{
    static KMDWorkInjuryREST * workInjuryREST = nil;
    if (workInjuryREST) {
        return workInjuryREST;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        workInjuryREST = [[KMDWorkInjuryREST alloc] initWithBaseURL:[User currentUser].hostname];
    });
    
    return workInjuryREST;
}


- (void)fetchFromBackEnd{
    static NSDate *lastUpdated = nil;
    if (self.workInjuries && lastUpdated && [lastUpdated timeIntervalSinceNow] > -60*60) {
        [self.delegate workInjuryREST:self isUpToDate:self.workInjuries];
    }
    
    NSError *error;
    
    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"POST" path:getWorkInjuries  parameters:nil error:&error];
    
    if (error) {
        [self.delegate workInjuryREST:self didFaileWithError:error];
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        return;
    }
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
  //  NSString *dateString = [dateFormatter stringFromDate:self.appDelegate.fetchFromDate];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"StartDate":@"" ,@"EmployeeID":@""} options:0 error:nil]];

    
    
    

    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
                [self.delegate workInjuryREST:self didFaileWithError:connectionError];
        } else {
            NSError *error;
            if (data) {
                NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (error || ![result isKindOfClass:[NSArray class]]) {
                    NSLog(@"%s %@\n%@",__PRETTY_FUNCTION__,error.localizedDescription,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                    
                    // try to give some sensible error code
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                    if (httpResponse.statusCode == 400 && !error) {
                        NSDictionary *errorDescription = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                        if (errorDescription) {
                            error = [NSError errorWithDomain:@"KMD Opus" code:400 userInfo:errorDescription];
                        }
                    }
                    
                        [self.delegate workInjuryREST:self didFaileWithError:error];
                } else {
                    self.workInjuries = [result copy];
                        [self.delegate workInjuryREST:self didUpdateWithWorkInjuries:self.workInjuries];
                    lastUpdated = [NSDate date];
                }
            }
        }
        
    }];
}

- (void)fetchFromBackEndForced{
    self.workInjuries = nil;
    [self fetchFromBackEnd];
}

@end
