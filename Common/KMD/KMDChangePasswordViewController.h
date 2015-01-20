//
//  KMDChangePasswordViewController.h
//  KMD Common
//
//  Created by Henning Böttger on 21/11/12.
//  Copyright (c) 2012 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KMDLoginViewController.h"

@interface KMDChangePasswordViewController : UITableViewController <UITextFieldDelegate>

/// If set this image will be used for the view's background for every new instance created.
///
+ (void)setBackgroundImage:(UIImage *)image;

/// The application name to identify itself with to the server.
///
+ (void)setApplicationName:(NSString *)applicationName;

@property (nonatomic, weak) id<KMDLoginViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *pinCode;

@property (nonatomic, weak) IBOutlet UITextField *_currentPasswordTextField;
@property (nonatomic, weak) IBOutlet UITextField *_aNewPasswordTextField;
@property (nonatomic, weak) IBOutlet UITextField *_retypedNewPasswordTextField;

@end
