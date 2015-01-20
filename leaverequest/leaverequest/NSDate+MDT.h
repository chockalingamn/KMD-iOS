//
//  NSDate+MDT.h
//  leaverequest
//
//  Created by Per Friis on 15/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (MDT)


/**
 * sets the tim to be 00:00 on the given date
 * @note when debugging you will se the NSdate object in GMT so it might look like the time is wrong, but then check your local timezone
 * @param date the date to set the time to 00:00
 * @return date the same date but with a stripped time
 */
+ (NSDate *)stripTimeFromDate:(NSDate *)date;

/**
 * sets the time to be the whole hour
 * @return date the same date and hour, without minutes/seconds
 */
+ (NSDate *)stripMinutesAndSecondsFromDate:(NSDate *)date;

/**
 * set the time on a given date
 * @note when debugging you will se the NSdate object in GMT so it might look like the time is wrong, but then check your local timezone
 * @param timeStrin the time to set on the date in 24 hour format (HH:mm)
 * @param date The date to set the time on
 * @return date with the time set
 */
+ (NSDate *)setTime:(NSString *)timeString onDate:(NSDate *)date;

/**
 * created a date from Year, Month and day, no validation.
 * @param year the year
 * @param month 1-12
 * @param day 1-31, depending of the month
 * @return NSdate a NSDate representation of the parameter (time 00:00)
 */
+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day;

/**
 * generets the higend date (9999-12-31 00:00)
 * @return NSDate 9999-12-31
 */
+ (NSDate *)higendDate;

- (NSInteger) year;

@end
