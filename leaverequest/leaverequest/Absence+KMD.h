//
//  Absence+KMD.h
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "Absence.h"

#define ABSENCE_ID      @"AbsenceID"
#define ABSENCE_NAME    @"AbsenceName"
#define COMMENTS        @"Comments"
#define END_DATE        @"EndDate"
#define END_TIME        @"EndTime"
#define HOURS           @"Hours"
#define NAME            @"Name"
#define NEW_COMMENT     @"NewComment"
#define REQUEST_ID      @"RequestID"
#define START_DATE      @"StartDate"
#define START_TIME      @"StartTime"
#define STATUS_ID       @"StatusID"
#define STATUS_TEXT     @"StatusText"
#define USER_ID         @"UserID"

// AbsenceExtra
#define CHILD_CPR        @"ChildCPR"
#define CHILD_ID         @"ChildID"
#define MATERNITY_ID     @"MaternityID"
#define REASON_TYPE_ID   @"ReasonTypeID"
#define REASON_TYPE_TEXT @"ReasonTypeText"
#define WORK_INJURY_DATE @"WorkInjuryDate"
#define WORK_INJURY_ID   @"WorkInjuryID"
#define ACTUAL_DELIVERY_DATE @"ActualDeliveryDate"
#define EXPECTED_DILIVERY_DATE @"ExpectedDeliveryDate"

typedef NS_ENUM(NSInteger, AbsenceSubmitStatus) {
    statusUnknown = -1,
    statusNone,
    statusSubmitted,
    statusError,
    statusApproved
};

typedef NS_ENUM(NSInteger, ExtraTypes){
    extraTypeUnknown = -1,
    extraTypeNone,
    extraTypeCareDay,
    extraTypeLeave,
    extraTypeWorkRelatedInjury,
    extraTypeMaternity
};

@interface Absence (KMD) <UIActionSheetDelegate>
/**
 * Validates the mandatory fields
 * @return valid Yes if the absence are ready to be submittet to backend
 */
@property (nonatomic, readonly) BOOL isValid;

/**
 * a more controlled way to chek the status
 * @return a enum value of the type AbsenceSubmitStatus
 */
@property (nonatomic, readwrite) AbsenceSubmitStatus status;

/**
 * the image to on the absence
 * @return statusImage The image that matches the status of the absence
 */
@property (nonatomic, readonly) UIImage *statusImage;

/**
 * status color, return a UIColor that matches the current status and status image
 */
@property (nonatomic, readonly) UIColor *statusColor;

/**
 * Yes if the current absenceID (type) requires extra data, the field can be one of serval, use extraID and extraText to set or get the extra data.
 */
@property (nonatomic, readonly) BOOL mustHaveExtra;


/**
 * Get a generel type for the extra data required if any
 * @return extraTypeID;
 */
@property (nonatomic, readonly) ExtraTypes extraTypeID;


/**
 * Dictionary ready to pase as json
 * @return Dictionary all keys and values
 */
@property (nonatomic, readonly) NSMutableDictionary *dictionary;

/**
 * Get or sets the extra data for a given absence, the value is fetched and placed in the "right" propertie
 * using the absenceID (absence type) to determin the placement eg. for absenceID "TJ" the extra value is using
 * the reasonID
 */
@property (nonatomic, readwrite) NSString *extraID;

/**
 * Get or sets the extra data for a given absence, the value is fetched and placed in the "right" propertie
 * using the absenceID (absence type) to determin the placement eg. for absenceID "TJ" the extra value is using
 * the reasonText
 */
@property (nonatomic, readwrite) id extraValue;

/**
 * Get the display string of the extra value
 * @return NSString the display name
 */
@property (nonatomic, readonly) NSString *extraValueDisplayString;

/**
 * return the display string formatted as "99t 59m"
 */
@property (nonatomic, readonly) NSString *durationDisplayString;

/**
 * if the start and the end time is 00:00 the registration is viewed as a whole day
 * @return BOOL YES if the registration is a wholeday
 */
@property (nonatomic, readonly) BOOL wholeDay;

/**
 * if the registration's endtime is on the same date as the start time, the registration is viewed as a one day
 * @return BOOL yes if its only for one day
 */
@property (nonatomic, readonly) BOOL oneDay;

/**
 * Get if the end date is not pressent (1-1-9999) or sets the enddate to be openended
 * @return BOOL YES if openenden
 */
@property (nonatomic, readwrite) BOOL openEnded;

/**
 * Add an array of absence, comming from the backen call (GetAbsenceList) this array must hold only AbsenceMainList objects
  * @note items with the same absentID, startTime and end dateTime wont be imported.
 * @param array The array of AbsenceMainList from the orginal json form GetAbsenceList
 * @param extraArray if there is registrations that have extra data on, the additional data i in this array, the additional data will be linked using the RequestID, can be nil
 * @param managedObjectContext The context to create the entities
 * @return none There is no return value nor any return if the method encounter errors.
 */
+ (void)addArrayOfAbsenceDictionary:(NSArray *)array absenceExtra:(NSArray *)extraArray inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 * Cleans the absence as all the data must be fetched from the server
 * @param ManagedObjectContext The handle to the managed object context
*/
+ (void)cleanAbsenceTableInManagedObjectContext:(NSManagedObjectContext *)managedObjectContect;

/**
 * checks the current data for a "non closed registration", end year = 9999
 * @param managedObjectContext the context to search for the database
 * @return Yes if there is a "non closed registration"
 */
+ (Absence *)haveOpenRegistrationInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

/**
 * As the GetAbsenceList don't have the children's name we need to fetch and add the name after the first fetch.
 */
+ (void)updateChildren;


@end
