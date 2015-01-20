//
//  KMDMileageTableViewCell.h
//  mymileageregistration
//
//  Created by Per Friis on 09/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import MapKit;

#import <UIKit/UIKit.h>

@interface KMDMileageTableViewCell : UITableViewCell
@property (nonatomic, weak) IBOutlet UITextField *textField;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UILabel *textViewPlaceholderLabel;
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;


@end
