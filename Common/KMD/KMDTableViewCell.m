#import "KMDTableViewCell.h"

#import <QuartzCore/QuartzCore.h>

#import "KMDRouindedTableView.h"


@implementation KMDTableViewCell

- (void)updateSelectedBackground:(NSIndexPath *)indexPath
{
    UITableView *tableView = (UITableView *)self.superview;
    
    if ([tableView isKindOfClass:KMDRouindedTableView.class])
    {
        UIRectCorner roundedCorners = 0;
        
        NSInteger numRows = ([tableView numberOfRowsInSection:indexPath.section]);
        
        if (indexPath.row == 0)
        {
            roundedCorners = UIRectCornerTopLeft|UIRectCornerTopRight; 
        }
        
        if (indexPath.row == numRows - 1)
        {
            roundedCorners |= UIRectCornerBottomLeft|UIRectCornerBottomRight;
        }
        
        
        CGRect bounds = self.backgroundView.bounds;
        bounds = CGRectInset(bounds, 1, 0);
        
        CAShapeLayer *shape = [CAShapeLayer layer];
        shape.path = [[UIBezierPath bezierPathWithRoundedRect:bounds byRoundingCorners:roundedCorners cornerRadii:CGSizeMake(10, 10)] CGPath];
        shape.strokeColor = UIColor.blackColor.CGColor;
        shape.lineWidth = 1;
        shape.fillColor = [[UIColor colorWithRed:0.3 green:0.532 blue:0.33 alpha:1] CGColor];
        
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView.layer insertSublayer:shape atIndex:0];
        bgColorView.frame = bounds;
        
        self.selectedBackgroundView = bgColorView;
    }
    else
    {
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = self.bounds;
        gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0.2 green:0.432 blue:0.23 alpha:1] CGColor], (id)[[UIColor colorWithRed:0.182 green:0.432 blue:0.19 alpha:1]CGColor], nil];
        
        UIView *bgColorView = [[UIView alloc] init];
        [bgColorView.layer insertSublayer:gradient atIndex:0];
        
        self.selectedBackgroundView = bgColorView;
    }
}

@end
