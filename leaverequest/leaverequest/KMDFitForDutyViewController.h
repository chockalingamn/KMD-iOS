//
//  KMDFitForDutyViewController.h
//  leaverequest
//
//  Created by Per Friis on 10/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Absence+KMD.h"

@protocol KMDFitForDutyViewControllerDelegate;

@interface KMDFitForDutyViewController : UIViewController
@property (nonatomic, assign) id <KMDFitForDutyViewControllerDelegate> delegate;
@property (nonatomic, strong) Absence *absence;
@property (nonatomic, strong) UIImage *backGroundImage;
@end


@protocol KMDFitForDutyViewControllerDelegate <NSObject>
/**
 * The only way to leave the "fit for duty" report, is to select a date and tap done
 * @param fitForDutyViewController The modal view controller you need to dismiss
 * @param fitForDutyDate The selected date
 */
- (void) fitForDutyViewController:(KMDFitForDutyViewController *)fitForDutyViewController didSelectDate:(NSDate *)fitForDutyDate;

@end