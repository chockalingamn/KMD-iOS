//
//  KMDSwitchTableViewCell.h
//  leaverequest
//
//  Created by Per Friis on 17/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KMDSwitchTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UISwitch *cellSwitch;
@property (nonatomic, weak) IBOutlet UILabel *lable;

@end
