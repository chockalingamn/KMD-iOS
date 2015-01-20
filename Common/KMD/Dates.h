#import <Foundation/Foundation.h>


@interface Dates : NSObject

+ (NSString *)RFC3339DateTimeStringFromDate:(NSDate *)date;

/// @returns nil if the string could not be converted.
///
+ (NSDate *)RFC3339DateTimeStringToDate:(NSString *)rfc3339DateTimeString;

/// @returns a date formatter with format dd.MM.yyyy
///
+ (NSDateFormatter *)dateDateFormatter;

/// @returns a date formatter with format dd.MM.yyyy HH:mm
///
+ (NSDateFormatter *)dateTimeDateFormatter;

/// @returns a string with format dd.MM.yyyy
///
+ (NSString *)dateToString:(NSDate *)date;

/// @returns date representing january 1 a year before the input date
///
+ (NSDate *)firstDayOfThePreviousYearRelativeTo:(NSDate *)date;

/// @returns date representing december 31 the same year as the input date
///
+ (NSDate *)lastDayOfTheYearRelativeTo:(NSDate *)date;

/// @returns date representing december 31 the following year relative to the input date
///
+ (NSDate *)lastDayOfTheFollowingYearRelativeTo:(NSDate *)date;

/// @returns date adding one year to the input date
///
+ (NSDate *)addOneYearTo:(NSDate *)date;

/// @returns date subtracting one year from the input date
///
+ (NSDate *)subtractOneYearFrom:(NSDate *)date;

@end
