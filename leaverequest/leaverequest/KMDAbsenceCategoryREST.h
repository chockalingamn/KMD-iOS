//
//  KMDAbsenceCategoryREST.h
//  leaverequest
//
//  Created by Per Friis on 15/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"

@protocol KMDAbsenceCategoryRESTDelegate;

@interface KMDAbsenceCategoryREST : KmdRestClient
@property (nonatomic, assign) id <KMDAbsenceCategoryRESTDelegate> delegate;
@property (nonatomic, strong) NSArray *categories;
+ (id)sharedInstance;

- (void)fetchFromBackEnd;
- (void)fetchFromBackEndForced;

@end


@protocol KMDAbsenceCategoryRESTDelegate <NSObject>

- (void)absenceCategory:(KMDAbsenceCategoryREST *)category didFailWithError:(NSError *)error;
- (void)absenceCategory:(KMDAbsenceCategoryREST *)category didUpdateWithData:(NSArray *)categories;
- (void)absenceCategory:(KMDAbsenceCategoryREST *)category isUpToDate:(NSArray *)categories;

@end