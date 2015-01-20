//
//  AppDelegate.h
//  mymileageregistration
//
//  Created by Per Friis on 26/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import CoreLocation;
@import CoreData;
#import <UIKit/UIKit.h>
#import "KMDMileage+utility.h"

static NSString *const kDatabaseIsReadyNotification = @"databaseIsReadyNotification";

@interface AppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate>
@property (nonatomic, readonly) UIManagedDocument *managedDocument;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) CLLocationManager *locationManager;
@property (nonatomic, strong) NSOperationQueue *downloadQueue;
@property (nonatomic, readonly) BOOL sessionTimeOut;

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) KMDMileage *editedMileage;

- (void)logout;
- (void)saveManagedDocument;
@end

