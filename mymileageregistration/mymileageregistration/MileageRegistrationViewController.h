//
//  MileageRegistrationViewController.h
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import CoreData;

#import <UIKit/UIKit.h>

#import "KMDTableViewController.h"
#import "KMDMileage+utility.h"
#import "KMDIntermidiatePoint+utility.h"

@interface MileageRegistrationViewController : UITableViewController
@property (nonatomic, strong) KMDMileage *mileage;
@end
