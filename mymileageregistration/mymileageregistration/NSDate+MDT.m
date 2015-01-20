//
//  NSDate+MDT.m
//  leaverequest
//
//  Created by Per Friis on 15/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "NSDate+MDT.h"

@implementation NSDate (MDT)
+ (NSDate *)stripTimeFromDate:(NSDate *)date{
    return [NSDate setTime:@"00:00" onDate:date];
}

+ (NSDate *)stripMinutesAndSecondsFromDate:(NSDate *)date{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd'T'HH:00:00'Z'"];
    NSString *dateString = [df stringFromDate:date];
    
    return [df dateFromString:dateString];
}

+ (NSDate *)setTime:(NSString *)timeString onDate:(NSDate *)date{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = [NSString stringWithFormat:@"yyyy-MM-dd'T'%@'Z'",timeString];
    NSString *dateString = [df stringFromDate:date];// stringByAppendingString:timeString];
    df.dateFormat = @"yyyy-MM-dd'T'HH:mm'Z'";
    return [df dateFromString:dateString];
}

+ (NSDate *)dateWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"yyyy-MM-dd";
    NSString *dateString = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",(long)year,(long)month,(long)day];
    NSDate *date = [df dateFromString:dateString];
    return date;
}

+ (NSDate *)higendDate{
    return [NSDate dateWithYear:9999 month:12 day:31];
}
                            
                            
                            
@end
