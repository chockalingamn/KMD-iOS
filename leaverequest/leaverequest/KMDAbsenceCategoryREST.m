//
//  KMDAbsenceCategoryREST.m
//  leaverequest
//
//  Created by Per Friis on 15/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDAbsenceCategoryREST.h"
#import "KMD/User.h"

static NSString *const getAbsenceTypes =@"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/GetAbsenceTypes?GetFullList=x";

@interface KMDAbsenceCategoryREST()
@end

@implementation KMDAbsenceCategoryREST

#pragma mark - Class Methods
#pragma mark public
+ (id)sharedInstance{
    static KMDAbsenceCategoryREST *categoryRest = nil;
    if (categoryRest) {
        return categoryRest;
    }
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        categoryRest = [[KMDAbsenceCategoryREST alloc]init];
    });
    
    
    return categoryRest;
}

#pragma mark - instance method

- init{
    self = [super initWithBaseURL:[User currentUser].hostname];
    if (self) {
        
    }
    
    return self;
}

- (void)fetchFromBackEnd{
    if (self.categories) {
        [self.delegate absenceCategory:self didUpdateWithData:self.categories];
    }
    
    NSError *error;
    
    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"GET" path:getAbsenceTypes  parameters:nil error:&error];
    
    if (error) {
        [self.delegate absenceCategory:self didFailWithError:[error copy]];
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        return;
    }
    
 //   [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    
    

    
    
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
            
            [self.delegate absenceCategory:self didFailWithError:connectionError];
        } else {
            NSError *error;
            if (data) {
                NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (error || ![result isKindOfClass:[NSArray class]]) {
                    NSLog(@"%s %@\n%@",__PRETTY_FUNCTION__,error.localizedDescription,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                } else {
                    self.categories = [result copy];
                        [self.delegate absenceCategory:self didUpdateWithData:result];
                }
            }
        }
    }];
}

- (void)fetchFromBackEndForced{
// the current version don't cache any data....
    [self fetchFromBackEnd];
}


@end
