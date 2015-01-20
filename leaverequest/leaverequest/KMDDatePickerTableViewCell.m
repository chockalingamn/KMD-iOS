//
//  KMDDatePickerTableViewCell.m
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDDatePickerTableViewCell.h"
@interface KMDDatePickerTableViewCell()
@end


@implementation KMDDatePickerTableViewCell
- (void)setDate:(NSDate *)date{
    _date = date;
    if (_date) {
        self.datePicker.date = _date;
    }
}

- (void)setMindate:(NSDate *)mindate{
    _mindate = mindate;
    self.datePicker.minimumDate = _mindate;
}

- (void)awakeFromNib
{
    [self.datePicker addTarget:self action:@selector(datePickerChangedValue:) forControlEvents:UIControlEventValueChanged];
    
    
}

- (IBAction)datePickerChangedValue:(UIDatePicker *)datePicker{
    self.date = self.datePicker.date;
    if ([self.delegate respondsToSelector:@selector(datePickerCell:didChangeDateValue:)]) {
        [self.delegate datePickerCell:self didChangeDateValue:self.datePicker.date];
    }
}

@end
