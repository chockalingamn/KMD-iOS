//
//  KMDAbsenceCategoryTableViewController.h
//  leaverequest
//
//  Created by Per Friis on 15/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Absence+KMD.h"

@interface KMDAbsenceCategoryTableViewController : KMDTableViewController
@property (nonatomic, strong) Absence *absence;
@end
