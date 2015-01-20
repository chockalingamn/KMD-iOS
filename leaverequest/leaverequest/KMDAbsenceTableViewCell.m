//
//  KMDAbsenceTableViewCell.m
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDAbsenceTableViewCell.h"
#import "NSDateFormatter+MDT.h"

@interface KMDAbsenceTableViewCell()
@property (nonatomic, weak) IBOutlet UIView         *statusBackgroundView;
@property (nonatomic, weak) IBOutlet UIImageView    *statusImageView;
@property (nonatomic, weak) IBOutlet UILabel        *absenceNameLabel;
@property (nonatomic, weak) IBOutlet UILabel        *extraLabel;
@property (nonatomic, weak) IBOutlet UILabel        *periodLabel;
@property (nonatomic, weak) IBOutlet UILabel        *durationLabel;
@property (nonatomic, weak) IBOutlet UIImageView    *durationImageView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@end

@implementation KMDAbsenceTableViewCell
#pragma mark - Properties
- (void)setAbsence:(Absence *)absence{
        _absence = absence;
        [self updateDataOnView];
}

#pragma mark - class methods
+ (CGFloat)heightWith:(Absence *)absence{
    CGFloat height = absence.mustHaveExtra?52.0f:46.0f;
    CGSize constringSize = CGSizeMake(261.0f, 999.0f);
   
    if([[[UIDevice currentDevice] systemVersion] integerValue] > 6){
        height += CGRectGetHeight([absence.absenceName boundingRectWithSize:constringSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]} context:nil]);
        if (absence.mustHaveExtra) {
            height += CGRectGetHeight([absence.extraValueDisplayString boundingRectWithSize:constringSize options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]} context:nil]);
        }
    } else {
        height += [absence.absenceName sizeWithFont:[UIFont systemFontOfSize:16.0f]].height;
        
        if (absence.mustHaveExtra) {
            height += [absence.extraValueDisplayString sizeWithFont:[UIFont systemFontOfSize:14.0f]].height;
        }
    }
    return height;
}


#pragma mark - Instance methods

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)updateDataOnView{

    self.absenceNameLabel.text = self.absence.absenceName;
    self.extraLabel.text = self.absence.extraValueDisplayString;
    self.statusImageView.image = self.absence.statusImage;
    if (self.absence.statusID) {
        [self.activityIndicatorView stopAnimating];
    } else {
        [self.activityIndicatorView startAnimating];
    }
    
    self.statusBackgroundView.backgroundColor = self.absence.statusColor;
    
    
    
    BOOL thisYear = [self.absence.startDate year] == [[NSDate date] year];
    BOOL thisYearEnd = [self.absence.endDate year] == [[NSDate date] year];
    BOOL sameYear = [self.absence.startDate year] == [self.absence.endDate year];
    
    if (thisYear) {
        self.periodLabel.text = [[NSDateFormatter displayDateWithOutYear] stringFromDate:self.absence.startDate];
    } else {
        self.periodLabel.text = [[NSDateFormatter displayDateWithYear] stringFromDate:self.absence.startDate];
    }
    
    if (self.absence.endDate && ![self.absence.endDate isEqualToDate:self.absence.startDate] && !self.absence.openEnded) {
        if (sameYear || thisYearEnd) {
            self.periodLabel.text = [self.periodLabel.text stringByAppendingFormat:@" - %@",[[NSDateFormatter displayDateWithOutYear] stringFromDate:self.absence.endDate]];
        } else {
            self.periodLabel.text = [self.periodLabel.text stringByAppendingFormat:@" - %@",[[NSDateFormatter displayDateWithYear] stringFromDate:self.absence.endDate]];
        }
    }
    
    if (!self.absence.wholeDay && self.absence.hours.floatValue > 0) {
        self.durationLabel.text = self.absence.durationDisplayString;
        self.durationLabel.hidden = NO;
        self.durationImageView.hidden = NO;
    } else {
        self.durationLabel.hidden = YES;
        self.durationImageView.hidden = YES;
    }
}

@end
