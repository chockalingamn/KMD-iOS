//
//  KMDAbsenceExtraViewController.m
//  leaverequest
//
//  Created by Per Friis on 12/08/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#import "KMDAbsenceExtraViewController.h"

#import "KMDReasonREST.h"
#import "KMDChildrenREST.h"
#import "KMDWorkInjuryREST.h"
#import "KMDMaternityREST.h"


@interface KMDAbsenceExtraViewController () <KMDReasonRESTDelegate,KMDChildrenRESTDelegate,KMDWorkInjuryRESTDelegate,KMDMaternityRESTDelegate>
@property (nonatomic, readonly) NSArray *values;

@property (nonatomic, strong) KMDReasonREST     *reasonREST;
@property (nonatomic, strong) KMDChildrenREST   *childreanREST;
@property (nonatomic, strong) KMDWorkInjuryREST *workInjuryREST;
@property (nonatomic, strong) KMDMaternityREST  *maternityREST;

@property (nonatomic, readonly) NSString *key_ID;

@end

@implementation KMDAbsenceExtraViewController
- (NSString *)key_ID{
    if (self.absence.extraTypeID == extraTypeMaternity) {
        return @"MaternityID";
    } else if (self.absence.extraTypeID == extraTypeWorkRelatedInjury){
        return  @"WorkInjuryID";
    }
    return @"ID";
}

- (NSArray *)values{
    switch (self.absence.extraTypeID) {
        case extraTypeLeave:
            return self.reasonREST.reasons;
            break;
            
        case extraTypeMaternity:
            return self.maternityREST.maternity;
            break;
            
        case extraTypeCareDay:
            return self.childreanREST.children;
            break;
            
        case extraTypeWorkRelatedInjury:
            return self.workInjuryREST.workInjuries;
            break;
            
        default:
            break;
    }

    return nil;
}

- (KMDChildrenREST *)childreanREST{
    if (!_childreanREST) {
        _childreanREST = [KMDChildrenREST sharedInstance];
        _childreanREST.delegate = self;
    }
    return _childreanREST;
}

- (KMDReasonREST *)reasonREST{
    if (!_reasonREST) {
        _reasonREST = [KMDReasonREST sharedInstance];
        _reasonREST.delegate = self;
    }
    return _reasonREST;
}

- (KMDWorkInjuryREST *)workInjuryREST{
    if (!_workInjuryREST) {
        _workInjuryREST = [KMDWorkInjuryREST sharedInstance];
        _workInjuryREST.delegate = self;
    }
    return _workInjuryREST;
}

- (KMDMaternityREST *)maternityREST{
    if (!_maternityREST) {
        _maternityREST = [KMDMaternityREST sharedInstance];
        _maternityREST.delegate = self;
    }
    return _maternityREST;
}


- (NSString *)valueIDAtIndexPath:(NSIndexPath *)indexPath{
    // this function don't handle multible sections
    NSDictionary *value = [self.values objectAtIndex:indexPath.row];
    return [value valueForKey:self.key_ID];
}

- (NSString *)valueDisplayStringAtIndexPath:(NSIndexPath *)indexPath{
    // this function don't handle multible sections
    NSDictionary *value = [self.values objectAtIndex:indexPath.row];
    switch (self.absence.extraTypeID) {
        case extraTypeLeave:
            return [value objectForKey:@"Name"];
            break;
            
        case extraTypeCareDay:
            return [NSString stringWithFormat:@"%@ %@",[value objectForKey:@"FirstName"],[value objectForKey:@"LastName"]];
            break;
            
        case extraTypeMaternity:{
            
            NSDate *date;
            
            if ([value valueForKey:@"ActualDevliveryDate"] && ![[value valueForKey:@"ActualDevliveryDate"] isEqualToString:@"0000-00-00"]) {
                date = [[NSDateFormatter rfc3339Date] dateFromString:[value valueForKey:@"ActualDevliveryDate"]];
            } else {
                date = [[NSDateFormatter rfc3339Date] dateFromString:[value valueForKey:@"ExpectedDeliveryDate"]];
            }
            return [[NSDateFormatter displayDateWithYear] stringFromDate:date];
    }
            break;
            
        case extraTypeWorkRelatedInjury:
            return [value valueForKey:@"WorkIjnuryID"];
            break;
            
        default:
            break;
    }
    return nil;
}

