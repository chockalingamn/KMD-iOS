//
//  KMDAbsenceCategoryTableViewController.m
//  leaverequest
//
//  Created by Per Friis on 15/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDAbsenceCategoryTableViewController.h"
#import "KMDAbsenceCategoryREST.h"

#import "DejalActivityView.h"

@interface KMDAbsenceCategoryTableViewController () <KMDAbsenceCategoryRESTDelegate, UIAlertViewDelegate>
@property (nonatomic, strong) KMDAbsenceCategoryREST *absenceCategoryRest;

@end

@implementation KMDAbsenceCategoryTableViewController


#pragma mark - View life cycle
- (void)viewDidLoad
{
    [super viewDidLoad];
  
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Henter\nfraværstyper"];
    self.absenceCategoryRest = [KMDAbsenceCategoryREST sharedInstance];
    self.absenceCategoryRest.delegate = self;
    [self.absenceCategoryRest fetchFromBackEnd];
}


- (void)dealloc{
    self.absenceCategoryRest.delegate = nil;
}
#pragma mark - delegates

#pragma mark - Table view data source


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.absenceCategoryRest.categories.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"category cell" forIndexPath:indexPath];
    
    NSDictionary *dic = [self.absenceCategoryRest.categories objectAtIndex:indexPath.row];
    cell.textLabel.text = [dic objectForKey:@"Name"];
    
    cell.accessoryType = [self.absence.absenceID isEqualToString:[dic objectForKey:@"ID"]]?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark alertview
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
//    [self.navigationController popToViewController:self.parentViewController animated:YES];
}

#pragma mark absenceCategory
- (void)absenceCategory:(KMDAbsenceCategoryREST *)category didFailWithError:(NSError *)error{
    NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    [DejalBezelActivityView removeView];
    UIAlertView *connectionError = [[UIAlertView alloc] initWithTitle:@"Mit Fravær" message:@"Der er problemer med at forbinde til serveren" delegate:self cancelButtonTitle:@"Prøv igen senere" otherButtonTitles:nil];
    [connectionError show];
    [connectionError performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:7.5f];
}

- (void)absenceCategory:(KMDAbsenceCategoryREST *)category didUpdateWithData:(NSArray *)categories{
    [DejalBezelActivityView removeView];
    [self.tableView reloadData];
    if (self.absence.absenceID && [self.tableView numberOfRowsInSection:0] > 0) {
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"ID == %@",self.absence.absenceID];
        id obj = [[self.absenceCategoryRest.categories filteredArrayUsingPredicate:pre] firstObject];
        NSInteger row = [self.absenceCategoryRest.categories indexOfObject:obj];
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:row inSection:0];
        if (![self.tableView.indexPathsForVisibleRows containsObject:indexPath]) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
        }
    }
}

- (void)absenceCategory:(KMDAbsenceCategoryREST *)category isUpToDate:(NSArray *)categories{
    [self absenceCategory:category didUpdateWithData:categories];
 }


#pragma mark - user interaction
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSDictionary *typeDic = self.absenceCategoryRest.categories[indexPath.row];

    ExtraTypes oldType = self.absence.extraTypeID;
    
    self.absence.absenceID = typeDic[@"ID"];
    self.absence.absenceName = typeDic[@"Name"];
    
    if ([typeDic[@"DefaultHighDate"] boolValue]) {
        self.absence.startDate = [NSDate stripTimeFromDate:self.absence.startDate];
        self.absence.endDate = [NSDate stripTimeFromDate:self.absence.endDate];
        self.absence.openEnded = YES;
    }
    
    
    if (oldType != self.absence.extraTypeID) {
            self.absence.extraID    = nil;
            self.absence.extraValue = nil;
    }

    [self.navigationController popViewControllerAnimated:YES];
}


@end
