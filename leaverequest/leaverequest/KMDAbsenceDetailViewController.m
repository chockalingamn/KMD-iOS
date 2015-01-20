//
//  KMDAbsenceDetailViewController.m
//  leaverequest
//
//  Created by Per Friis on 15/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//

#define BASIC_CELL_ID @"basic cell"
#define RIGHT_DETAIL_CELL_ID @"right detail cell"
#define DATE_PICKER_CELL_ID @"datepicker cell"
#define SWITCH_CELL_ID @"wholeday cell"

#define SECTION_NAME 0
#define SECTION_WHOLEDAY_SWITCH 1
#define SECTION_FROM 2
#define SECTION_TO 3



typedef NS_ENUM(NSInteger, editType){
    absenceNone = -1,
    absenceName,
    absenceExtra,
    absenceStart,
    absenceEnd
};


typedef NS_ENUM(NSInteger, ActionSheet) {
    actionSheetDelete,
    actionSheetBack,
    actionSheetBackNew
};

#import "KMDAbsenceDetailViewController.h"
#import "KMDAbsenceCategoryTableViewController.h"
#import "KMDDatePickerTableViewCell.h"
#import "KMDSwitchTableViewCell.h"

#import "KMDAbsenceTableViewController.h"

#import "AbsenceSubmitREST.h"
#import "NSDate+MDT.h"

#import "KMDChildrenREST.h"
#import "KMDMaternityREST.h"
#import "KMDWorkInjuryREST.h"

@interface KMDAbsenceDetailViewController() <UIActionSheetDelegate,KMDDatePickerTableViewCellDelegate,AbsenceSubmitRESTDelegate>
@property (nonatomic, weak) IBOutlet UILabel *statusHeaderLabel;
@property (nonatomic, weak) IBOutlet UILabel *absenceTypeLabel;
@property (nonatomic, weak) IBOutlet UILabel *absenceReasonLabel;
@property (nonatomic, weak) IBOutlet UILabel *fromDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *toDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *hoursLabel;

@property (nonatomic, strong) NSDateFormatter *startDateFormatter;
@property (nonatomic, strong) NSDateFormatter *endDateFormatter;
@property (nonatomic, readwrite) editType currentEdit;
@property (nonatomic, readwrite) BOOL haveChanged;

@property (nonatomic, assign) UIDatePicker *currentDatePicker;
@property (nonatomic, strong) UISwitch *wholeDaySwitch;
@property (nonatomic, strong) UISwitch *openEndedSwitch;
@property (nonatomic, readwrite) BOOL editWholeDay;
@property (nonatomic, readonly) BOOL wholeDayOn; // handle if the switch is not assigned yet


@end

@implementation KMDAbsenceDetailViewController
- (NSDateFormatter *)startDateFormatter{
    if (!_startDateFormatter) {
        _startDateFormatter = [[NSDateFormatter alloc] init];
        _startDateFormatter.dateStyle = NSDateFormatterLongStyle;
        _startDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _startDateFormatter;
}

- (NSDateFormatter *)endDateFormatter{
    if (!_endDateFormatter) {
        _endDateFormatter = [[NSDateFormatter alloc] init];
        _endDateFormatter.dateStyle = NSDateFormatterLongStyle;
        _endDateFormatter.timeStyle = NSDateFormatterShortStyle;
    }
    return _endDateFormatter;
}

- (BOOL)wholeDayOn{
    if (self.wholeDaySwitch) {
        return self.wholeDaySwitch.isOn;
    } else if (self.absence){
        return self.absence.wholeDay;
    }
    return NO;
}

- (void)setAbsence:(Absence *)absence{
    if (_absence != absence || absence.hasChanges) {
        _absence = absence;
        [_absence.managedObjectContext.undoManager removeAllActions];
        self.editWholeDay = _absence.wholeDay;
        [self.tableView reloadData];
        
    }
}

- (void)setCurrentEdit:(editType)currentEdit{
    _currentEdit = currentEdit;
    
    self.haveChanged = YES;
}


#pragma mark - View life cycle

- (void)viewDidLoad{
    [super viewDidLoad];
    
    self.currentEdit = absenceNone;
    self.haveChanged = NO;
    
    self.navigationItem.backBarButtonItem = nil;
    if ([[[UIDevice currentDevice] systemVersion] integerValue] > 6){
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    } else {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Tilbage" style:UIBarButtonItemStyleDone target:self action:@selector(back:)];
    }
    
   
    if (self.absence.requestID) { // you can only delete one that you have on the backend
        UIView *deleteButtonContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 88.0)];

        UIButton *deleteButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [deleteButton setTitle:@"Slet denne registrering" forState:UIControlStateNormal];
        deleteButton.tintColor = KMDColorDarkGreen;

        [deleteButton addTarget:self action:@selector(deleteAbsence:) forControlEvents:UIControlEventTouchUpInside];
        
        [deleteButtonContainer addSubview:deleteButton];
        deleteButton.frame = CGRectMake(0.0f,0.0f, CGRectGetWidth(deleteButtonContainer.frame)-40.0, 44);
        deleteButton.center = CGPointMake(CGRectGetMidX(deleteButtonContainer.frame), CGRectGetMidY(deleteButtonContainer.frame));
        
        self.tableView.tableFooterView = deleteButtonContainer;
        
        UIEdgeInsets inserts = self.tableView.contentInset;
        inserts.bottom += 88.0f;
        [self.tableView setContentInset:inserts];
    }
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.editWholeDay = self.absence.wholeDay;
    [self.tableView reloadData];
    [self updateSubmitButton];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    if (self.editWholeDay) {
        [self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.15f];
    }
    
    if (self.absence.mustHaveExtra && !self.absence.extraID){
        [self ifOnlyOneExtraValue];
    }
}


