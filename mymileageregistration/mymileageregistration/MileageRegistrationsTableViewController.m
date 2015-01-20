//
//  MileageRegistrationsTableViewController.m
//  mymileageregistration
//
//  Created by Per Friis on 27/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import CoreData;
@import CoreLocation;

#import "MileageRegistrationsTableViewController.h"
#import "MileageRegistrationViewController.h"

//#import "KMD/KMDLoginViewController.m"

#import "KMDMileage+utility.h"
#import "KMDIntermidiatePoint+utility.h"
#import "KMDTemplate+utility.h"
#import "MileageTableViewCell.h"

typedef NS_ENUM(NSInteger, actionSheetType){
    actionSheetNewRegistration
};

@interface MileageRegistrationsTableViewController () <NSFetchedResultsControllerDelegate,UIActionSheetDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, readonly) AppDelegate *appDelegate;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly) CLLocationManager *locationManager;
@end

@implementation MileageRegistrationsTableViewController
#pragma mark - properties
#pragma mark readonly
- (AppDelegate *)appDelegate{
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (NSManagedObjectContext *)managedObjectContext{
    return self.appDelegate.managedDocument.managedObjectContext;
}

#pragma mark lazy instantiate

- (NSFetchedResultsController *)fetchedResultsController{
    if (!_fetchedResultsController && self.managedObjectContext) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"username = %@",[[User currentUser] username]];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"isSent" ascending:YES],
                                         [NSSortDescriptor sortDescriptorWithKey:@"status" ascending:NO],
                                         [NSSortDescriptor sortDescriptorWithKey:@"depatureTimestamp" ascending:NO]];
        
        NSError *error = nil;
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"isSent" cacheName:nil];
        
        [_fetchedResultsController performFetch:&error];
        if (error) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
            abort();
        }
        
        [self.tableView reloadData];
        _fetchedResultsController.delegate = self;
        
    }
    return _fetchedResultsController;
}




#pragma mark - view lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Min Kørsel";
    if (!self.managedObjectContext) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(databaseIsReady:) name:kDatabaseIsReadyNotification object:self.appDelegate];
    } else {
        [KMDTemplate updateTemplateFromBackend];
        [KMDMileage updateMileageRegistrationsFromBackend];
    }
    
    self.tableView.tableFooterView = [[UIView alloc] init];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mileageUpdated:) name:mileageDidUpdateFromBackend object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mileageFailUpdate:) name:mileageFailedTupdateFromBackend object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadFromBackend:) name:milageBackendMightHaveUpdates object:nil];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [KMDMileage cleanEmplyMileageRegistrations];
    
    
    
    
    if (self.appDelegate.editedMileage.managedObjectContext.undoManager.canUndo) {
        
        NSString *message = @"Vil du gemme dine rettelser?";
        NSString *title = @"Min Kørsel";
        
        if ([self.appDelegate.editedMileage.status isEqualToString:@"NEW"]) {
            message = @"Vil du gemme din indberetning som kladde?";
        }
        
        if ([UIAlertController class]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleActionSheet];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ja" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [self.managedObjectContext performBlock:^{
                    if ([self.appDelegate.editedMileage.status isEqualToString:@"NEW"]) {
                        self.appDelegate.editedMileage.status = nil;
                    }
                    [self.managedObjectContext.undoManager removeAllActions];
                    [self.managedObjectContext save:nil];
                    self.appDelegate.editedMileage = nil;
                }];
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Nej" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                [self.managedObjectContext performBlock:^{
                    if ([self.appDelegate.editedMileage.status isEqualToString:@"NEW"]) {
                        [self.managedObjectContext deleteObject:self.appDelegate.editedMileage];
                    } else {
                        while (self.managedObjectContext.undoManager.canUndo) {
                            [self.managedObjectContext.undoManager undo];
                        }
                        [self.managedObjectContext save:nil];
                        [self.appDelegate saveManagedDocument];
                    }
                }];
            }]];
            [self.navigationController.topViewController presentViewController:alertController animated:YES completion:nil];
            
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Nej" otherButtonTitles:@"Ja", nil];
            [alertView show];
        }
    } else if ([self.appDelegate.editedMileage.status isEqualToString:@"NEW"]) {
        [self.managedObjectContext deleteObject:self.appDelegate.editedMileage];
    }
}

