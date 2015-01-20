//
//  KMDTemplate+utility.h
//  mymileageregistration
//
//  Created by Per Friis on 09/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import "KMDTemplate.h"
static NSString *templateUpdatedFromBackendNotification = @"templateUpdatedFromBackendNotification";


@interface KMDTemplate (utility)
+ (NSDate *)lastRefreshed;
+ (void)setLastRefreshed:(NSDate *)lastRefreshed;
+ (NSArray *)templatesInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
+ (void)updateTemplateFromBackend;

+ (NSString *)templateNameFor:(NSString *)templateID;

@end
