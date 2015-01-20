//
//  KMDWorkInjuryREST.h
//  leaverequest
//
//  Created by Per Friis on 12/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"

@protocol KMDWorkInjuryRESTDelegate;

@interface KMDWorkInjuryREST : KmdRestClient
@property (nonatomic, assign) id <KMDWorkInjuryRESTDelegate> delegate;
@property (nonatomic, readonly) NSArray *workInjuries;

+ (id)sharedInstance;

- (void)fetchFromBackEnd;
- (void)fetchFromBackEndForced;



@end


@protocol KMDWorkInjuryRESTDelegate <NSObject>

- (void) workInjuryREST:(KMDWorkInjuryREST *)workInjuryREST didFaileWithError:(NSError *) error;
- (void) workInjuryREST:(KMDWorkInjuryREST *)workInjuryREST didUpdateWithWorkInjuries:(NSArray *)workInjuries;
- (void) workInjuryREST:(KMDWorkInjuryREST *)workInjuryREST isUpToDate:(NSArray *)workInjuries;

@end