//
//  KMDReasonREST.h
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"

@protocol KMDReasonRESTDelegate;

@interface KMDReasonREST : KmdRestClient
@property (nonatomic, assign) id <KMDReasonRESTDelegate> delegate;
@property (nonatomic, readonly) NSArray *reasons;

+ (id)sharedInstance;

- (void)fetchFromBackEnd;
- (void)fetchFromBackEndForced;


@end


@protocol KMDReasonRESTDelegate <NSObject>

- (void) reasonREST:(KMDReasonREST *)reasonREST didFaileWithError:(NSError *) error;
- (void) reasonREST:(KMDReasonREST *)reasonREST didUpdateWithReasons:(NSArray *)reasons;
- (void) reasonREST:(KMDReasonREST *)reasonREST isUpToDate:(NSArray *)reasons;

@end