#pragma mark tableview delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    if (self.absence) {
        return 4;
        return self.wholeDayOn?5:4;
    }
    return 0;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case SECTION_NAME: // absence category/type and extravalue
            return self.absence.mustHaveExtra?2:1;
            break;
            
        case SECTION_WHOLEDAY_SWITCH: // whole day button
            return 1;
            break;
            
        case SECTION_FROM: // from date
            return self.currentEdit == absenceStart?2:1;
            break;
            
        case SECTION_TO: // to date
            return self.currentEdit == absenceEnd?2:1;
            break;
            
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell;
    if (indexPath.section == SECTION_NAME) {
        cell = [tableView dequeueReusableCellWithIdentifier:BASIC_CELL_ID forIndexPath:indexPath];

        switch (indexPath.row) {
            case 0: // absence name
                if (self.absence.absenceName) {
                    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:self.absence.absenceName attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17.0],NSForegroundColorAttributeName:[UIColor blackColor]}];
                } else {
                    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Vælg Fraværstype" attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.0],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                }
                break;
                
                case 1: // extra value
                if (self.absence.extraValue) {
                    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:self.absence.extraValueDisplayString attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:17.0],NSForegroundColorAttributeName:[UIColor blackColor]}];
                } else {
                    NSString *extraTypeString;
                    switch (self.absence.extraTypeID) {
                        case extraTypeCareDay:
                            if ([[KMDChildrenREST sharedInstance] children].count == 0) {
                                extraTypeString = @"Der er ikke registreret nogle børn";
                            } else {
                                extraTypeString = @"Barn";
                            }
                            break;
                            
                        case extraTypeLeave:
                            extraTypeString = @"Årsag";
                            break;
                            
                        case extraTypeMaternity:
                            if ([[KMDMaternityREST sharedInstance] maternity].count == 0) {
                                extraTypeString = @"Der er ikke registreret nogle barselssager";
                            } else {
                                extraTypeString = @"Termin";
                            }
                            break;
                            
                        case extraTypeWorkRelatedInjury:
                            if ([[KMDWorkInjuryREST sharedInstance] workInjuries].count == 0) {
                                extraTypeString = @"Der er ikke registreret nogle arbejdsskader";
                            } else {
                                extraTypeString = @"Arbejdsskade";
                            }
                            break;
                            
                        default:
                            extraTypeString = @"Værdi";
                            break;
                    }
                    
                    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:[@"Vælg " stringByAppendingString:extraTypeString] attributes:@{NSFontAttributeName: [UIFont systemFontOfSize:13.0],NSForegroundColorAttributeName:[UIColor lightGrayColor]}];
                }
                break;
                
            default:
                break;
        }

    
    } else if (indexPath.section == SECTION_WHOLEDAY_SWITCH) {
        KMDSwitchTableViewCell *c = [tableView dequeueReusableCellWithIdentifier:SWITCH_CELL_ID forIndexPath:indexPath];
        self.wholeDaySwitch = c.cellSwitch;
        [self.wholeDaySwitch setOn:self.editWholeDay];
        [self.wholeDaySwitch addTarget:self action:@selector(wholeDaySwitchValueChanged:) forControlEvents:UIControlEventValueChanged];
        cell = c;
    } else if (indexPath.section == SECTION_FROM || indexPath.section == SECTION_TO) { // from and to date, with picker
        if (indexPath.row == 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:RIGHT_DETAIL_CELL_ID forIndexPath:indexPath];
            
            if (indexPath.section==SECTION_FROM){ // start date
            cell.textLabel.text = @"Fra";
           
            if (self.editWholeDay) {
                self.startDateFormatter.dateStyle = NSDateFormatterFullStyle;
                self.startDateFormatter.timeStyle = NSDateFormatterNoStyle;
            } else {
                self.startDateFormatter.dateStyle = NSDateFormatterLongStyle;
                self.startDateFormatter.timeStyle = NSDateFormatterShortStyle;
            };

            cell.detailTextLabel.text = [self.startDateFormatter stringFromDate:self.absence.startDate];
            } else { // end date
                cell.textLabel.text = @"Til";
                
                if (self.absence.openEnded) {
                    cell.detailTextLabel.text = @"-";
                } else {
                    if ( self.editWholeDay) {
                        self.endDateFormatter.dateStyle = NSDateFormatterFullStyle;
                        self.endDateFormatter.timeStyle = NSDateFormatterNoStyle;
                    } else {
                        self.endDateFormatter.timeStyle = NSDateFormatterShortStyle;
                        if (self.absence.oneDay) {
                            self.endDateFormatter.dateStyle = NSDateFormatterNoStyle;
                        } else {
                            self.endDateFormatter.dateStyle = NSDateFormatterLongStyle;
                        }
                }
                
                cell.detailTextLabel.text           = [self.endDateFormatter stringFromDate:self.absence.endDate];
                }
            }
        } else {
            KMDDatePickerTableViewCell *c = [tableView dequeueReusableCellWithIdentifier:DATE_PICKER_CELL_ID forIndexPath:indexPath];
            c.delegate = self;
            c.date = indexPath.section == SECTION_FROM? self.absence.startDate:self.absence.endDate;
            c.mindate = indexPath.section == SECTION_FROM? nil:self.absence.startDate;
            self.currentDatePicker = c.datePicker;
            c.datePicker.datePickerMode = self.editWholeDay?UIDatePickerModeDate:UIDatePickerModeDateAndTime;
            
            
            cell = c;
        }
    }
    
    return cell;
}




- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if (section > 1) {
        return nil;
    }
    
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 32.0f)];
    view.backgroundColor = [UIColor colorWithRed:80.0f/255.0f green:80.0f/255.0f blue:80.0f/255.0f alpha:0.80f];
    UILabel *textLabel = [[UILabel alloc] initWithFrame:CGRectMake(8.0f, 5.0f, CGRectGetWidth(view.frame)-16.0f, 22.0f)];
    textLabel.textColor = [UIColor whiteColor];
    textLabel.backgroundColor = [UIColor clearColor];
    
    switch (section) {
        case 0:
            textLabel.text = [NSString stringWithFormat:@"Status: %@",self.absence.statusText?self.absence.statusText:@"kladde"];
            break;
        case 1:
            textLabel.text =  @"Periode";
            
        default:
            break;
    }
    
    [view addSubview:textLabel];
    
    return view;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == SECTION_TO && !self.editWholeDay){
            return nil;
    } else if (section == SECTION_TO && self.editWholeDay){
        UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 44)];
        footerView.backgroundColor = [UIColor whiteColor];
        
        UILabel *lable = [[UILabel alloc] initWithFrame:CGRectMake(8, 0, 250, 44)];
        lable.text = @"Ingen slutdato";
        [footerView addSubview:lable];
        
        self.openEndedSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(CGRectGetWidth(tableView.frame)- 67, 6, 51, 31)];
        [self.openEndedSwitch setOn:self.absence.openEnded];
        [self.openEndedSwitch addTarget:self action:@selector(openEndedValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.openEndedSwitch setOnTintColor:KMDColorDarkGreen];

        
        [footerView addSubview:self.openEndedSwitch];
        return footerView;
    }
    
    return [[UIView alloc] init];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section{
    if (section == SECTION_TO && !self.wholeDayOn){
        return [NSString stringWithFormat:@"Varighed: %@",self.absence.durationDisplayString];
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ((indexPath.section == SECTION_FROM || indexPath.section == SECTION_TO) && indexPath.row == 1) {
        return 203.0f;
    }

    return 44.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section > SECTION_WHOLEDAY_SWITCH) {
        return 0.1;
    }
    return 33.0f;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if (section == SECTION_TO){
        return self.editWholeDay?44.0f:33.0f;
    }
    return 0.1f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:SECTION_WHOLEDAY_SWITCH]]) {
        return;
    }
    // segue to category view
    if ([indexPath isEqual:[NSIndexPath indexPathForItem:0 inSection:SECTION_NAME]]){
        [self performSegueWithIdentifier:@"absence category view" sender:nil];
        return;
    }
    
    
    // segue to extra information if avalible (segue id = absence id)
    if ([indexPath isEqual:[NSIndexPath indexPathForItem:1 inSection:SECTION_NAME]] &&
               self.absence.mustHaveExtra){
        [self performSegueWithIdentifier:@"extra" sender:nil];
        return;
    }
    
    // if whole day cell is tapped, switch the whole day switch
    if ([indexPath isEqual:[NSIndexPath indexPathForItem:0 inSection:SECTION_WHOLEDAY_SWITCH]]) {
        [self.wholeDaySwitch setOn:!self.wholeDaySwitch.isOn animated:YES];
        [self wholeDaySwitchValueChanged:self.wholeDaySwitch];
        return;
    }

    
    // handle insert/expansion of cells with date selection wheel
    NSRange range;
    range.location = SECTION_FROM;
    range.length = 2;
    
    if (indexPath.section == SECTION_FROM) {
        if (self.currentEdit == absenceStart) {
            self.currentEdit = absenceNone;
        } else {
            self.currentEdit = absenceStart;
        }
        [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:SECTION_TO]] && !self.openEndedSwitch.on){
        if (self.currentEdit == absenceEnd) {
            self.currentEdit = absenceNone;
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_TO] withRowAnimation:UITableViewRowAnimationAutomatic];
        } else {
            self.currentEdit = absenceEnd;
            [tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }

}

