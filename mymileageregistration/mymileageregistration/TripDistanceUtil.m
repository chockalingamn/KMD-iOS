//
//  DistanceNumberUtil.m
//  Driver Registration
//
//  Created by Henning Böttger on 20/09/12.
//  Copyright (c) 2012 Trifork Public A/S. All rights reserved.
//

#import "TripDistanceUtil.h"

@implementation TripDistanceUtil

+(NSString *)formatDecimalNumberWithComma:(NSNumber *)number
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMinimumIntegerDigits:1];
    [formatter setMinimumFractionDigits:0];
    [formatter setMaximumFractionDigits:2];
    [formatter setDecimalSeparator:@","];
    return [formatter stringFromNumber:number];
}

+(NSString *)formatDecimalNumberWithDot:(NSNumber *)number
{
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setMinimumIntegerDigits:1];
    [formatter setMinimumFractionDigits:0];
    [formatter setMaximumFractionDigits:2];
    [formatter setDecimalSeparator:@"."];
    return [formatter stringFromNumber:number];
}

+(bool)isValidTripDistance:(NSString *)string
{
    // Regular expression: [0-9]+(,[0-9]{1,2})?
    NSRegularExpression *intermediateInputRegexp = [NSRegularExpression regularExpressionWithPattern:@"\\A(\\d)+(,(\\d){0,2})?\\z" options:0 error:nil];
    return [intermediateInputRegexp numberOfMatchesInString:string options:0 range:NSMakeRange(0, [string length])] > 0;
}

@end
