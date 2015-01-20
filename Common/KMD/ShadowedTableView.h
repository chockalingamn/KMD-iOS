#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@interface ShadowedTableView : UITableView
{
	CAGradientLayer *originShadow;
	CAGradientLayer *topShadow;
	CAGradientLayer *bottomShadow;
}

@end
