//
//  KMDChildrenREST.h
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMD/KmdRestClient.h"

@protocol KMDChildrenRESTDelegate;

@interface KMDChildrenREST : KmdRestClient
@property (nonatomic, assign) id <KMDChildrenRESTDelegate> delegate;
@property (nonatomic, readonly) NSArray *children;

+ (id)sharedInstance;

- (void)fetchFromBackEnd;
- (void)fetchFromBackEndForced;

- (NSString *)childNameForID:(NSString *)childID;

@end


@protocol KMDChildrenRESTDelegate <NSObject>
- (void) childrenREST:(KMDChildrenREST *)childrenREST didFaileWithError:(NSError *) error;
- (void) childrenREST:(KMDChildrenREST *)childrenREST didUpdateWithChildren:(NSArray *)children;
- (void) childrenREST:(KMDChildrenREST *)childrenREST isUpToDate:(NSArray *)children;

@end