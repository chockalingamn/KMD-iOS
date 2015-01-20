//
//  KMDChildrenREST.m
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDChildrenREST.h"
#import "KMD/User.h"

static NSString *const getChildren =@"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/GetChildren";

@interface KMDChildrenREST()
@property (nonatomic, strong) NSArray *children;
@end

@implementation KMDChildrenREST

+ (id)sharedInstance{
    static KMDChildrenREST *childrenREST = nil;
    if (childrenREST) {
        return childrenREST;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        childrenREST = [[KMDChildrenREST alloc] initWithBaseURL:[User currentUser].hostname];
    });
    
    return childrenREST;
}

- (void)fetchFromBackEnd{
    static NSDate *lastUpdated = nil;
    if (self.children && lastUpdated && [lastUpdated timeIntervalSinceNow] > -60*60) {
        [self.delegate childrenREST:self isUpToDate:self.children];
    }
    
    NSError *error;
    
    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"GET" path:getChildren  parameters:nil error:&error];
    
    if (error) {
        [self.delegate childrenREST:self didFaileWithError:error];
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        return;
    }
    
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    

    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
                [self.delegate childrenREST:self didFaileWithError:connectionError];
        } else {
            NSError *error;
            if (data) {
                NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (error || ![result isKindOfClass:[NSArray class]]) {
                    NSLog(@"%s %@\n%@",__PRETTY_FUNCTION__,error.localizedDescription,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                        [self.delegate childrenREST:self didFaileWithError:error];
                } else {
                    self.children = [result copy];
                        [self.delegate childrenREST:self didUpdateWithChildren:result];
                    lastUpdated = [NSDate date];
                }
            }
        }
        
    }];
}

- (void)fetchFromBackEndForced{
    self.children = nil;
    [self fetchFromBackEnd];
}



- (NSString *)childNameForID:(NSString *)childID{
    NSPredicate *idPre= [NSPredicate predicateWithFormat:@"ID = %@",childID];
    NSArray *result = [self.children filteredArrayUsingPredicate:idPre];
    NSDictionary *c = result.firstObject;
    if (c) {
        return [NSString stringWithFormat:@"%@ %@",c[@"FirstName"],c[@"LastName"]];
    }
    return nil;
}

@end
