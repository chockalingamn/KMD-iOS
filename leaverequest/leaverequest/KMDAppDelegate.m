//
//  KMDAppDelegate.m
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//
@import CoreData;

#import "KMD/KMDLoginViewController.m"
#import "KMDAppDelegate.h"
#import "Absence+KMD.h"
#import "KMDChildrenREST.h"
#import "KMDWorkInjuryREST.h"
#import "KMDReasonREST.h"
#import "KMDMaternityREST.h"

#define SESSION_TIMEOUT 30*60

@interface KMDAppDelegate() <KMDLoginViewControllerDelegate>
@property (nonatomic, strong) NSURL *databaeFileURL;
@property (nonatomic, strong) UIManagedDocument *managedDocument;
@property (nonatomic, readwrite) BOOL databaseReady;
@end

@implementation KMDAppDelegate
-(NSManagedObjectContext *)managedObjectContext{
    if (self.databaseReady) {
        return self.managedDocument.managedObjectContext;
    }
    return nil;
}
- (NSDate *)fetchFromDate{
    return [[NSUserDefaults standardUserDefaults] objectForKey:KEY_FETCH_FROM_DATE];
}

- (BOOL)sessionTimeOut{
    NSTimeInterval timeinterval = fabs([[[User currentUser] lastRequestToServer] timeIntervalSinceNow]) - SESSION_TIMEOUT;
    
    if (timeinterval < 0) {
        return NO;
    }
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self logout:nil];
        
        
        NSString *title = @"Din session er udløbet";
        NSString *message = @"så du er blevet logget ud af systemte, logind igen for at fortsætte";
        
        if ([UIAlertController class]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [alertController dismissViewControllerAnimated:YES completion:nil];
            }]];
            
            [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        }
    }];
    
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([[[UIDevice currentDevice] systemVersion] integerValue] < 7) {
        [[UINavigationBar appearance] setTintColor:KMD_GRAY];
    }
    [[UINavigationBar appearance] setTintColor:KMD_DARK_GREEN];
    [[UIButton appearance] setTintColor:KMD_DARK_GREEN];
    
    
    
    // create or open document
    self.databaseReady = NO; // must be no at this point
    self.managedDocument = [[UIManagedDocument alloc] initWithFileURL:self.databaeFileURL];
    
    // start with login
    [KMDLoginViewController setApplicationName:@"LeaveRequest"];
    
    
    UIImage *backgroundImage;
    
    if ([[UIScreen mainScreen] bounds].size.height == 568) {
        backgroundImage = [UIImage imageNamed:@"logon-background@r4"];
    } else {
        backgroundImage = [UIImage imageNamed:@"logon-background"];
    }
    
    [KMDLoginViewController setBackgroundImage:backgroundImage];
    [KMDLoginViewController setTitle:@"Mit Fravær" ];
    
    UINavigationController *navController = [KMDLoginViewController createInstanceEmbeddedInNavigationViewController];
    KMDLoginViewController *loginViewController = [navController.viewControllers objectAtIndex:0];
    
    loginViewController.delegate = self;
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    self.window.rootViewController = navController;
    
    
    return YES;
}

#pragma mark - Login View Controller
- (void)loginSuccessful:(KMDLoginViewController *)loginViewController user:(User *)user
{
    user.lastRequestToServer = [NSDate date];
    [self setFromMonth:-2];
    // load and cache data lists
    [[KMDReasonREST sharedInstance] fetchFromBackEnd];
    [[KMDChildrenREST sharedInstance] fetchFromBackEnd];
    [[KMDMaternityREST sharedInstance] fetchFromBackEnd];
    [[KMDWorkInjuryREST sharedInstance] fetchFromBackEnd];
    
    
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    
    [UIView transitionFromView:self.window.rootViewController.view toView:rootViewController.view duration:1 options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
        
        _window.rootViewController = rootViewController;
    }];
}


- (IBAction)logout:(id)sender{
    [Absence cleanAbsenceTableInManagedObjectContext:self.managedObjectContext];
    [self setFromMonth:-2];
    
    
    
    UINavigationController *navController = [KMDLoginViewController createInstanceEmbeddedInNavigationViewController];
    
    KMDLoginViewController *loginViewController = [navController.viewControllers objectAtIndex:0];
    loginViewController.delegate = self;
    
    [UIView transitionFromView:self.window.rootViewController.view toView:navController.view duration:0.75f options:UIViewAnimationOptionTransitionFlipFromRight completion:^(BOOL finished) {
        _window.rootViewController = navController;
    }];
}

@synthesize databaeFileURL = _databaeFileURL;
-(NSURL *)databaeFileURL{
    if (!_databaeFileURL) {
        _databaeFileURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]lastObject];
        _databaeFileURL = [_databaeFileURL URLByAppendingPathComponent:@"leaverequest"];
    }
    return _databaeFileURL;
}

-(void)setManagedDocument:(UIManagedDocument *)managedDocument{
    if (_managedDocument != managedDocument) {
        _managedDocument = managedDocument;
        _managedDocument.persistentStoreOptions = @{NSMigratePersistentStoresAutomaticallyOption:@1,
                                                    NSInferMappingModelAutomaticallyOption:@1};
        if (![[NSFileManager defaultManager] fileExistsAtPath:_managedDocument.fileURL.path]) {
            [_managedDocument saveToURL:_managedDocument.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                if (success) {
                    [self startUsingDocument];
                } else {
                    [self managedDocumentError];
                }
            }];
        } else if (_managedDocument.documentState == UIDocumentStateClosed){
            [_managedDocument openWithCompletionHandler:^(BOOL success) {
                if (success) {
                    [self startUsingDocument];
                } else {
                    [self managedDocumentError];
                }
            }];
        } else if (_managedDocument.documentState == UIDocumentStateNormal){
            [self startUsingDocument];
        } else {
            [self managedDocumentError];
        }
    }
}

-(void)startUsingDocument{
    
    [Absence cleanAbsenceTableInManagedObjectContext:self.managedDocument.managedObjectContext];
    
    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
    
    self.databaseReady = YES;
    
    // let the rest know that the database is ready to be used
    [[NSNotificationCenter defaultCenter] postNotificationName:kKMDDatabaseIsReady object:self];
}

- (void)managedDocumentError{
    
}


- (NSDate *)setFromMonth:(NSInteger)month{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components: NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    
    components.month += month;
    NSDate *date = [calendar dateFromComponents:components];
    
    [[NSUserDefaults standardUserDefaults] setObject:date forKey:KEY_FETCH_FROM_DATE];
    [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithInteger:month] forKey:@"monthDelta"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    
    return date;
}

- (NSDate *)addFromMonth:(NSInteger)month{
    NSInteger delta = [[[NSUserDefaults standardUserDefaults] valueForKey:@"monthDelta"] integerValue];
    delta += month;
    return [self setFromMonth:delta];
}

@end
