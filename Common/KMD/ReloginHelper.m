//
//  ReloginHelper.m
//  KMD Common
//
//  Created by Henning Böttger on 21/12/12.
//  Copyright (c) 2012 KMD A/S. All rights reserved.
//

#import "ReloginHelper.h"

typedef void (^LoginCallback)();

@interface ReloginHelper ()

@property (nonatomic, copy) LoginCallback loginSuccessBlock;
@property (nonatomic, copy) LoginCallback loginCancelledBlock;

@end

@implementation ReloginHelper
{
    __weak UIViewController *_callingViewController;
}

- (id)initWithViewController:(UIViewController *) callingViewController
{
    if (self = [super init])
    {
        _callingViewController = callingViewController;
    }
    return self;
}

- (void)requestLogin:(void (^)())success cancelled:(void (^)())cancelled
{
    UINavigationController *navigationController = [KMDLoginViewController createInstanceEmbeddedInNavigationViewController];
    KMDLoginViewController *loginController = [navigationController.viewControllers objectAtIndex:0];

    loginController.delegate = self;
    loginController.isCancelButtonVisible = YES;
    
    self.loginSuccessBlock = success;
    self.loginCancelledBlock = cancelled;
    
    [_callingViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)loginSuccessful:(KMDLoginViewController *)loginViewController user:(User *)user
{
    [_callingViewController dismissViewControllerAnimated:YES completion:nil];
    if (self.loginSuccessBlock) self.loginSuccessBlock();
}

- (void)loginCancelled:(KMDLoginViewController *)loginViewController
{
    [_callingViewController dismissModalViewControllerAnimated:YES];
    if (self.loginCancelledBlock) self.loginCancelledBlock();
}


@end
