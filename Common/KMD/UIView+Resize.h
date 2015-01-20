//
//  UIView+Resize.h
//  Menu
//
//  Created by Thomas Børlum on 1/26/12.
//  Copyright (c) 2012 Trifork Public A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (Resize)

- (CGSize)size;
- (void)setSize:(CGSize)size;

- (CGPoint)origin;
- (void)setOrigin:(CGPoint)origin;

- (CGFloat)width;
- (void)setWidth:(CGFloat)width;

- (CGFloat)height;
- (void)setHeight:(CGFloat)height;

- (CGFloat)x;
- (void)setX:(CGFloat)x;

- (CGFloat)y;
- (void)setY:(CGFloat)y;

- (CGFloat)right;
- (void)setRight:(CGFloat)right;

- (CGFloat)bottom;
- (void)setBottom:(CGFloat)bottom;

- (void)centerInParentHorizontally:(BOOL)horizontally vertically:(BOOL)vertically;
- (void)centerInParentHorizontally:(BOOL)horizontally vertically:(BOOL)vertically snapToIntegralPosition:(BOOL)snapToIntegralPosition;

@end
