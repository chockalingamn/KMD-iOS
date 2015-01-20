//
//  MileageTableViewCell.h
//  mymileageregistration
//
//  Created by Per Friis on 11/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MileageTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UILabel *mileagePurposeLable;
@property (nonatomic, weak) IBOutlet UILabel *departureDateLable;
@property (nonatomic, weak) IBOutlet UILabel *distanceLabel;
@property (nonatomic, weak) IBOutlet UIImageView *statusImageView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;

@end