#pragma mark - delegate
#pragma mark actionsheet
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (actionSheet.tag) {
        case actionSheetDelete:
            if (buttonIndex == 0) { // delete confirmed
                // submit a deletion
                [DejalBezelActivityView activityViewForView:self.view withLabel:@"Sletter fravær"];
                [AbsenceSubmitREST submitAbsence:self.absence operation:operationDelete delegate:self];
            }

            break;
            
        case actionSheetBack:
            switch (buttonIndex) {
                case 0:
                    while (self.absence.managedObjectContext.undoManager.canUndo){
                        [self.absence.managedObjectContext.undoManager undo];
                    }

                    [self.navigationController popViewControllerAnimated:YES];
                    break;
                    
                case 1:
                    if (self.absence.isValid) {
                        [self submit];
                    } else {
                        [[[UIAlertView alloc] initWithTitle:@"Fravær kan ikke sendes" message:@"Der mangler muligvis en oplysning" delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
                    }
                    break;
                    
                default:
                    break;
            }
            break;
            
        case actionSheetBackNew:
            // handle the 3 button
            switch (buttonIndex) {
                case 0:
                    [self.absence.managedObjectContext deleteObject:self.absence];
                    [self.navigationController popViewControllerAnimated:YES];
                    break;
                    
                case 2:
                    [self submit];
                    break;
                    
                default:
                    break;
            }
            
            break;
            
        default:
            break;
    }
}

#pragma mark Date Picker cell change
- (void)datePickerCell:(KMDDatePickerTableViewCell *)cell didChangeDateValue:(NSDate *)date{
    NSMutableArray *cellsToRefresh = [[NSMutableArray alloc] init];
    if (self.currentEdit == absenceStart) {
        self.absence.startDate = date;
        [cellsToRefresh addObject:[NSIndexPath indexPathForRow:0 inSection:SECTION_FROM]];
        if ([self.absence.endDate compare:self.absence.startDate] <= NSOrderedSame) {
            self.absence.endDate = self.absence.startDate;
            [cellsToRefresh addObject:[NSIndexPath indexPathForRow:0 inSection:SECTION_TO]];
        }
    } else if (self.currentEdit == absenceEnd) {
        self.absence.endDate = date;
        [cellsToRefresh addObject:[NSIndexPath indexPathForRow:0 inSection:SECTION_TO]];
    }
    
    if (!self.wholeDaySwitch.isOn) {
        NSDate *date1 = [NSDate stripTimeFromDate:self.absence.endDate],
        *date2 = [NSDate stripTimeFromDate:self.absence.startDate];
        if ([date1 timeIntervalSinceDate:date2] == 0) {
            self.absence.hours = [NSNumber numberWithFloat:[self.absence.endDate timeIntervalSinceDate:self.absence.startDate] /3600];
        } else {
            self.absence.hours = @-1;
        }
    }
    
    [self.tableView reloadRowsAtIndexPaths:cellsToRefresh withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark AbsenceSubmitREST delegate

- (void)absenceSubmitRest:(AbsenceSubmitREST *)sender didFailWithError:(NSError *)error{
    [DejalBezelActivityView removeViewAnimated:YES];
    self.absence.status = statusNone;
    
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.title = @"Teknisk fejl";
    
    alertView.message = [NSString stringWithFormat:@"Fejl ved kommunikation til server\n%@\nprøv igen senere",error.localizedDescription];
    [alertView addButtonWithTitle:@"Luk"];
    [alertView show];
    [alertView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:5.0f];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_NAME] withRowAnimation:UITableViewRowAnimationNone];

}

- (void)absenceSubmitRest:(AbsenceSubmitREST *)sender didFailWithUserMessage:(NSString *)userMessage{
    [DejalBezelActivityView removeViewAnimated:YES];
    self.absence.status = statusError;
    UIAlertView *alertView = [[UIAlertView alloc] init];
    alertView.title = self.absence.absenceName;
    alertView.message = userMessage;
    [alertView addButtonWithTitle:@"OK"];
    [alertView show];
    [self.tableView reloadData];
}

- (void)absenceSubmitRESTDitFinishWithSuccess:(AbsenceSubmitREST *)sender forOperation:(RestOperation)operation forAbsence:(Absence *)absence{
    [DejalBezelActivityView removeViewAnimated:YES];
    [self.absence.managedObjectContext save:nil];
    self.absence.status = statusUnknown;
    [self.absence.managedObjectContext.undoManager removeAllActions];

    if (operation == operationDelete) {
        [self.absence.managedObjectContext deleteObject:self.absence];
    }

    [self popToAbsencetableViewController];
}

#pragma mark - utility methods
- (void)submit{
    // TODO: jeg er ikke glad for denne tekst....
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Sender fravær"];
    if (!self.absence.requestID) {
        self.absence.status = statusSubmitted;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_NAME] withRowAnimation:UITableViewRowAnimationNone];

        [AbsenceSubmitREST submitAbsence:self.absence operation:operationCreate delegate:self];
    } else {
        self.absence.status = statusSubmitted;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:SECTION_NAME] withRowAnimation:UITableViewRowAnimationNone];

        [AbsenceSubmitREST submitAbsence:self.absence operation:operationModify delegate:self];
    }
}

