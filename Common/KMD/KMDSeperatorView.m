//
//  KMDSeperatorView.m
//  KMD Common
//
//  Created by Thomas Børlum on 6/3/12.
//  Copyright (c) 2012 Trifork Public A/S. All rights reserved.
//

#import "KMDSeperatorView.h"

@implementation KMDSeperatorView

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    
    if (highlighted)
    {
        self.backgroundColor = UIColor.blackColor;
    }
    else
    {
        self.backgroundColor = UIColor.grayColor;
    }
}

@end
