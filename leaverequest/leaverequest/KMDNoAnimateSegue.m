//
//  KMDNoAnimateSegue.m
//  leaverequest
//
//  Created by Per Friis on 29/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDNoAnimateSegue.h"

@implementation KMDNoAnimateSegue

-(void)perform{
    [[self.sourceViewController navigationController] pushViewController:self.destinationViewController animated:NO];
}


@end