#pragma mark AlertView
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0 && self.appDelegate.editedMileage) {
        [self.managedObjectContext performBlock:^{
            if ([self.appDelegate.editedMileage.status isEqualToString:@"NEW"]) {
                [self.managedObjectContext deleteObject:self.appDelegate.editedMileage];
            } else {
                while (self.managedObjectContext.undoManager.canUndo) {
                    [self.managedObjectContext.undoManager undo];
                }
                [self.managedObjectContext save:nil];
                [self.appDelegate saveManagedDocument];
            }
            self.appDelegate.editedMileage = nil;
        }];
    } else {
        [self.managedObjectContext performBlock:^{
            if ([self.appDelegate.editedMileage.status isEqualToString:@"NEW"]) {
                self.appDelegate.editedMileage.status = nil;
            }
            [self.managedObjectContext.undoManager removeAllActions];
            [self.managedObjectContext save:nil];
            [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveManagedDocument];

            self.appDelegate.editedMileage = nil;
        }];
    }
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else
        return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    KMDMileage *mileage = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    MileageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:mileage.isSent.boolValue?@"remote cell":@"local cell" forIndexPath:indexPath];
    
    
    cell.mileagePurposeLable.attributedText = mileage.displayReason;
    cell.departureDateLable.text = [[NSDateFormatter displayDateWithYear] stringFromDate:mileage.depatureTimestamp];
    cell.distanceLabel.text = [NSString stringWithFormat:@"%.2f km",mileage.distanceOfTripInKilometers.floatValue];
    
    if (mileage.submitError) {
        CGRect rect = CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), 83);
        
        if ([UIVisualEffectView class]) {
            UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
            effectView.frame = rect;
            effectView.tag = 100;
            [cell.contentView addSubview:effectView];
        } else {
            UIGraphicsBeginImageContext(rect.size);
            [self.view drawViewHierarchyInRect:rect afterScreenUpdates:YES];
            UIImage *blurBackground = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:rect];
            
            imageView.image = [blurBackground applyLightEffect];
            imageView.tag = 100; // make sure it's deletes upon cell reuse
            [cell.contentView addSubview:imageView];
        }
        
        
        
        NSMutableAttributedString *errorMessageString = [[NSMutableAttributedString alloc] init];
        
        if (mileage.isValid) {
            [errorMessageString appendAttributedString:[[NSMutableAttributedString alloc] initWithString:@"Din kørsel kunne ikke registreres\n" attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],NSForegroundColorAttributeName:[UIColor redColor]}]];
        }
        
        [errorMessageString appendAttributedString:[[NSAttributedString alloc] initWithString:mileage.submitError attributes:@{NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody],NSForegroundColorAttributeName:[UIColor blueColor]}]];
        
        UILabel *errorMessage = [[UILabel alloc] initWithFrame:CGRectInset(rect, 15.0, 8.0)];
        errorMessage.textAlignment = NSTextAlignmentCenter;
        errorMessage.numberOfLines = 0;
        errorMessage.tag = 100; // make sure it's deletes upon cell reuse
        errorMessage.attributedText = errorMessageString;
        
        [cell.contentView addSubview:errorMessage];
    } else {
        [cell.contentView.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj tag] == 100) {
                [obj removeFromSuperview];
            }
        }];
    }
    
    if (mileage.isSent.boolValue) {
        if (!mileage.status) {
            cell.statusImageView.image = nil;
            [cell.activityIndicatorView startAnimating];
        } else {
            [cell.activityIndicatorView stopAnimating];
            if (mileage.status.length > 0) {
                cell.statusImageView.image = [UIImage imageNamed:mileage.status];
            } else {
                cell.statusImageView.image = [UIImage imageNamed:@"WAITING"];
            }
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 83.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        if ([[sectionInfo name] integerValue] == 0) {
            UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 44.0f)];
            footer.backgroundColor = [UIColor whiteColor];
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            [button addTarget:self action:@selector(submitAll:) forControlEvents:UIControlEventTouchUpInside];
            [button setTitle:@"Send alle" forState:UIControlStateNormal];
            [footer addSubview:button];
            button.frame = CGRectMake(0.0f, 0.0f, CGRectGetWidth(footer.frame), CGRectGetHeight(footer.frame));
            return footer;
        }
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        if ([[sectionInfo name] integerValue] == 0) {
            return 44.0f;
        }
    }
    
    return 0.0f;
    
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *headerTitle;
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        switch ([[sectionInfo name] integerValue]) {
            case 0:
                headerTitle = @"Ikke sendte";
                break;
                
            case 1:
                headerTitle =  @"Sendte";
                break;
                
            default:
                return nil;
                break;
        };
    }
    
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 32.0f)];
    view.backgroundColor = [UIColor colorWithRed:80.0f/255.0f green:80.0f/255.0f blue:80.0f/255.0f alpha:0.80f];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 5.0f, CGRectGetWidth(view.frame)-16.0f, 22.0f)];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.backgroundColor = [UIColor clearColor];
    
    textLabel.text = headerTitle;
    [view addSubview:textLabel];
    
    return view;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 32.0f;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    KMDMileage *mileage = [self.fetchedResultsController objectAtIndexPath:indexPath];
    return !mileage.isSent.boolValue;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            // handle delete
            [DejalBezelActivityView activityViewForView:self.view withLabel:@"Sletter kørsel"];
            [self.managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
            [DejalBezelActivityView removeViewAnimated:YES];
            break;
            
        default:
            break;
    }
}

