//
//  AppDelegate.m
//  mymileageregistration
//
//  Created by Per Friis on 26/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import CoreData;
#import "KMDMileage+utility.h"
#import "V130Registration.h"

#import "KMD/KMDLoginViewController.m"
#import "KMD/Errors.h"

#import "AppDelegate.h"
#define SESSION_TIMEOUT 30*60
// half hour time out

@interface AppDelegate () <KMDLoginViewControllerDelegate>


@property (nonatomic, strong) NSManagedObjectContext        *managedObjectContext130;
@property (nonatomic, strong) NSManagedObjectModel          *managedObjectModel130;
@property (nonatomic, strong) NSPersistentStoreCoordinator  *persistentStoreCoordinator130;


@property (nonatomic, strong) UIManagedDocument     *managedDocument;
@property (nonatomic, readonly) NSURL               *databaseFileUrl;
@property (nonatomic, readonly) NSURL               *iCloudURL;
@property (nonatomic, strong) CLLocationManager     *locationManager;

@end

@implementation AppDelegate
- (NSManagedObjectContext *)managedObjectContext{
    return self.managedDocument.managedObjectContext;
}

- (CLLocationManager *)locationManager{
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }
    }
    return _locationManager;
}


- (NSOperationQueue *)downloadQueue{
    if (!_downloadQueue) {
        _downloadQueue = [[NSOperationQueue alloc] init];
        
    }
    return _downloadQueue;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(undoCheck:) name:NSUndoManagerCheckpointNotification object:nil];
    
    
    
    
    [[UIButton appearance] setTintColor:KMD_DARK_GREEN];
    [[UINavigationBar appearance] setTintColor:KMD_DARK_GREEN];
//    [[UINavigationBar appearance] setBarTintColor:KMD_LIGHT_GREEN];
    [[UIPickerView appearance] setTintColor:KMD_DARK_GREEN];
    [[UIDatePicker appearance] setTintColor:KMD_DARK_GREEN];
        
    // set the version in the description
    NSString *versionString = [NSString stringWithFormat:@"%@ build:%@",
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"],
                               [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]];
    
    [[NSUserDefaults standardUserDefaults] setObject:versionString forKey:@"version"];
    
    
    // login
    // start with login
    [KMDLoginViewController setApplicationName:@"LeaveRequest"];
    
    // TODO: handle background image
    UIImage *backgroundImage;
    
    if ([[UIScreen mainScreen] bounds].size.height == 568) {
        backgroundImage = [UIImage imageNamed:@"logon-background@r4"];
    } else {
        backgroundImage = [UIImage imageNamed:@"logon-background"];
    }
    
    [KMDLoginViewController setBackgroundImage:backgroundImage];
    [KMDLoginViewController setTitle:@"Min Kørsel" ];
    
    UINavigationController *navController = [KMDLoginViewController createInstanceEmbeddedInNavigationViewController];
    KMDLoginViewController *loginViewController = [navController.viewControllers objectAtIndex:0];
    
    loginViewController.delegate = self;
    
    self.window.rootViewController = navController;
    
    self.managedDocument = [[UIManagedDocument alloc] initWithFileURL:self.databaseFileUrl];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.managedObjectContext save:nil];
    [self saveManagedDocument];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}



#pragma mark - Delegate
#pragma mark Login ViewController



- (void)loginSuccessful:(UIViewController *)viewController user:(User *)user{
    user.lastRequestToServer = [NSDate date];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    UIViewController *rootViewController = [storyboard instantiateInitialViewController];
    
    [UIView transitionFromView:self.window.rootViewController.view toView:rootViewController.view duration:0.75f options:UIViewAnimationOptionTransitionFlipFromLeft completion:^(BOOL finished) {
        
        _window.rootViewController = rootViewController;
        
    }];
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"submitError != nil"];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    [fetchedObjects enumerateObjectsUsingBlock:^(KMDMileage *mileage, NSUInteger idx, BOOL *stop) {
        mileage.submitError = nil;
    }];
    
}

- (void)loginCancelled:(UIViewController *)viewController{
    
}

- (BOOL)sessionTimeOut{
    NSTimeInterval timeinterval = fabs([[[User currentUser] lastRequestToServer] timeIntervalSinceNow]) - SESSION_TIMEOUT;
    
    
    if (timeinterval < 0) {
        return NO;
    }
    
    [self logout];
    
    NSString *title = @"Din session er udløbet";
    NSString *message = @"så du er blevet logget ud af systemte, logind igen for at fortsætte";
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
    [alertView show];
    
    return YES;
}

