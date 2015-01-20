//
//  NSDateFormatter+MDT.h
//  leaverequest
//
//  Created by Per Friis on 13/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDateFormatter (MDT)
+ (NSDateFormatter *)displayDateWithOutYear;
+ (NSDateFormatter *)displayDateWithYear;
+ (NSDateFormatter *)rfc3339;
+ (NSDateFormatter *)rfc3339GMT;
+ (NSDateFormatter *)rfc3339NoTime;
@end
