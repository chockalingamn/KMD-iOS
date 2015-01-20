//
//  KMDMaternityREST.h
//  leaverequest
//
//  Created by Per Friis on 12/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"

@protocol KMDMaternityRESTDelegate;

@interface KMDMaternityREST : KmdRestClient
@property (nonatomic, assign) id <KMDMaternityRESTDelegate> delegate;
@property (nonatomic, readonly) NSArray *maternity;

+ (id)sharedInstance;

- (void)fetchFromBackEnd;
- (void)fetchFromBackEndForced;

@end


@protocol KMDMaternityRESTDelegate <NSObject>

- (void) MaternityREST:(KMDMaternityREST *)maternityREST didFaileWithError:(NSError *) error;
- (void) MaternityREST:(KMDMaternityREST *)maternityREST didUpdateWithMaternity:(NSArray *)maternity;
- (void) MaternityREST:(KMDMaternityREST *)maternityREST isUpToDate:(NSArray *)maternity;

@end