//
//  Absence.h
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Absence : NSManagedObject

@property (nonatomic, retain) NSString * absenceID;
@property (nonatomic, retain) NSString * absenceName;
@property (nonatomic, retain) NSDate * actualDeliveryDate;
@property (nonatomic, retain) NSString * childCPR;
@property (nonatomic, retain) NSString * childID;
@property (nonatomic, retain) NSString * comments;
@property (nonatomic, retain) NSDate * endDate;
@property (nonatomic, retain) NSDate * expectedDeliveryDate;
@property (nonatomic, retain) NSNumber * hours;
@property (nonatomic, retain) NSString * maternityID;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * nComment;
@property (nonatomic, retain) NSString * reasonTypeID;
@property (nonatomic, retain) NSString * reasonTypeText;
@property (nonatomic, retain) NSString * requestID;
@property (nonatomic, retain) NSDate * startDate;
@property (nonatomic, retain) NSString * statusID;
@property (nonatomic, retain) NSString * statusText;
@property (nonatomic, retain) NSString * userID;
@property (nonatomic, retain) NSDate * workInjuryDate;
@property (nonatomic, retain) NSString * workInjuryID;
@property (nonatomic, retain) NSString * oldAbsenceTypeID;
@property (nonatomic, retain) NSDate * oldStartDate;
@property (nonatomic, retain) NSDate * oldEndDate;
@property (nonatomic, retain) NSString * childName;

@end
