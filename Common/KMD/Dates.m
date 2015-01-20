#import "Dates.h"


@implementation Dates

static NSCalendar *__gregorianCalendar;

+ (NSDateFormatter *)createDateFormatter
{
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale]; // HACK: Setting zero's to force it.
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':00Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    
    return rfc3339DateFormatter;
}


+ (NSString *)RFC3339DateTimeStringFromDate:(NSDate *)date
{
    return [[Dates createDateFormatter] stringFromDate:date];
}


+ (NSDate *)RFC3339DateTimeStringToDate:(NSString *)rfc3339DateTimeString
{
    return [[Dates createDateFormatter] dateFromString:rfc3339DateTimeString];
}


+ (NSDateFormatter *)dateDateFormatter;
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy"];
    return dateFormatter;
}


+ (NSDateFormatter *)dateTimeDateFormatter
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd/MM/yyyy HH:mm"];
    return dateFormatter;
}


+ (NSString *)dateToString:(NSDate *)date
{
    return [[Dates dateDateFormatter] stringFromDate:date];
}

#pragma mark - Date Utilities

+ (NSDate *)firstDayOfThePreviousYearRelativeTo:(NSDate *)date
{
    // Returns january 1 the previous year from the input date argument
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:[[Dates.gregorianCalendar components:NSYearCalendarUnit fromDate:date] year]-1];
    [dateComponents setMonth:1];
    [dateComponents setDay:1];
    [dateComponents setHour:0];
    [dateComponents setMinute:0];
    [dateComponents setSecond:0];
    
    return [Dates.gregorianCalendar dateFromComponents:dateComponents];
}

+ (NSDate *)lastDayOfTheYearRelativeTo:(NSDate *)date
{
    // Returns december 31 the same year as the input date argument
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:[[Dates.gregorianCalendar components:NSYearCalendarUnit fromDate:date] year]];
    [dateComponents setMonth:12];
    [dateComponents setDay:31];
    [dateComponents setHour:23];
    [dateComponents setMinute:59];
    [dateComponents setSecond:59];
    
    return [Dates.gregorianCalendar dateFromComponents:dateComponents];
}

+ (NSDate *)lastDayOfTheFollowingYearRelativeTo:(NSDate *)date
{
    // Returns december 31 the same year as the input date argument
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:[[Dates.gregorianCalendar components:NSYearCalendarUnit fromDate:date] year]+1];
    [dateComponents setMonth:12];
    [dateComponents setDay:31];
    [dateComponents setHour:23];
    [dateComponents setMinute:59];
    [dateComponents setSecond:59];
    
    return [Dates.gregorianCalendar dateFromComponents:dateComponents];
}

+ (NSDate *)addOneYearTo:(NSDate *)date
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:1];
    [dateComponents setMonth:0];
    [dateComponents setDay:0];
    NSDate *outputDate = [Dates.gregorianCalendar dateByAddingComponents:dateComponents toDate:date options:0];
    return outputDate;
}

+ (NSDate *)subtractOneYearFrom:(NSDate *)date
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    [dateComponents setYear:-1];
    [dateComponents setMonth:0];
    [dateComponents setDay:0];
    NSDate *outputDate = [Dates.gregorianCalendar dateByAddingComponents:dateComponents toDate:date options:0];
    return outputDate;
}

+ (NSCalendar *)gregorianCalendar
{
    if (!__gregorianCalendar) {
        __gregorianCalendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    }
    
    return __gregorianCalendar;
}


@end
