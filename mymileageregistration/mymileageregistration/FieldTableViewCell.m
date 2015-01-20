//
//  FieldTableViewCell.m
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import "FieldTableViewCell.h"
@interface FieldTableViewCell() <UITextViewDelegate, UITextFieldDelegate>
@end


@implementation FieldTableViewCell
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}


- (void)textViewDidChange:(UITextView *)textView{
    if (self.placeHolder.alpha > 0 && textView.text.length > 0) {
        [UIView animateWithDuration:0.25f animations:^{
            self.placeHolder.alpha = 0;
        }];
    } else if (self.placeHolder.alpha == 0 && textView.text.length == 0){
        [UIView animateWithDuration:0.25f animations:^{
            self.placeHolder.alpha = 1;
        }];
    }
}


- (IBAction)datePickerChanged:(UIDatePicker *)sender{
    
}

@end