#pragma mark - Logout
- (void)logout{
    [self.downloadQueue cancelAllOperations];
    
    // clear if nessary
    UINavigationController *navController = [KMDLoginViewController createInstanceEmbeddedInNavigationViewController];
    
    KMDLoginViewController *loginViewController = [navController.viewControllers objectAtIndex:0];
    loginViewController.delegate = self;
    
    [UIView transitionFromView:self.window.rootViewController.view toView:navController.view duration:0.75f options:UIViewAnimationOptionTransitionFlipFromRight completion:^(BOOL finished) {
        _window.rootViewController = navController;
    }];
    
}


#pragma mark - Coredata / Managed Document handling

#pragma mark - UImanagedDocument
@synthesize databaseFileUrl = _databaseFileUrl;

- (NSURL *)databaseFileUrl{
    if (!_databaseFileUrl) {
        // use iCloud if avalible
        _databaseFileUrl = self.iCloudURL;
        if (!_databaseFileUrl) {
            _databaseFileUrl = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]lastObject];
        }
        _databaseFileUrl = [_databaseFileUrl URLByAppendingPathComponent:@"mileageregistrations.database"];
    }
    return _databaseFileUrl;
}

- (NSURL *)iCloudURL {
    return [[NSFileManager defaultManager] URLForUbiquityContainerIdentifier:nil];
}

- (void)setManagedDocument:(UIManagedDocument *)managedDocument {
    if (_managedDocument != managedDocument) {
        _managedDocument = managedDocument;
        
        NSMutableDictionary *persistentStoreOptions = [[NSMutableDictionary alloc] init];
        [persistentStoreOptions setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
        [persistentStoreOptions setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
        
        if (self.iCloudURL) {
            [persistentStoreOptions setObject:@"mileageregistrations" forKey:NSPersistentStoreUbiquitousContentNameKey ];
            [persistentStoreOptions setObject:[self.iCloudURL URLByAppendingPathComponent:@"CoreDataLog"] forKey:NSPersistentStoreUbiquitousContentURLKey];
        }
        
        _managedDocument.persistentStoreOptions = persistentStoreOptions;
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

- (void)startUsingDocument {
    NSURL *storeURL =  [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DriverRegistration_v2.sqlite"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:storeURL.path]){
        [self convertFrom130To200];
    }
    
    self.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
    
    
  //  self.managedDocument.managedObjectContext.undoManager = [[NSUndoManager alloc] init];
// FIXME: get the undo manager to work if it is nessary, currently it only stops the database from beeing persistant
    
    // Listen for changes in the database, iCloud or locally
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(persistentStoreDidChange:)
                                                name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(managedDocumentStateChanged:) name:UIDocumentStateChangedNotification object:self.managedDocument];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(managedObjectChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedDocument.managedObjectContext];
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDatabaseIsReadyNotification object:self];
    
}

- (void)managedDocumentError {
    if (self.managedDocument.documentState == UIDocumentStateNormal) {
        
        [self.managedDocument closeWithCompletionHandler:^(BOOL success) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:[self.managedDocument.fileURL path]]) {
                [[NSFileManager defaultManager] removeItemAtPath:[self.managedDocument.fileURL path] error:nil];
                
                self.managedDocument = [[UIManagedDocument alloc] initWithFileURL:self.databaseFileUrl];
            }
        }];
    } else {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self.managedDocument.fileURL path]]) {
            [[NSFileManager defaultManager] removeItemAtPath:[self.managedDocument.fileURL path] error:nil];
            self.managedDocument = [[UIManagedDocument alloc] initWithFileURL:self.databaseFileUrl];
            
        }
    }
}

