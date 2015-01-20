//
//  V130Registration.h
//  mymileageregistration
//
//  Created by Per Friis on 04/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface V130Registration : NSManagedObject

@property (nonatomic, retain) NSString * destination;
@property (nonatomic, retain) NSNumber * isSent;
@property (nonatomic, retain) NSString * origin;
@property (nonatomic, retain) NSString * reason;
@property (nonatomic, retain) NSString * templateID;
@property (nonatomic, retain) NSString * templateName;
@property (nonatomic, retain) NSDate * tripDate;
@property (nonatomic, retain) NSNumber * tripDistanceInKilometers;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * vehicleRegistrationNumber;

@end
