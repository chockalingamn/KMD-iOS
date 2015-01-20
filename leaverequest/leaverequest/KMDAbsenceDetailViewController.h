//
//  KMDAbsenceDetailViewController.h
//  leaverequest
//
//  Created by Per Friis on 15/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Absence+KMD.h"


@interface KMDAbsenceDetailViewController : KMDTableViewController
/**
 * the current absence to work with
 * @note Must be valid, for creation, create the entity priore to show the controller
 */

@property (nonatomic, strong) Absence *absence;

@end
