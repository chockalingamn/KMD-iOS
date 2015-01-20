//
//  KMDAbsenceTableViewController.m
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//
@import CoreData;

#import "DejalActivityView.h"
#import "KMD/KMDLoginViewController.h"
#import "KMDFitForDutyViewController.h"
#import "UIImage+ImageEffects.h"
#import "NSDate+MDT.h"

#import "Absence+KMD.h"
#import "AbsenceREST.h"
#import "AbsenceSubmitREST.h"
#import "KMDAbsenceTableViewController.h"
#import "KMDAbsenceTableViewCell.h"
#import "KMD/User.h"

#import "KMDChildrenREST.h"
#import "KMDMaternityREST.h"
#import "KMDReasonREST.h"
#import "KMDWorkInjuryREST.h"

#import "KMDAbsenceDetailViewController.h"

@interface KMDAbsenceTableViewController () <NSFetchedResultsControllerDelegate,AbsenceRESTDelegate,KMDLoginViewControllerDelegate,KMDFitForDutyViewControllerDelegate,AbsenceSubmitRESTDelegate>
@property (nonatomic, readonly) KMDAppDelegate *appDelegate;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, strong) UIButton *fetchMoreAbsenceButton;

@property (nonatomic, strong) UIImageView *emptyImageView;

@property BOOL isFetchingFromBackend;

//@property (nonatomic, readonly) User *user;
@end

@implementation KMDAbsenceTableViewController
#pragma mark - Properties
#pragma mark readonly properties
-(KMDAppDelegate *)appDelegate{
    return [[UIApplication sharedApplication] delegate];
}

#pragma lazy instantiated properties

- (NSFetchedResultsController *)fetchedResultsController{
    if (!self.appDelegate.managedObjectContext) {
        _fetchedResultsController = nil;
    } else if (!_fetchedResultsController) {
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Absence"];
        fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"startDate" ascending:NO]];
        
        _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.appDelegate.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        
        
        NSError *error = nil;
        [_fetchedResultsController performFetch:&error];
        if (error) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        }
        _fetchedResultsController.delegate = self;
        [self.tableView reloadData];
    }
    return _fetchedResultsController;
}

- (UIImageView *)emptyImageView{
    if (!_emptyImageView) {
        _emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"emptytable"]];
        _emptyImageView.frame = CGRectOffset(_emptyImageView.frame, 75.0f, 20.0f);
    }
    return _emptyImageView;
}


#pragma mark - view life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.appDelegate.managedObjectContext) {
        [self getDataFromBackEnd];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataUpdated:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.appDelegate.managedObjectContext];
    } else {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(getDataFromBackEnd) name:kKMDDatabaseIsReady object:self.appDelegate];
        
    }
    
    self.fetchMoreAbsenceButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.fetchMoreAbsenceButton setTitle:@"Hent tidligere registreringer" forState:UIControlStateNormal];
    self.fetchMoreAbsenceButton.tintColor = KMDColorDarkGreen;
    
    [self.fetchMoreAbsenceButton addTarget:self action:@selector(fetchMoreAbsence:) forControlEvents:UIControlEventTouchUpInside];
    
    
    self.tableView.tableFooterView = self.fetchMoreAbsenceButton;
    CGRect rect = self.fetchMoreAbsenceButton.frame;
    rect.size.height = 88.0;
    self.fetchMoreAbsenceButton.frame = rect;
    
    
    UIEdgeInsets inserts = self.tableView.contentInset;
    inserts.bottom += 88.0f;
    [self.tableView setContentInset:inserts];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)showHelpIfNeeded{
    if (self.fetchedResultsController.fetchedObjects.count > 0 && _emptyImageView) {
        [UIView animateWithDuration:0.25f animations:^{
            self.emptyImageView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [self.emptyImageView removeFromSuperview];
            self.emptyImageView = nil;
        }];
        
        self.tableView.tableHeaderView = [[UIView alloc] init];
        
    } else if (!self.isFetchingFromBackend && self.fetchedResultsController.fetchedObjects.count == 0 && !_emptyImageView){
        self.emptyImageView.alpha = 0.0f;
        [self.tableView addSubview:self.emptyImageView];
        [UIView animateWithDuration:0.25f animations:^{
            self.emptyImageView.alpha = 1.0f;
        }];
        
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame),CGRectGetHeight(self.emptyImageView.frame) + 20)];
        
    }
}

