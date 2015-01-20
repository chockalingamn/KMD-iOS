#import "KMDDateCell.h"


@implementation KMDDateCell
{
    IBOutlet UIView *_rootView;

    IBOutlet UILabel *_dateLabel;

    IBOutlet UILabel *_internalTitleLabel;
}

@synthesize date = _date;
@synthesize dateFormatter = _dateFormatter;

@synthesize titleLabel = _titleLabel;
@synthesize dateLabel = _dateLabel;
@synthesize associatedLaterDateCell = _associatedLaterDateCell;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder])
    {
        _date = [NSDate date];
        _dateFormatter = [[NSDateFormatter alloc] init];

        static UINib *__nib;

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            __nib = [UINib nibWithNibName:@"KMD.bundle/KMDDateCell" bundle:nil];
        });

        [__nib instantiateWithOwner:self options:nil];

        _rootView.frame = self.contentView.bounds;
        [self.contentView insertSubview:_rootView atIndex:0];

        // If a title label has been set externally we don't need the
        // build-in label.

        if (_titleLabel)
        {
            [_internalTitleLabel removeFromSuperview];
            _internalTitleLabel = nil;
        }
        else
        {
            _titleLabel = _internalTitleLabel;
        }
    }

    return self;
}


- (void)setDate:(NSDate *)date
{
    if (![date isEqualToDate:_date])
    {
        _date = date;
        _dateLabel.text = [_dateFormatter stringFromDate:date];
    }
}


- (void)setDateFormatter:(NSDateFormatter *)dateFormatter
{
    _dateFormatter = dateFormatter;
    _dateLabel.text = [dateFormatter stringFromDate:_date];
}


- (void)becomeFirstResponderWithDatePicker:(UIDatePicker *)datePicker
{
    self.inputView = datePicker;
    
    [self becomeFirstResponder];

    #define ALL_TARGETS nil
    #define ALL_ACTIONS NULL

    [datePicker removeTarget:ALL_TARGETS action:ALL_ACTIONS forControlEvents:UIControlEventAllEvents];

    [datePicker addTarget:self action:@selector(dateDidChange:) forControlEvents:UIControlEventValueChanged];
    
    [datePicker setDate:_date animated:YES];
}


- (void)dateDidChange:(UIDatePicker *)datePicker
{
    self.date = [datePicker.date copy];
    
    if (_associatedLaterDateCell) 
    {
        if ([_associatedLaterDateCell.date compare:self.date] < 0) _associatedLaterDateCell.date = self.date;
    }
}

@end