- (void)updateSubmitButton{
    self.navigationItem.rightBarButtonItem.enabled = self.absence.isValid;
}

#pragma mark - user interaction
- (IBAction)wholeDaySwitchValueChanged:(UISwitch *)sender{
    self.editWholeDay = sender.isOn;
    if (self.absence.openEnded) {
        self.absence.openEnded = NO;
    }
    self.currentEdit = absenceNone;
    if (self.editWholeDay) {
        self.absence.startDate = [NSDate stripTimeFromDate:self.absence.startDate];
        self.absence.endDate = [NSDate stripTimeFromDate:self.absence.endDate];
    } else {
        self.absence.startDate = [NSDate setTime:@"08:00" onDate:self.absence.startDate];
        self.absence.endDate = [NSDate setTime:@"16:00" onDate:self.absence.endDate];
    }

    NSRange range;
    range.location = SECTION_FROM;
    range.length = 2;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationAutomatic];
    
//    [self.tableView reloadData];
}

- (IBAction)openEndedValueChanged:(UISwitch *)sender{
    self.absence.openEnded = sender.isOn;
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:SECTION_TO]] withRowAnimation:UITableViewRowAnimationNone];
    }];
}


- (void) ifOnlyOneExtraValue{
    // checking if there is only one option, if so, seletct the one and don't display the selection.
      switch (self.absence.extraTypeID) {
            case extraTypeCareDay:
                if ([[KMDChildrenREST sharedInstance] children].count == 1) {
                    self.absence.extraID = [[[[KMDChildrenREST sharedInstance] children] firstObject] valueForKey:@"ID"];
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:SECTION_NAME]] withRowAnimation:UITableViewRowAnimationFade];
                }
                break;
              
            case extraTypeMaternity:
              if ([[KMDMaternityREST sharedInstance] maternity].count == 1) {
                  self.absence.extraID = [[[[KMDMaternityREST sharedInstance] maternity] firstObject] valueForKey:@"MaternityID"];
                  [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:1 inSection:SECTION_NAME]] withRowAnimation:UITableViewRowAnimationFade];
              }
              
            case extraTypeWorkRelatedInjury:
              if ([[KMDWorkInjuryREST sharedInstance] workInjuries].count == 1) {
                  self.absence.extraID = [[[[KMDWorkInjuryREST sharedInstance] workInjuries] firstObject] valueForKey:@"WorkInjuryID"];
              }
                
            default:
                break;
        }
    
    [self updateSubmitButton];