- (void)dataUpdated:(NSNotification *)notification{
    NSSet *inserted = [notification.userInfo valueForKey:@"inserted"];
    [inserted enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        Absence *a = obj;
        if (a.openEnded) {
            
                [self performSegueWithIdentifier:@"fitforduty view" sender:a];
            
            *stop = YES;
            
        }
    }];
}

#pragma mark - data handling methods
- (void)getDataFromBackEnd{
    self.navigationItem.rightBarButtonItem.enabled = NO;


    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(getDataFromBackEnd) object:nil];
    [self.tableView beginUpdates];
    self.isFetchingFromBackend = YES;
    [Absence cleanAbsenceTableInManagedObjectContext:self.appDelegate.managedObjectContext];
    if (!self.refreshControl.isRefreshing) {
        [DejalBezelActivityView activityViewForView:self.view withLabel:@"Henter registreringer"];
    }
    self.tableView.userInteractionEnabled = NO;
    [AbsenceREST fetchAbsenceWithDelegate:self];
    if (!self.fetchedResultsController) {
        [self.tableView reloadData];
    }
    [self updateLoadMoreButtonTitle];
}

#pragma mark - UI opdatering
- (void)updateLoadMoreButtonTitle{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc]init];
    dateFormatter.dateFormat = @"'Hent registreringer fra før' MMMM YYYY";
    [self.fetchMoreAbsenceButton setTitle:[dateFormatter stringFromDate:self.appDelegate.fetchFromDate] forState:UIControlStateNormal];
}

#pragma mark - tableview delegate
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [KMDAbsenceTableViewCell heightWith:[self.fetchedResultsController objectAtIndexPath:indexPath]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    KMDAbsenceTableViewCell *cell;
    Absence *absence = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (absence.mustHaveExtra) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"extra" forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"absence" forIndexPath:indexPath];
    }
    
    cell.absence = absence;
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo name];
    } else
        return nil;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.fetchedResultsController sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    Absence *absence = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (absence.status == statusNone) {
        return NO;
    }
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    switch (editingStyle) {
        case UITableViewCellEditingStyleDelete:
            // handle delete
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            [DejalBezelActivityView activityViewForView:self.view withLabel:@"Sletter fravær"];
            [AbsenceSubmitREST submitAbsence:[self.fetchedResultsController objectAtIndexPath:indexPath] operation:operationDelete delegate:self];
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
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self updateLoadMoreButtonTitle];
    [self showHelpIfNeeded];
    
    [self.tableView endUpdates];
}

#pragma mark - external delegate
#pragma mark AbsenceRestDelegate
- (void)AbsenceRestDidFinishDownload:(AbsenceREST *)absenceRest{
    [self.tableView endUpdates];
    self.navigationItem.rightBarButtonItem.enabled = YES;
    self.isFetchingFromBackend = NO;
    [DejalBezelActivityView removeView];
    [self.refreshControl endRefreshing];
    self.tableView.userInteractionEnabled = YES;
}

#pragma mark Absence Submit REST delegate
-(void)absenceSubmitRest:(AbsenceSubmitREST *)sender didFailWithError:(NSError *)error{
    self.navigationItem.rightBarButtonItem.enabled = YES;
    [DejalBezelActivityView removeViewAnimated:YES];
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.title = @"Mit Fravær";
    alertView.message = [NSString stringWithFormat:@"Der var et problem med at kommunikere med server\n%@\nprøv igen senere",error.localizedDescription];
    [alertView addButtonWithTitle:@"OK"];
    
    [alertView show];
    [alertView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:5.0];
}

