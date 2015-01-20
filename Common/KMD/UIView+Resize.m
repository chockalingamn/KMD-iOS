#import "UIView+Resize.h"


@implementation UIView (Resize)

- (CGSize)size
{
    return self.frame.size;
}


- (void)setSize:(CGSize)size
{
    CGPoint origin = self.frame.origin;
    self.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
}


- (CGPoint)origin
{
    return self.frame.origin;
}


- (void)centerInParentHorizontally:(BOOL)horizontally vertically:(BOOL)vertically
{
    [self centerInParentHorizontally:horizontally vertically:vertically snapToIntegralPosition:YES];
}


- (void)centerInParentHorizontally:(BOOL)horizontally vertically:(BOOL)vertically snapToIntegralPosition:(BOOL)snapToIntegralPosition
{
    UIView *superview = self.superview;
    
    if (superview)
    {
        if (horizontally)
        {
            self.x = superview.width / 2.0 - self.width / 2.0;
        }
        
        if (vertically)
        {
            self.y = superview.height / 2.0 - self.height / 2.0;
        }
        
        if (snapToIntegralPosition)
        {
            self.x = round(self.x);
            self.y = round(self.y);
        }
    }
}


- (void)setOrigin:(CGPoint)origin
{
    CGSize size = self.frame.size;
    self.frame = CGRectMake(origin.x, origin.y, size.width, size.height);
}


- (CGFloat)height
{
    return self.size.height;
}


- (void)setHeight:(CGFloat)height
{
    self.size = CGSizeMake(self.width, height);
}


- (CGFloat)width
{
    return self.size.width;
}


- (void)setWidth:(CGFloat)width
{
    self.size = CGSizeMake(width, self.height);
}


- (CGFloat)x
{
    return self.origin.x;
}


- (void)setX:(CGFloat)x
{
    self.origin = CGPointMake(x, self.origin.y);
}


- (CGFloat)y
{
    return self.origin.y;
}


- (void)setY:(CGFloat)y
{
    self.origin = CGPointMake(self.origin.x, y);
}


- (CGFloat)right
{
    return self.x + self.width;
}


- (void)setRight:(CGFloat)right
{
    self.x = right - self.width;
}


- (CGFloat)bottom
{
    return self.y + self.height;
}


- (void)setBottom:(CGFloat)bottom
{
    self.y = bottom - self.height;
}

@end
