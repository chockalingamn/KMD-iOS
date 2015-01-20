//
//  KMDSwitchTableViewCell.m
//  leaverequest
//
//  Created by Per Friis on 17/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDSwitchTableViewCell.h"

@implementation KMDSwitchTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:NO animated:animated];

    // Configure the view for the selected state
}

@end
