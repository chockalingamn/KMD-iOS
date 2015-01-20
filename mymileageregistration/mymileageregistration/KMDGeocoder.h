//
//  KMDGeocoder.h
//  mymileageregistration
//
//  Created by Per Friis on 09/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMDMileage+utility.h"

@interface KMDGeocoder : NSObject
+ (void)reverseGeocode:(CLLocation *)location completionHandler:(void (^)(NSString *formattedAddress, NSError *error))completionBlock;
+ (void)calculateDistanceOnMileage:(KMDMileage *)mileage completionBlock:(void(^)(double distance, NSError *error)) completionBlock;

+ (void)autoComplete:(NSString *)string location:(CLLocation *)location completionBlock:(void (^)(NSArray *suggestions)) completionBlock;
@end
