//
//  DistanceNumberUtil.h
//  Driver Registration
//
//  Created by Henning Böttger on 20/09/12.
//  Copyright (c) 2012 Trifork Public A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TripDistanceUtil : NSObject

+(NSString *)formatDecimalNumberWithComma:(NSNumber *)number;
+(NSString *)formatDecimalNumberWithDot:(NSNumber *)number;
+(bool)isValidTripDistance:(NSString *)string;

@end