#pragma mark - fetchedController delegate


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        default:
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];// configureCell:[tableView
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark actionsheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSString *segueIdentifier;
    switch (actionSheet.tag) {
        case actionSheetNewRegistration:
            if (buttonIndex == 0) {
                segueIdentifier = @"new auto registration";
            } else {
                segueIdentifier = @"new manual registration";
            }
            
            [self performSegueWithIdentifier:segueIdentifier sender:[KMDMileage newMileageInManagedContext:self.managedObjectContext]];
            break;
            
        default:
            break;
    }
}


#pragma mark - notifications
- (IBAction)databaseIsReady:(NSNotification *)notification{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kDatabaseIsReadyNotification object:self.appDelegate];
    [KMDTemplate updateTemplateFromBackend];
    [KMDMileage updateMileageRegistrationsFromBackend];
    [self.tableView reloadData];
}


#pragma mark mileage backend update
- (IBAction)mileageUpdated:(NSNotification *)notification{
    [self.refreshControl endRefreshing];
    NSDateFormatter *tf = [NSDateFormatter displayDateWithYear];
    tf.dateFormat = @"HH:mm";
    
    [self setTableViewFotterWithString:[NSString stringWithFormat:@"opdateret : %@",[tf stringFromDate:[NSDate date]]]];
}

- (IBAction)mileageFailUpdate:(NSNotification *)notification{
    [self.refreshControl endRefreshing];
    
    if ([[notification.userInfo objectForKey:@"connectionError"] isKindOfClass:[NSError class]]) {
        NSError *error = [notification.userInfo objectForKey:@"connectionError"];
        [self setTableViewFotterWithString:[NSString stringWithFormat:@"Fejl ved hentning af tidligere kørselsregistreringer: %@",error.localizedDescription]];
    }
}

- (IBAction)reloadFromBackend:(NSNotification *)notification{
    [KMDMileage updateMileageRegistrationsFromBackend];
}

- (void)setTableViewFotterWithString:(NSString *)string{
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0,CGRectGetWidth(self.tableView.frame), 33)];
    
    UILabel *lable = [[UILabel alloc] initWithFrame:tableFooterView.frame];
    lable.textAlignment = NSTextAlignmentCenter;
    lable.numberOfLines = 0;
    lable.font = [UIFont systemFontOfSize:10];
    
    lable.text = string;
    [tableFooterView addSubview:lable];
    self.tableView.tableFooterView = tableFooterView;
}

#pragma mark - Navigation
#pragma mark pre-navigation

#pragma mark user interaction

- (IBAction)logout:(id)sender{
    [self.appDelegate logout];
}

- (IBAction)newRegistration:(id)sender{
    UIActionSheet *newRegActionSheet = [[UIActionSheet alloc] initWithTitle:@"Hvordan vil du registrere din kørsel?" delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:@"Automatisk vha. GPS",@"Manuel indtastning", nil];
    
    newRegActionSheet.tag = actionSheetNewRegistration;
    [newRegActionSheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
}


// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    KMDMileage *mileage;
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        mileage = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:sender]];
    } else if ([sender isKindOfClass:[KMDMileage class]]){
        mileage = sender;
    }
    
    if ([segue.destinationViewController respondsToSelector:@selector(setMileage:)] && mileage) {
        [segue.destinationViewController setMileage:mileage];
    }
}



- (IBAction)submitAll:(id)sender{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isSent = 0"];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    
    [fetchedObjects enumerateObjectsUsingBlock:^(KMDMileage *mileage, NSUInteger idx, BOOL *stop) {
        if (mileage.isValid) {
            [mileage submitMileageToBackend];
        } else {
            [mileage validateAndUpdateError];
        }
    }];
}



- (IBAction)update:(id)sender{
    [KMDMileage updateMileageRegistrationsFromBackend];
}

@end