- (void)persistentStoreDidChange:(NSNotification *) notification {
    [self.managedDocument.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}

- (void)managedDocumentStateChanged:(NSNotification *)notification {
    NSLog(@"%s %@",__PRETTY_FUNCTION__,notification);
}

- (void)managedObjectChange:(NSNotification *)notification{
    if (![notification.userInfo[NSDeletedObjectsKey] isKindOfClass:[NSNull class]]) {
    }
    if (![notification.userInfo[NSUpdatedObjectsKey] isKindOfClass:[NSNull class]]){
    }
    
    if (![notification.userInfo[NSInsertedObjectsKey] isKindOfClass:[NSNull class]]) {
    }
}


#pragma mark - Core Data stack version 1.3.0
- (void)convertFrom130To200{
    // this is nessary as the usage paradime is changed from obsolite coredata implementing with a created persisten store coordinator, to a more furture safe version, using UIManagedDocument, the new implementation also supports iCloud implementation
    
    [self.managedDocument.managedObjectContext performBlock:^{

        // copy download til ny database
        
        [self convertRegistrationToMileage];

        NSURL *storeURL =  [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DriverRegistration_v2.sqlite"];
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        
    }];
}

- (void)deleteEntities:(NSString *)entityName{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    NSArray *fetchedObjects = [self.managedDocument.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    [fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self.managedDocument.managedObjectContext deleteObject:obj];
    }];
}

- (void)convertRegistrationToMileage{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Registration"];
    
    NSArray *registrations = [self.managedObjectContext130 executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        return;
    }
    
    if (registrations) {
        [registrations enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            V130Registration *registration = obj;
            if (!registration.isSent.boolValue) {
                KMDMileage *mileage = [KMDMileage newMileageInManagedContext:self.managedObjectContext];
                mileage.endAddress      = registration.destination;
                mileage.startAddress    = registration.origin;
                mileage.isSent          = registration.isSent;
                mileage.reason          = registration.reason;
                mileage.templateID      = registration.templateID;
                mileage.templateName    = registration.templateName;
                mileage.depatureTimestamp = registration.tripDate;
                mileage.distanceOfTripInKilometers = registration.tripDistanceInKilometers;
                mileage.username        = registration.username;
                mileage.vehicleRegistrationNumber = registration.vehicleRegistrationNumber;
            }
        }];
    }
}

- (void)convertEntity:(NSString *)entityName{
    NSError *error;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    
    NSArray *oldEntity = [self.managedObjectContext130 executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    
    if (oldEntity) {
        for (NSManagedObject *oldRegistration in oldEntity) {
            
            NSManagedObject *newRegistration = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.managedDocument.managedObjectContext];
            [oldRegistration.entity.attributesByName enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if ([newRegistration.entity.propertiesByName objectForKey:key]) {
                    [newRegistration setValue:[oldRegistration valueForKey:key] forKey:key];
                }
            }];
        }
    }
}


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext130
{
    if (_managedObjectContext130 != nil)
    {
        return _managedObjectContext130;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator130];
    if (coordinator != nil)
    {
        _managedObjectContext130 = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext130 setPersistentStoreCoordinator:coordinator];
    }
    
    return _managedObjectContext130;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel130
{
    if (_managedObjectModel130 != nil){
        return _managedObjectModel130;
    }
    
    // note: select the first version of the database model, regardless of the currente version
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"DriverRegistration" ofType:@"mom" inDirectory:@"DriverRegistration.momd"];
    
    
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    _managedObjectModel130 = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel130;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator130
{
    if (_persistentStoreCoordinator130 != nil) return _persistentStoreCoordinator130;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"DriverRegistration_v2.sqlite"];
    
    NSError *error = nil;
    
    _persistentStoreCoordinator130 = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel130]];
    if (![_persistentStoreCoordinator130 addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    
    return _persistentStoreCoordinator130;
}


#pragma mark - Legacy Core Data
+ (NSManagedObjectContext *)createSandboxManagedObjectContext
{
    NSManagedObjectContext *sandboxContext = [[NSManagedObjectContext alloc] init];
    sandboxContext.persistentStoreCoordinator = self.globalManagedObjectContext.persistentStoreCoordinator;
    
    [NSNotificationCenter.defaultCenter addObserverForName:NSManagedObjectContextDidSaveNotification object:sandboxContext queue:nil usingBlock:^(NSNotification *notification) {
        
        [AppDelegate mergeChangesIntoGlobalContext:notification];
    }];
    
    return sandboxContext;
}

+ (NSManagedObjectContext *)createTemplateManagedObjectContext
{
    NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] init];
    newContext.persistentStoreCoordinator = self.globalManagedObjectContext.persistentStoreCoordinator;
    return newContext;
}

+ (NSManagedObjectContext *)globalManagedObjectContext
{
    AppDelegate *appDelegate = (AppDelegate *)UIApplication.sharedApplication.delegate;
    return appDelegate.managedObjectContext130;
}


+ (void)mergeChangesIntoGlobalContext:(NSNotification *)notification
{
    // This is a separate method to avoid problems with blocks and 'self' references.
    
    [self.globalManagedObjectContext mergeChangesFromContextDidSaveNotification:notification];
}


#pragma mark - Application's Documents directory


- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)saveManagedDocument{
    [self.managedDocument saveToURL:self.databaseFileUrl forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {}];
}


- (void)undoCheck:(NSNotification *)notification{
    NSLog(@"%s - %@",__PRETTY_FUNCTION__,notification);
}


@end
