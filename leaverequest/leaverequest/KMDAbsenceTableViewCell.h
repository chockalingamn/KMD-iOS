//
//  KMDAbsenceTableViewCell.h
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Absence+KMD.h"

@interface KMDAbsenceTableViewCell : UITableViewCell
@property (nonatomic, strong) Absence *absence;


+ (CGFloat)heightWith:(Absence *)absence;
@end
