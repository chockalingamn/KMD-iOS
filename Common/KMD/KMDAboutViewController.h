//
//  KMDAboutViewController.h
//  KMD Common
//
//  Created by Henning Böttger on 17/05/13.
//  Copyright (c) 2013 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface KMDAboutViewController : UITableViewController

/// If set this image will be used for the view's background for every new instance created.
///
+ (void)setBackgroundImage:(UIImage *)image;

@property (nonatomic, weak) IBOutlet UITextView *appDescriptionTextView;
@property (nonatomic, weak) IBOutlet UILabel *appSupportNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *appSupportVersionLabel;

@end
