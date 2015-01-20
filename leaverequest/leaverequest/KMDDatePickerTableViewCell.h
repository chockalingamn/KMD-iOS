//
//  KMDDatePickerTableViewCell.h
//  leaverequest
//
//  Created by Per Friis on 16/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol KMDDatePickerTableViewCellDelegate;

@interface KMDDatePickerTableViewCell : UITableViewCell
@property (nonatomic, assign) id <KMDDatePickerTableViewCellDelegate> delegate;
@property (nonatomic, strong) NSDate *mindate;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;

@end

@protocol KMDDatePickerTableViewCellDelegate <NSObject>

@optional
- (void) datePickerCell:(KMDDatePickerTableViewCell *)cell didChangeDateValue:(NSDate *)date;

@end
