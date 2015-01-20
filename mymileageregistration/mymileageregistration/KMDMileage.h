//
//  KMDMileage.h
//  mymileageregistration
//
//  Created by Per Friis on 04/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class KMDIntermidiatePoint;

@interface KMDMileage : NSManagedObject

@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSDate * depatureTimestamp;
@property (nonatomic, retain) NSNumber * distanceOfTripInKilometers;
@property (nonatomic, retain) NSString * endAddress;
@property (nonatomic, retain) NSNumber * eligibleForDelete;
@property (nonatomic, retain) NSNumber * isSent;
@property (nonatomic, retain) NSString * mileageType;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * startAddress;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSString * templateID;
@property (nonatomic, retain) NSString * templateName;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * vehicleRegistrationNumber;
@property (nonatomic, retain) NSString * versionID;
@property (nonatomic, retain) NSString * workFlowID;
@property (nonatomic, retain) NSNumber * startLatitude;
@property (nonatomic, retain) NSNumber * startLongitude;
@property (nonatomic, retain) NSString * submitError;
@property (nonatomic, retain) NSNumber * endLatitude;
@property (nonatomic, retain) NSNumber * endLongitude;
@property (nonatomic, retain) NSOrderedSet *intermidiatePoints;
@end

@interface KMDMileage (CoreDataGeneratedAccessors)

- (void)insertObject:(KMDIntermidiatePoint *)value inIntermidiatePointsAtIndex:(NSUInteger)idx;
- (void)removeObjectFromIntermidiatePointsAtIndex:(NSUInteger)idx;
- (void)insertIntermidiatePoints:(NSArray *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeIntermidiatePointsAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInIntermidiatePointsAtIndex:(NSUInteger)idx withObject:(KMDIntermidiatePoint *)value;
- (void)replaceIntermidiatePointsAtIndexes:(NSIndexSet *)indexes withIntermidiatePoints:(NSArray *)values;
- (void)addIntermidiatePointsObject:(KMDIntermidiatePoint *)value;
- (void)removeIntermidiatePointsObject:(KMDIntermidiatePoint *)value;
- (void)addIntermidiatePoints:(NSOrderedSet *)values;
- (void)removeIntermidiatePoints:(NSOrderedSet *)values;
@end
