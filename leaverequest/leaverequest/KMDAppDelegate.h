//
//  KMDAppDelegate.h
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//



#import <UIKit/UIKit.h>
#define kKMDDatabaseIsReady @"KMDDatabaseIsReady"
#define KEY_FETCH_FROM_DATE @"fetchFromDate"


@interface KMDAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) BOOL sessionTimeOut;

@property (nonatomic, readonly) NSDate *fetchFromDate;

/**
 * set a nsuserdefaults (KEY_FETCH_FROM_DATE) with a starting point current month  eg today = 9-7 2014 give result 1-7-2014 if the paramerer is 0
 * @param month number of month to add to the value
 * @return Date the same date as stored in the NSUserDefaults
 */
- (NSDate *)setFromMonth:(NSInteger)month;


/**
 * same as setFromMonth, but this increments the count, keeping track of the previously add value
 * @param month the number of month to add to the current value, if no prevously value was added, the function will use current month as bias
 * @return date The same date as stored in NSUserDefaults
 */
- (NSDate *)addFromMonth:(NSInteger)month;

/**
 * logout and resets the database and fetch period
 */
- (IBAction)logout:(id)sender;
@end
