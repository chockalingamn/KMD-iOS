//
//  leaverequestRestClient.m
//  leaverequest
//
//  Created by Per Friis on 08/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

static NSString *const postAbsenceList =@"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/GetAbsenceList";

#import "DejalActivityView.h"
#import "KMD/User.h"
#import "Absence+KMD.h"

#import "AbsenceREST.h"
@interface AbsenceREST()
@property (nonatomic, readonly) KMDAppDelegate *appDelegate;
@end


@implementation AbsenceREST
- (KMDAppDelegate *)appDelegate{
    return [[UIApplication sharedApplication] delegate];
}



+ (void)fetchAbsenceWithDelegate:(id<AbsenceRESTDelegate>)delegate{
    AbsenceREST *absenceRest = [[AbsenceREST alloc] initWithBaseURL:[User currentUser].hostname];
    absenceRest.delegate = delegate;
    [absenceRest getData];
}



- (void)getData{
    KMDAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.sessionTimeOut) {
        return;
    }
    
    NSError *error;

    NSMutableURLRequest *request = [self kmdRequestWithMethod:@"POST" path:postAbsenceList  parameters:nil error:&error];
    
    if (error) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        return;
    }
    
    [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
   

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    NSString *dateString = [dateFormatter stringFromDate:self.appDelegate.fetchFromDate];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:@{@"StartDate":dateString ,@"EmployeeID":@""} options:0 error:nil]];
    
 
    
    [User currentUser].lastRequestToServer = [NSDate date];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        } else {
            NSError *error;
            if (data) {
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (error || ![result isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"%s %@\n%@",__PRETTY_FUNCTION__,error.localizedDescription,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                } else {
                    if (![result[@"AbsenceMainList"] isKindOfClass:[NSNull class]]) {
                        NSArray *absencelist = result[@"AbsenceMainList"];
                        NSArray *absenceExtraList = [result[@"AbsenceExtraList"] isKindOfClass:[NSNull class]]?nil:result[@"AbsenceExtraList"];
                        [self.appDelegate.managedObjectContext performBlock:^{
                        [Absence addArrayOfAbsenceDictionary:absencelist absenceExtra:absenceExtraList inManagedObjectContext:self.appDelegate.managedObjectContext];
                        }];
                    }
                }
            }
        }
        if ([self.delegate respondsToSelector:@selector(AbsenceRestDidFinishDownload:)]) {
                [self.delegate AbsenceRestDidFinishDownload:self];
        }
    }];
}

@end
