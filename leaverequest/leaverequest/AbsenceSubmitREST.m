//
//  leaverequestRestClient.m
//  leaverequest
//
//  Created by Per Friis on 08/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

static NSString *const postAbsenceList =@"KMD.LPT.Mobile.LeaveRequest/MyLeaveRequest/ReportLeaveRequest";

#import "DejalActivityView.h"
#import "KMD/User.h"
#import "Absence+KMD.h"

#import "AbsenceSubmitREST.h"
@interface AbsenceSubmitREST()
@property (nonatomic, readonly) KMDAppDelegate *appDelegate;

@end


@implementation AbsenceSubmitREST
- (KMDAppDelegate *)appDelegate{
    return [[UIApplication sharedApplication] delegate];
}



+ (void)submitAbsence:(Absence *)absence operation:(RestOperation)operation delegate:(id<AbsenceSubmitRESTDelegate>)delegate {
    AbsenceSubmitREST *absenceSubmitREST = [[AbsenceSubmitREST alloc] initWithBaseURL:[User currentUser].hostname];
    absenceSubmitREST.delegate = delegate;
    [absenceSubmitREST submitAbsence:absence operation:operation];
}



- (void)submitAbsence:(Absence *)absene operation:(RestOperation)operation{
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
    
    
    NSMutableDictionary *httpBodyDictionary = absene.dictionary;
    NSString *op = @"CREATE";
    switch (operation) {
        case operationDelete:
            op = @"DELETE";
            break;
            
        case operationModify:
            op = @"MODIFY";
            
        default:
            break;
    }
    
    [httpBodyDictionary setObject:op forKey:@"Operation"];
    
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:httpBodyDictionary options:0 error:nil];
    [request setHTTPBody:data];
    
    [User currentUser].lastRequestToServer = [NSDate date];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        
        if (connectionError) {
            [self.delegate absenceSubmitRest:self didFailWithError:connectionError];
        } else {
            
            
            
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            switch (httpResponse.statusCode) {
                case 200:
                    [self.delegate absenceSubmitRESTDitFinishWithSuccess:self forOperation:operation forAbsence:absene];
                    break;
                    
                case 400:{
                    NSDictionary *userData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                    [self.delegate absenceSubmitRest:self didFailWithUserMessage:[userData valueForKey:@"errorReason"]];
                }
                    break;
                    
                    
                default:
                    [self.delegate absenceSubmitRest:self didFailWithError:[[NSError alloc] initWithDomain:@"KMD OPUS" code:httpResponse.statusCode userInfo:[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil]]];
                    break;
            }
            
            NSLog(@"%s %@\n%@\n%@",__PRETTY_FUNCTION__,httpResponse,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding],error.localizedDescription);
        }
    }];
}

@end