- (id)valueAtIndexPath:(NSIndexPath *)indexPath{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    // this function don't handle multible sections
    NSDictionary *value = [self.values objectAtIndex:indexPath.row];
    switch (self.absence.extraTypeID) {
        case extraTypeLeave:
            return [value objectForKey:@"Name"];
            break;
            
        case extraTypeCareDay:
            return [NSString stringWithFormat:@"%@ %@",[value objectForKey:@"FirstName"],[value objectForKey:@"LastName"]];
            break;
            
        case extraTypeMaternity:
            if ([value valueForKey:@"ActualDevliveryDate"] && [dateFormatter dateFromString:[value valueForKey:@"ActualDevliveryDate"]]) {
                return [dateFormatter dateFromString:[value valueForKey:@"ActualDevliveryDate"]];
            } else {
                return [dateFormatter dateFromString:[value valueForKey:@"ExpectedDeliveryDate"]];;
            }
            
            break;
            
        case extraTypeWorkRelatedInjury:
            return [dateFormatter dateFromString:[value valueForKey:@"WorkIjnuryID"]];
            break;
            
        default:
            break;
    }
    return nil;

}


#pragma mark - view life cycle
- (void)viewDidLoad{
    [super viewDidLoad];
    
    switch (self.absence.extraTypeID) {
        case extraTypeLeave:
            self.title = @"Vælg Årsag";
            break;
            
        case extraTypeMaternity:
            self.title = @"Barsel";
            break;
            
        case extraTypeCareDay:
            self.title = @"Barsel";
            break;
            
        case extraTypeWorkRelatedInjury:
            self.title = @"Vælg Arbejdsskade";
            break;
            
        default:
            break;
    }
    
    
    [DejalBezelActivityView activityViewForView:self.view withLabel:[NSString stringWithFormat:@"Henter\n%@",self.title]];

    switch (self.absence.extraTypeID) {
        case extraTypeLeave:
            [self.reasonREST fetchFromBackEnd];
            break;
            
        case extraTypeCareDay:
            [self.childreanREST fetchFromBackEnd];
            break;
            
        case extraTypeMaternity:
            [self.maternityREST fetchFromBackEnd];
            break;
            
        case extraTypeWorkRelatedInjury:
            [self.workInjuryREST fetchFromBackEnd];
            break;
            
        default:
            [self reasonREST:nil didFaileWithError:nil];
            break;
    }
}


-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if (self.absence.extraValue) {
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"%K == %@",self.key_ID,self.absence.extraID];
        id obj = [[self.values filteredArrayUsingPredicate:pre] firstObject];
        NSInteger row = [self.values indexOfObject:obj];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForItem:row inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:animated];
    }
}


- (void)dealloc{
    _childreanREST.delegate = nil;
    
    _reasonREST.delegate = nil;
    
    _workInjuryREST.delegate = nil;
    
    _maternityREST.delegate = nil;
}

#pragma mark - delegates
#pragma mark Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.values.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"extra cell" forIndexPath:indexPath];
    
    cell.textLabel.text = [self valueDisplayStringAtIndexPath:indexPath];

    
    cell.accessoryType = [self currentStatusfor:indexPath];
    
    return cell;
}

- (UITableViewCellAccessoryType)currentStatusfor:(NSIndexPath *)indexPath{
    NSDictionary *value = [self.values objectAtIndex:indexPath.row];
    
    
    if ([[value objectForKey:self.key_ID] isEqualToString:self.absence.extraID]) {
        return UITableViewCellAccessoryCheckmark;
    }
    
    return UITableViewCellAccessoryNone;
}

