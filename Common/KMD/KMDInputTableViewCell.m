//
//  KMDInputTableViewCell.m
//  KMD Common
//
//  Created by Thomas Børlum on 5/3/12.
//  Copyright (c) 2012 Trifork Public A/S. All rights reserved.
//

#import "KMDInputTableViewCell.h"

@implementation KMDInputTableViewCell

@synthesize inputView = _inputView;
@synthesize inputAccessoryView = _inputAccessoryView;


- (BOOL)hasText
{
    return YES;
}


- (void)insertText:(NSString *)theText { }


- (void)deleteBackward { }


- (BOOL)canBecomeFirstResponder
{
    return YES;
}

@end
