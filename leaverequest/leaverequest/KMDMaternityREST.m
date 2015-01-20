//
//  KMDMaternityREST.m
//  leaverequest
//
//  Created by Per Friis on 12/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDMaternityREST.h"
#import "KMD/User.h"

static NSString *const getMaternityList = @"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/GetMaternityList";


@interface KMDMaternityREST ()
@property (nonatomic, strong) NSArray *maternity;
@end

@implementation KMDMaternityREST


#pragma mark - class methods
#pragma mark public

+ (id)sharedInstance{
    static KMDMaternityREST * MaternityREST = nil;
    if (MaternityREST) {
        return MaternityREST;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MaternityREST = [[KMDMaternityREST alloc] initWithBaseURL:[User currentUser].hostname];
    });
    
    return MaternityREST;
}


- (void)fetchFromBackEnd{
    static NSDate *lastUpdated = nil;
    if (self.maternity && lastUpdated && [lastUpdated timeIntervalSinceNow] > -60*60) {
        [self.delegate MaternityREST:self isUpToDate:self.maternity];
    }
    
    NSError *error;
    
    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"POST" path:getMaternityList  parameters:nil error:&error];
    
    if (error) {
        [self.delegate MaternityREST:self didFaileWithError:error];
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
                [self.delegate MaternityREST:self didFaileWithError:connectionError];
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
                    
                        [self.delegate MaternityREST:self didFaileWithError:error];
                } else {
                    self.maternity = [result copy];
                        [self.delegate MaternityREST:self didUpdateWithMaternity:self.maternity];
                    lastUpdated = [NSDate date];
                }
            }
        }
        
    }];
}

- (void)fetchFromBackEndForced{
    self.maternity = nil;
    [self fetchFromBackEnd];
}


@end
