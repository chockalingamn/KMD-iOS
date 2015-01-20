//
//  ReloginHelper.h
//  KMD Common
//
//  Created by Henning Böttger on 21/12/12.
//  Copyright (c) 2012 KMD A/S. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KMDLoginViewController.h"

@interface ReloginHelper : NSObject <KMDLoginViewControllerDelegate>

- (id)initWithViewController:(UIViewController *)callingViewController;

- (void)requestLogin:(void (^)())success cancelled:(void (^)())cancelled;

@end
