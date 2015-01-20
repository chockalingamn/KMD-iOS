//
//  leaverequestRestClient.h
//  leaverequest
//
//  Created by Per Friis on 08/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"
#import "Absence+KMD.h"


@protocol AbsenceRESTDelegate;

@interface AbsenceREST : KmdRestClient
@property (nonatomic, assign) id <AbsenceRESTDelegate> delegate;

+ (void)fetchAbsenceWithDelegate:(id<AbsenceRESTDelegate>) delegate;

- (void)getData;

@end


@protocol AbsenceRESTDelegate <NSObject>

@optional
- (void)AbsenceRestDidFinishDownload:(AbsenceREST *)absenceRest;

@end