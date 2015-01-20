//
//  KMDFitForDutyViewController.m
//  leaverequest
//
//  Created by Per Friis on 10/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//



#import "KMDFitForDutyViewController.h"

@interface KMDFitForDutyViewController ()
@property (nonatomic, weak) IBOutlet UILabel *absenceNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *absenceExtraLabel;
@property (nonatomic, weak) IBOutlet UILabel *absenceStartDateLabel;
@property (nonatomic, weak) IBOutlet UIImageView *backgroundImageView;

@property (nonatomic, weak) IBOutlet UIButton       *done;
@property (nonatomic, weak) IBOutlet UIDatePicker   *datePicker;
@property (nonatomic, weak) IBOutlet UIView         *dataFrameView;

@end

@implementation KMDFitForDutyViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.datePicker.minimumDate = self.absence.startDate;
    if ([self.absence.startDate timeIntervalSinceNow] > 0) {
        self.datePicker.date = self.absence.startDate;
    } else {
        self.datePicker.date = [NSDate stripTimeFromDate:[NSDate date]];
    }
    
    self.datePicker.datePickerMode = UIDatePickerModeDate;
        
    self.absenceNameLabel.text = self.absence.absenceName;
    self.absenceExtraLabel.text = self.absence.extraValueDisplayString;
    self.absenceStartDateLabel.text = [[NSDateFormatter displayDateWithYear] stringFromDate:self.absence.startDate];
    
    self.done.layer.borderColor = [[UIColor colorWithWhite:.7f alpha:1] CGColor];
    self.done.layer.borderWidth = 0.5f;
    self.done.layer.cornerRadius = 10.0f;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)apparove:(id)sender{
    [self.delegate fitForDutyViewController:self didSelectDate:self.datePicker.date];
}

@end
