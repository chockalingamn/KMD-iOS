//
//  KMDTemplate.h
//  mymileageregistration
//
//  Created by Per Friis on 04/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface KMDTemplate : NSManagedObject

@property (nonatomic, retain) NSString * templateID;
@property (nonatomic, retain) NSString * templateName;


@end
