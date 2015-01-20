#import <UIKit/UIKit.h>

#import "KMDTableViewCell.h"


@interface KMDInputTableViewCell : KMDTableViewCell <UIKeyInput>

@property (nonatomic, strong) UIView *inputView;
@property (nonatomic, strong) UIView *inputAccessoryView;

@end
