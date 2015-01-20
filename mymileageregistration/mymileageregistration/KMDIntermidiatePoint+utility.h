//
//  KMDIntermidiatePoint+utility.h
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

@import MapKit;
@import CoreLocation;

#import "KMDIntermidiatePoint.h"

@interface KMDIntermidiatePoint (utility)<MKAnnotation>

/**
 * deletes all current Intermidiate points on the mileage registration and add the new ones
 * @param array An array of dictionary, with keys matching the attributes in the intermidiatePoint
 * @param mileage The mileage that sould hold the intermidiate points
 */
+ (void) addPointsFromArray:(NSArray *)array addToMileage:(KMDMileage *)mileage;


+ (NSInteger) addIntermidiatePointToMileage:(KMDMileage *)onMilage withCoordinates:(CLLocationCoordinate2D )coordinate;

+ (NSString *)entityName;
- (NSString *)entityName;


@end