- (void)absenceSubmitRest:(AbsenceSubmitREST *)sender didFailWithUserMessage:(NSString *)userMessage{
    [DejalBezelActivityView removeViewAnimated:YES];
    UIAlertView *alerView = [[UIAlertView alloc] init];
    alerView.title = @"Mit Fravær";
    alerView.message = userMessage;
    [alerView addButtonWithTitle:@"OK"];
    [alerView show];
}

- (void)absenceSubmitRESTDitFinishWithSuccess:(AbsenceSubmitREST *)sender forOperation:(RestOperation)operation forAbsence:(Absence *)absence{
    [DejalBezelActivityView removeViewAnimated:YES];
    if (operation == operationDelete) {
        [absence.managedObjectContext deleteObject:absence];
    }
    
}


#pragma mark MKDLoginViewControllerDelegate
- (void)loginSuccessful:(UIViewController *)viewController user:(User *)user{
    [viewController dismissViewControllerAnimated:YES completion:^{
        [self getDataFromBackEnd];
        
        [[KMDChildrenREST sharedInstance] fetchFromBackEndForced];
        [[KMDMaternityREST sharedInstance] fetchFromBackEndForced];
        [[KMDWorkInjuryREST sharedInstance] fetchFromBackEndForced];
        [[KMDReasonREST sharedInstance] fetchFromBackEndForced];
    }];
}

#pragma mark KMDFitForDutyViewControllerDelegate
- (void)fitForDutyViewController:(KMDFitForDutyViewController *)fitForDutyViewController didSelectDate:(NSDate *)fitForDutyDate{
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Opdaterer fravær"];
    Absence *absence = fitForDutyViewController.absence;
    absence.endDate = fitForDutyDate;
    
    [fitForDutyViewController dismissViewControllerAnimated:YES completion:^{
        [AbsenceSubmitREST submitAbsence:absence operation:operationModify delegate:self];
    }];
    
    
}

#pragma mark - user interaction
- (IBAction)pullToRefresh:(UIRefreshControl *)sender{
    [self performSelector:@selector(getDataFromBackEnd) withObject:sender afterDelay:1.0f];
}

- (IBAction)fetchMoreAbsence:(id)sender{
    [self.appDelegate addFromMonth:-1];
    [self getDataFromBackEnd];
}

- (IBAction)logout:(id)sender{
    [self.appDelegate logout:self];
    
//    [Absence cleanAbsenceTableInManagedObjectContext:self.appDelegate.managedObjectContext];
//    [self.appDelegate setFromMonth:-2];
//    UINavigationController *navController = [KMDLoginViewController createInstanceEmbeddedInNavigationViewController];
//    
//    KMDLoginViewController *loginViewController = [navController.viewControllers objectAtIndex:0];
//    
//    loginViewController.delegate = self;
//    
//    [self presentViewController:navController animated:YES completion:nil];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        Absence *absence = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:sender]];
        if (absence.status == statusNone) {
            return NO;
        }
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    Absence *absence;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    if ([segue.identifier isEqualToString:@"absence new"]) {
        absence = [NSEntityDescription insertNewObjectForEntityForName:@"Absence" inManagedObjectContext:self.appDelegate.managedObjectContext];
        absence.startDate = [NSDate stripTimeFromDate:[NSDate date]];
        absence.endDate = [NSDate stripTimeFromDate:[NSDate date]];
        
        absence.statusID = nil;
    }

    
    if ([sender isKindOfClass:[Absence class]]) {
        absence = sender;
    }
    
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        absence = [self.fetchedResultsController objectAtIndexPath:[self.tableView indexPathForCell:sender]];
    }
    
    if ([segue.destinationViewController respondsToSelector:@selector(setAbsence:)] && absence) {
        [absence.managedObjectContext.undoManager removeAllActions];
        [segue.destinationViewController setAbsence:absence];
    }
    
    
    if ([segue.destinationViewController isKindOfClass:[KMDFitForDutyViewController class]]) {
        KMDFitForDutyViewController *ffdwc = segue.destinationViewController;
        ffdwc.delegate = self;
    }
}





@end