#pragma mark Alert view
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex{
    self.absence.extraID = @"na";
    self.absence.extraValue = @"-";
    
    
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark reason REST
- (void)reasonREST:(KMDReasonREST *)reasonREST didFaileWithError:(NSError *)error{
    [DejalBezelActivityView removeViewAnimated:YES];
    UIAlertView *alertview = [[UIAlertView alloc] initWithTitle:@"Mit Fravær" message:@"Der er et problem med at forbinde til serveren" delegate:self cancelButtonTitle:@"Prøv senere" otherButtonTitles:nil];
    
    if ([error.userInfo valueForKey:@"errorReason"]) {
        alertview.message = [error.userInfo valueForKey:@"errorReason"];
    }
    
    [alertview show];
    [alertview performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:7.5f];
    
}

- (void)reasonREST:(KMDReasonREST *)reasonREST isUpToDate:(NSArray *)reasons{
    [self reasonREST:reasonREST didUpdateWithReasons:reasons];
}

- (void)reasonREST:(KMDReasonREST *)reasonREST didUpdateWithReasons:(NSArray *)reasons{
    [self.tableView reloadData];
    [DejalBezelActivityView removeView];
}

#pragma mark Children REST
- (void)childrenREST:(KMDChildrenREST *)childrenREST didFaileWithError:(NSError *)error{
    [self reasonREST:nil didFaileWithError:error];
}

- (void)childrenREST:(KMDChildrenREST *)childrenREST isUpToDate:(NSArray *)children{
    [self childrenREST:childrenREST didUpdateWithChildren:children];
}

- (void)childrenREST:(KMDChildrenREST *)childrenREST didUpdateWithChildren:(NSArray *)children{
    [self.tableView reloadData];
    [DejalBezelActivityView removeViewAnimated:YES];
}

#pragma mark Work Injury REST
- (void)workInjuryREST:(KMDWorkInjuryREST *)workInjuryREST didFaileWithError:(NSError *)error{
    [self reasonREST:nil didFaileWithError:error];
}

- (void)workInjuryREST:(KMDWorkInjuryREST *)workInjuryREST isUpToDate:(NSArray *)workInjuries{
    [self workInjuryREST:workInjuryREST didUpdateWithWorkInjuries:workInjuries];
}

- (void)workInjuryREST:(KMDWorkInjuryREST *)workInjuryREST didUpdateWithWorkInjuries:(NSArray *)workInjuries{
    [self.tabBarController reloadInputViews];
    [DejalBezelActivityView removeViewAnimated:YES];
}

#pragma mark MaternatyRest delegate
- (void)MaternityREST:(KMDMaternityREST *)maternityREST didFaileWithError:(NSError *)error{
    [self reasonREST:nil didFaileWithError:error];
}

- (void)MaternityREST:(KMDMaternityREST *)maternityREST isUpToDate:(NSArray *)maternity{
    [self MaternityREST:maternityREST didUpdateWithMaternity:maternity];
}

- (void)MaternityREST:(KMDMaternityREST *)maternityREST didUpdateWithMaternity:(NSArray *)maternity{
    [self.tableView reloadData];
    [DejalBezelActivityView removeViewAnimated:YES];
}


#pragma mark - user interaction
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    self.absence.extraID    = [self valueIDAtIndexPath:indexPath];
    if (self.absence.extraTypeID == extraTypeMaternity) {
        NSDictionary *value = [self.values objectAtIndex:indexPath.row];

        self.absence.expectedDeliveryDate = [[NSDateFormatter rfc3339Date] dateFromString:[value valueForKey:@"ExpectedDeliveryDate"]];
        self.absence.actualDeliveryDate = [[NSDateFormatter rfc3339Date] dateFromString:[value valueForKey:@"ActualDevliveryDate"]];
    } else {
    
        self.absence.extraValue = [self valueAtIndexPath:indexPath];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}

@end
