//
//  KMDMileage+utility.h
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import "KMDMileage.h"

static NSString *const mileageDidUpdateFromBackend = @"mileagedidUpdateFromBackend";
static NSString *const mileageFailedTupdateFromBackend = @"mileageFailedUpdateFromBackend";
static NSString *const milageBackendMightHaveUpdates = @"milageBackendMightHaveUpdates";

@interface KMDMileage (utility)
/**
 * Analyse the mandatory fields in the current mileage registration
 * @return isValid BOOL value telling that the mileage is valid for submission
 */
@property (nonatomic, readonly, getter=isValid) BOOL valid;

@property (nonatomic, readonly) NSArray *mappoints;


@property (nonatomic, readonly) NSAttributedString *displayReason;
@property (nonatomic, readonly) NSAttributedString *displayTeamplateName;
/**
 * insert a new Mileage registration in the managed context, it sets the default values
 * @param context The managedObjectContext to hold the new managedObject
 * @return mileage the new entity, with default values
 */
+ (instancetype)newMileageInManagedContext:(NSManagedObjectContext *)context;

/**
 * the entityname
 * @return entityName
 */
+ (NSString *)entityName;


/**
 * calls the server with the current user credentials and update the local core 
 * with the result, the method posts notifications depenting of the result.
 * @note The method will post a mileageDidUpdateFromBackend or mileageFailedUpdateFromBackend notification based on the result
 */
+ (void)updateMileageRegistrationsFromBackend;

/**
 * Clean all the local mileage registrations, without purpose, origien, via, destination, distance, license, remark
 *
 */
+ (void)cleanEmplyMileageRegistrations;


/**
 * Collects the data, and submits the data to the backend.
 * the mileage entity is updated upon the success or failure received from the backend
 * upon success, the sent and status is updated
 * upon falure, the sent is set to NO and the submitError is set to the error message from the backend.
 * The error message from the backend, is mostly a user readable format
 */
- (void)submitMileageToBackend;

- (NSString *)entityName;

/**
 * validates the data and update the submitError with a validation text if not vald
 */
- (void)validateAndUpdateError;

@end
