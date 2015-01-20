#import <UIKit/UIKit.h>

#import "KMDInputTableViewCell.h"


@interface KMDDateCell : KMDInputTableViewCell

@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong, readonly) UILabel *dateLabel;
@property (nonatomic, weak) KMDDateCell *associatedLaterDateCell;


- (void)becomeFirstResponderWithDatePicker:(UIDatePicker *)datePicker;

@end
