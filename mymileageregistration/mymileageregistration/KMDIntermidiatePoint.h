//
//  KMDIntermidiatePoint.h
//  mymileageregistration
//
//  Created by Per Friis on 04/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KMDMileage;

@interface KMDIntermidiatePoint : NSManagedObject

@property (nonatomic, retain) NSNumber * distanceFromLastAddress;
@property (nonatomic, retain) NSString * intermidiateAddress;
@property (nonatomic, retain) NSNumber * manualDistance;
@property (nonatomic, retain) NSString * versionID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) KMDMileage *onMileage;

@end
