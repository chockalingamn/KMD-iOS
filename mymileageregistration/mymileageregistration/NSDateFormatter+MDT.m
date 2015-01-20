//
//  NSDateFormatter+MDT.m
//  leaverequest
//
//  Created by Per Friis on 13/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "NSDateFormatter+MDT.h"

@implementation NSDateFormatter (MDT)

+ (NSDateFormatter *)displayDateWithOutYear{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    df.dateFormat = @"d. MMM";
    return df;
}

+ (NSDateFormatter *)displayDateWithYear{
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    df.dateFormat = @"d. MMM YYYY";
    return df;
}

+ (NSDateFormatter *)rfc3339{
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    return df;
}

+ (NSDateFormatter *)rfc3339GMT{
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    df.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    df.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    return df;
}

+ (NSDateFormatter *)rfc3339NoTime{
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    df.dateFormat = @"yyyy-MM-dd";
    return df;
}

@end
