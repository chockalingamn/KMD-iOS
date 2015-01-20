//
//  KMDReasonREST.m
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDReasonREST.h"
#import "KMD/User.h"


static NSString *const getAbsenceReasons =@"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/GetReasonTypes"; //?AbdTypeID=

@interface KMDReasonREST()
@property (nonatomic, strong) NSArray *reasons;
@end


@implementation KMDReasonREST

#pragma mark - class methods
#pragma mark public
+ (id)sharedInstance{
    static KMDReasonREST *reasonREST = nil;
    if (reasonREST) {
        return reasonREST;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reasonREST = [[KMDReasonREST alloc] initWithBaseURL:[User currentUser].hostname];
    });
    
    return reasonREST;
}


#pragma mark - instance Methods
- (void)fetchFromBackEnd{
    static NSDate *lastUpdated = nil;
    if (self.reasons && lastUpdated && [lastUpdated timeIntervalSinceNow] > -60*60) {
        [self.delegate reasonREST:self isUpToDate:self.reasons];
    }
    
    NSError *error;
    
    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"GET" path:getAbsenceReasons  parameters:nil error:&error];
    
    if (error) {
        [self.delegate reasonREST:self didFaileWithError:error];
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        return;
    }
    
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
            [self.delegate reasonREST:self didFaileWithError:connectionError];
        } else {
            NSError *error;
            if (data) {
                NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (error || ![result isKindOfClass:[NSArray class]]) {
                    NSLog(@"%s %@\n%@",__PRETTY_FUNCTION__,error.localizedDescription,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                } else {
                    self.reasons = [result copy];
                    [self.delegate reasonREST:self didUpdateWithReasons:result];
                    lastUpdated = [NSDate date];
                }
            }
        }
        
    }];
}

- (void)fetchFromBackEndForced{
    self.reasons = nil;
    [self fetchFromBackEnd];
}


@end