//    [self performSegueWithIdentifier:@"extra" sender:nil];

}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.destinationViewController respondsToSelector:@selector(setAbsence:)]) {
        [segue.destinationViewController setAbsence:self.absence];
    }
}


#pragma user interaction
- (IBAction)deleteAbsence:(id)sender{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Er du sikker på, at du vil slette denne registrering?" delegate:self cancelButtonTitle:@"Nej" destructiveButtonTitle:@"Ja, slet" otherButtonTitles: nil];
    actionSheet.tag = actionSheetDelete;
    [actionSheet showInView:self.view];
}

- (IBAction)submitAbsence:(id)sender{
    if (!self.absence.hasChanges && (self.absence.status == statusApproved || self.absence.status == statusSubmitted)) {
        UIAlertView *alertView = [[UIAlertView alloc] init];
        alertView.title = self.absence.absenceName;
        alertView.message = @"Der er ingen ændringer på denne registrering.\nRegistreringen bliver ikke sendt.";
        [alertView addButtonWithTitle:@"Luk"];
        
        
        [alertView show];
        [alertView performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:5.0f];
        return;
    }
    
    [self submit];
    
}


- (IBAction)back:(id)sender{
    if (self.absence.hasChanges || self.absence.status <= statusNone) {
        
        UIActionSheet *actionsheet = [[UIActionSheet alloc] initWithTitle:@"Der er rettelser i din registrering" delegate:self cancelButtonTitle:@"Gem rettelser" destructiveButtonTitle:@"Fortryd rettelser" otherButtonTitles:nil];
        actionsheet.tag = actionSheetBack;
        if (!self.absence.requestID) {
            actionsheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Send registrering" destructiveButtonTitle:@"Fortryd registrering" otherButtonTitles:@"Fortsæt indberetning", nil];
        
            actionsheet.tag = actionSheetBackNew;
        }
        
        [actionsheet showInView:self.view];
        
    } else{
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)popToAbsencetableViewController{
    // GitHub issue #22
    // This is a dirty fix on two issues
    // 1. When a new absence is submitted to the backend and returned with success, there is no unique handle to match the submitted absence, with the backend, data. to handle this, the local data must be reloaded from the backend, to ensure, further edit(submit) is possible.
    // 2. The backend have an processing time and an error, that results in returning the same object twise if the download happens to fast after submittion
    for (id vc in [self.navigationController viewControllers]) {
        if ([vc isKindOfClass:[KMDAbsenceTableViewController class]]) {
            KMDAbsenceTableViewController * atvc = vc;
            [atvc performSelector:@selector(getDataFromBackEnd) withObject:nil afterDelay:7.0f];
        }
    }
   // }
    [self.navigationController popViewControllerAnimated:YES];
}
@end
