//
//  leaverequestRestClient.h
//  leaverequest
//
//  Created by Per Friis on 08/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"
#import "Absence+KMD.h"

typedef NS_ENUM(NSInteger, RestOperation) {
    operationCreate,
    operationDelete,
    operationModify
};

@protocol AbsenceSubmitRESTDelegate;

@interface AbsenceSubmitREST : KmdRestClient
@property (nonatomic, assign) id <AbsenceSubmitRESTDelegate> delegate;

+ (void)submitAbsence:(Absence *)absence operation:(RestOperation)operation delegate:(id<AbsenceSubmitRESTDelegate>) delegate;

@end


@protocol AbsenceSubmitRESTDelegate <NSObject>

- (void)absenceSubmitRest:(AbsenceSubmitREST *)sender didFailWithError:(NSError *)error;
- (void)absenceSubmitRest:(AbsenceSubmitREST *)sender didFailWithUserMessage:(NSString *)userMessage;
- (void)absenceSubmitRESTDitFinishWithSuccess:(AbsenceSubmitREST *)sender forOperation:(RestOperation)operation forAbsence:(Absence *)absence;

@end