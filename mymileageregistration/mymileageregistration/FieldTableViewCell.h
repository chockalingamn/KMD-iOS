//
//  FieldTableViewCell.h
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol FieldTableViewCellDelegate;

@interface FieldTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UIButton *actionButton;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UILabel *placeHolder;
@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;

@property (nonatomic, strong) NSString *theKey;
@property id <FieldTableViewCellDelegate> delegate;

@end


@protocol FieldTableViewCellDelegate <NSObject>

@optional
- (void)fieldTableViewDidUpdateText:(NSString *)value forKey:(NSString *)key tag:(NSInteger)tag;

@end