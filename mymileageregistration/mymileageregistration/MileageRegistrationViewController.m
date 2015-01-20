//
//  MileageRegistrationViewController.m
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import "MileageRegistrationViewController.h"
#import "FieldTableViewCell.h"
#import "KMDKeyboardToolbar.h"
#import "KMDMapPoint.h"
#import "KMDTemplate+utility.h"
#import "KMDGeocoder.h"


#define KMD_EXTRALIGHT_GRAY [UIColor colorWithRed:0.97f green:0.97f blue:0.97f alpha:1]
#define KMD_LIGHT_GRAY [UIColor colorWithRed:0.87f green:0.87f blue:0.87f alpha:1]
typedef NS_ENUM(NSInteger, Mileage) {
    sectionPurpose,
    sectionFrom,
    sectionTo,
    sectionVia,
    sectionDistance,
    sectionDate,
    sectionTemplate,
    sectionLicense,
    sectionRemark
};

typedef NS_ENUM(NSInteger, FieldTag) {
    ftUnknown,
    ftPurpose,
    ftFrom,
    ftTo,
    ftDistance,
    ftLicense,
    ftComment,
    ftNotUsed,
    ftVia
};

@interface MileageRegistrationViewController () <UITextFieldDelegate,UITextViewDelegate,FieldTableViewCellDelegate,UIPickerViewDataSource,UIPickerViewDelegate,KMDKeyboardToolbarDelegate,CLLocationManagerDelegate,UIAlertViewDelegate>
@property (nonatomic, readwrite) BOOL showDateSelector;
@property (nonatomic, readwrite) BOOL showTemplateSelector;
@property (nonatomic, readonly) AppDelegate *appDelegate;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) IBOutlet KMDKeyboardToolbar *keyboardToolbar;

@property (nonatomic, readonly) NSArray *templates;
@property (nonatomic, assign) id currentFirstResponder;

@property (nonatomic, weak) IBOutlet UITextField *purposeTextField;
@property (nonatomic, weak) IBOutlet UITextField *fromTextField;
@property (nonatomic, weak) IBOutlet UIButton *fromButton;
@property (nonatomic, strong) IBOutletCollection(UITextField) NSMutableArray *viaTextFields;
@property (nonatomic, strong) IBOutletCollection(UIButton) NSMutableArray *viaButtons;
@property (nonatomic, weak) IBOutlet UITextField *currentVia;
@property (nonatomic, weak) IBOutlet UITextField *toTextField;
@property (nonatomic, weak) IBOutlet UIButton *toButton;
@property (nonatomic, weak) IBOutlet UITextField *distanceTextField;
@property (nonatomic, weak) IBOutlet UIButton *distanceButton;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) IBOutlet UITextField *licenseTextField;
@property (nonatomic, weak) IBOutlet UITextView *commentTextView;
@property (nonatomic, weak) IBOutlet UILabel *commentPlaceHolder;

@property (nonatomic,weak) IBOutlet UIView *googleAutoCompleteContainer;

@property (nonatomic, readonly) CLLocationManager *locationManager;

@property (nonatomic, strong) CLLocation *currentLocation;

@property (nonatomic, readwrite) NSInteger reversegeocoding;

@property (nonatomic, readwrite) BOOL manualDistance;

@end

@implementation MileageRegistrationViewController
#pragma mark - properties
@synthesize templates = _templates;
- (NSArray *)templates{
    if (!_templates) {
        _templates = [KMDTemplate templatesInManagedObjectContext:self.managedObjectContext];
    }
    return _templates;
    
}

- (NSMutableArray *)viaButtons{
    if (!_viaButtons) {
        _viaButtons = [[NSMutableArray alloc] init];
    }
    return _viaButtons;
}

- (NSMutableArray *)viaTextFields{
    if (!_viaTextFields) {
        _viaTextFields = [[NSMutableArray alloc] init];
    }
    return _viaTextFields;
}

- (AppDelegate *)appDelegate{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (NSManagedObjectContext *)managedObjectContext{
    return self.appDelegate.managedDocument.managedObjectContext;
}

- (CLLocationManager *)locationManager{
    return self.appDelegate.locationManager;
}

- (void)setReversegeocoding:(NSInteger)reversegeocoding{
    if (reversegeocoding < 0) {
        _reversegeocoding = 0;
    } else {
        _reversegeocoding = reversegeocoding;
    }
}

#pragma mark - utility
- (void)updateSubmitButtonValid{
    self.navigationItem.rightBarButtonItem.enabled = self.mileage.isValid && !self.mileage.isSent.boolValue;
}


#pragma mark - view life cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
   
    self.showDateSelector = NO;
    self.showTemplateSelector = NO;
    self.reversegeocoding = 0;
    self.manualDistance = NO;
    
    [self.managedObjectContext.undoManager disableUndoRegistration];
    if (self.mileage.isSent.boolValue) {
        self.navigationItem.rightBarButtonItem = nil;
    }
    [self.managedObjectContext.undoManager enableUndoRegistration];
    
    if (!self.mileage.isSent.boolValue){
        
        UIView *tableFooterDeleteView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.tableView.frame), 44.0f)];
        tableFooterDeleteView.backgroundColor = [UIColor whiteColor];
        
        UIButton *deleteDraft = [UIButton buttonWithType:UIButtonTypeSystem];
        
        deleteDraft.frame = CGRectInset(tableFooterDeleteView.frame, 16.0f, 4.0f);
        
        [deleteDraft setTitle:@"Slet kladde" forState:UIControlStateNormal];
        [deleteDraft addTarget:self action:@selector(deleteDraft:) forControlEvents:UIControlEventTouchUpInside];
        
        deleteDraft.layer.borderColor = [[UIColor redColor] CGColor];
        deleteDraft.layer.borderWidth = 0.5f;
        deleteDraft.layer.cornerRadius = 5.0f;
        
        [tableFooterDeleteView addSubview:deleteDraft];
        self.tableView.tableFooterView = tableFooterDeleteView;
    } else {
        self.tableView.tableFooterView = [[UIView alloc]init];
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.locationManager startUpdatingLocation];
    self.locationManager.delegate = self;
    [self updateSubmitButtonValid];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
  
    
    if (self.mileage.submitError) {
        NSString *errorTitle;
        if (self.mileage.isValid) {
            errorTitle = @"Din kørsel kunne ikke registreres:";
        } else {
            errorTitle = @"Kørsel";
        }
        
        if ([UIAlertController class]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorTitle message:self.mileage.submitError preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                [alertController dismissViewControllerAnimated:YES completion:nil];
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
            // iOS 8....
        } else {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:self.mileage.submitError delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
            [alertView show];
        }
        
        self.mileage.submitError = nil;
        [self.managedObjectContext save:nil];
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveManagedDocument];

    }
   [self.managedObjectContext.undoManager removeAllActions];
}


- (void) viewWillDisappear:(BOOL)animated{
  
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    
    
    if (!self.mileage.isSent.boolValue) {
        self.appDelegate.editedMileage = self.mileage;
    } else {
        self.appDelegate.editedMileage = nil;
    }
    
    [super viewWillDisappear:animated];
    
}


- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Delegates
#pragma mark tableview
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 9;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case sectionVia:
            return self.mileage.intermidiatePoints.count; // numbers of via points
            break;
            
        case sectionDate:
            return self.showDateSelector?2:1;
            break;
            
        case sectionTemplate:
            return self.showTemplateSelector?2:1;
            break;
            
        default:
            return 1;
            break;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    NSString *leadText;
    switch (section) {
        case sectionPurpose:
            leadText =  @"Formål";
            break;
            
        case sectionFrom:
            leadText =   @"Fra";
            break;
            
        case sectionVia:
            if (self.mileage.isSent.boolValue && self.mileage.intermidiatePoints.count == 0) {
                return nil;
            }
            leadText = @"Via";
            break;
            
        case sectionTo:
            leadText =   @"Til";
            break;
            
        case sectionDate:
            leadText = @"Dato";
            break;
            
        case sectionTemplate:
            leadText = @"Kørselstype";
            break;
            
        case sectionLicense:
            leadText =   @"Registreringsnummer";
            break;
            
        case sectionDistance:
            leadText =   @"Distance";
            break;
            
        case sectionRemark:
            leadText =   @"Kommentar";
            break;
            
        default:
            return nil;
            break;
    }
    
    
    UIView *headerview = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 22)];
    headerview.backgroundColor = KMD_EXTRALIGHT_GRAY;
    
    UILabel *headerTitle = [[UILabel alloc] initWithFrame:CGRectInset(headerview.frame, 8, 0)];
    headerTitle.attributedText = [[NSAttributedString alloc] initWithString:leadText attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12]}];
    
    [headerview addSubview:headerTitle];
    
    return headerview;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if (section == sectionVia && self.mileage.isSent.boolValue && self.mileage.intermidiatePoints.count == 0)  {
        return 0;
    }
    return 22;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if (section == sectionVia && !self.mileage.isSent.boolValue) {
        UIView *sectionFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(tableView.frame), 32.0f)];
        sectionFooterView.backgroundColor = [UIColor whiteColor];
        
        UIButton *addViaPoint = [UIButton buttonWithType:UIButtonTypeSystem];
        
        [addViaPoint setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
        addViaPoint.frame = CGRectMake(0, 0, CGRectGetWidth(tableView.frame)- 8, 32.0f);
        addViaPoint.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        
        [addViaPoint setTitle:@"Tilføj nyt viapunkt " forState:UIControlStateNormal];
        [addViaPoint addTarget:self action:@selector(addViaPoint:) forControlEvents:UIControlEventTouchUpInside];
        [sectionFooterView addSubview:addViaPoint];
        return sectionFooterView;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return (section == sectionVia  && !self.mileage.isSent.boolValue)?28.0f:0.0f;
}



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    FieldTableViewCell *cell;
    
    switch (indexPath.section) {
        case sectionPurpose:
        {
            FieldTableViewCell *fieldcell = [tableView dequeueReusableCellWithIdentifier:@"field cell"];
            self.purposeTextField = fieldcell.textField;
            self.purposeTextField.placeholder = @"Formål med kørsel";
            self.purposeTextField.delegate = self;
            self.purposeTextField.text = self.mileage.reason;

            self.purposeTextField.enabled = !self.mileage.isSent.boolValue;
            
            cell = fieldcell;
        }
            break;
            
        case sectionFrom: // purpose and origien
        {
            FieldTableViewCell *fieldcell = [tableView dequeueReusableCellWithIdentifier:@"gps cell"];
            
            self.fromTextField = fieldcell.textField;
            self.fromTextField.placeholder = @"Fra";
            self.fromTextField.text = self.mileage.startAddress;
            self.fromTextField.delegate = self;
            self.fromTextField.enabled = !self.mileage.isSent.boolValue;
            
            self.fromButton = fieldcell.actionButton;
            self.fromButton.tag = ftFrom;
            self.fromButton.enabled = NO;
            [self.fromButton addTarget:self action:@selector(fromReverseGeocode:) forControlEvents:UIControlEventTouchUpInside];
            
            cell = fieldcell;
        }
            
            break;
            
        case sectionVia: // via points
        {
            FieldTableViewCell *fieldcell = [tableView dequeueReusableCellWithIdentifier:@"gps cell"];
            KMDIntermidiatePoint *intermidiatePoint = [self.mileage.intermidiatePoints objectAtIndex:indexPath.row];
            
            UITextField *textField = fieldcell.textField;
            textField.placeholder = @"Via";
            textField.text = intermidiatePoint.intermidiateAddress;
            textField.tag = ftVia + indexPath.row;
            textField.delegate = self;
            textField.enabled = !self.mileage.isSent.boolValue;
            
            [self.viaTextFields setObject:textField atIndexedSubscript:indexPath.row];
            
            UIButton *button = fieldcell.actionButton;
            [button addTarget:self action:@selector(fromReverseGeocode:) forControlEvents:UIControlEventTouchUpInside];
            button.tag = ftVia+ indexPath.row;
            button.enabled = self.fromButton.enabled;
            [self.viaButtons setObject:button atIndexedSubscript:indexPath.row];
            fieldcell.theKey = @"via";
            
            cell = fieldcell;
        }
            break;
            
        case sectionTo: // end destination
            
        {
            FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"gps cell" forIndexPath:indexPath];
            self.toTextField = fieldCell.textField;
            
            
            self.toTextField.placeholder = @"Til";
            self.toTextField.tag = ftTo;
            self.toTextField.delegate = self;
            
            self.toTextField.text = self.mileage.endAddress;
            self.toTextField.enabled = !self.mileage.isSent.boolValue;
            
            self.toButton = fieldCell.actionButton;
            [self.toButton addTarget:self action:@selector(fromReverseGeocode:) forControlEvents:UIControlEventTouchUpInside];
            self.toButton.tag = ftTo;
            self.toButton.enabled = NO;
            
            fieldCell.theKey = @"endAddress";
            cell = fieldCell;
        }
            break;
            
        case sectionDistance:
        {
            FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"button cell" forIndexPath:indexPath];
            self.distanceTextField = fieldCell.textField;
            
            self.distanceTextField.placeholder = @"Km";
            self.distanceTextField.tag = ftDistance;
            self.distanceTextField.delegate = self;
            self.distanceTextField.enabled = !self.mileage.isSent.boolValue;
            
            if (self.mileage.distanceOfTripInKilometers.floatValue > 0) {
                self.distanceTextField.text = [NSString stringWithFormat:@"%.2f km",self.mileage.distanceOfTripInKilometers.floatValue];
            }
            
            self.distanceButton = fieldCell.actionButton;
            self.distanceButton.tag = ftDistance;
            self.distanceButton.enabled = !self.mileage.isSent.boolValue;
            [self.distanceButton addTarget:self action:@selector(calculateDistance:) forControlEvents:UIControlEventTouchUpInside];
            
            fieldCell.theKey = @"distanceOfTripInKilometers";
            cell = fieldCell;
        }
            break;
            
            
        case sectionDate: // date
            switch (indexPath.row) {
                case 0:
                {
                    FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"date cell" forIndexPath:indexPath];
                    fieldCell.dateLabel.tag = 5;
                    self.dateLabel = fieldCell.dateLabel;
                    self.dateLabel.text = [[NSDateFormatter displayDateWithYear] stringFromDate:self.mileage.depatureTimestamp];
                    fieldCell.theKey = @"depatureTimestamp";
                    return fieldCell;
                    
                }
                    break;
                    
                case 1:
                {// dato select{
                    FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"datepicker cell" forIndexPath:indexPath];
                    self.datePicker = fieldCell.datePicker;
                    self.datePicker.date = self.mileage.depatureTimestamp;
                    [self.datePicker addTarget:self action:@selector(datePickerValueChanged:) forControlEvents:UIControlEventValueChanged];
                    
                    fieldCell.theKey = @"dateSelect";
                    cell = fieldCell;
                }
                    break;
                    
                default:
                    cell = nil;
                    break;
            }
            break;
            
        case sectionTemplate: // template
            switch (indexPath.row) {
                case 0:
                {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"standard cell" forIndexPath:indexPath];
                    cell.textLabel.attributedText = self.mileage.displayTeamplateName;
                }
                    break;
                    
                case 1: // picker
                {
                    FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"templatepicker cell" forIndexPath:indexPath];
                    fieldCell.pickerView.dataSource = self;
                    fieldCell.pickerView.delegate = self;
                    fieldCell.pickerView.tag = 1;
                    
                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"templateID == %@",self.mileage.templateID];
                    id obj = [[self.templates filteredArrayUsingPredicate:predicate] firstObject];
                    if (obj) {
                        [fieldCell.pickerView selectRow:[self.templates indexOfObject:obj]+1 inComponent:0 animated:YES];
                    }
                    cell = fieldCell;
                }
                    break;
                    
                default:
                    cell = nil;
                    break;
            }
            break;
            
        case sectionLicense:
            
        {
            FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"field cell" forIndexPath:indexPath];
            self.licenseTextField = fieldCell.textField;

            self.licenseTextField.placeholder = @"Registreringsnummer";
            self.licenseTextField.text = self.mileage.vehicleRegistrationNumber;
            self.licenseTextField.delegate = self;
            self.licenseTextField.enabled = !self.mileage.isSent.boolValue;
            
            fieldCell.theKey = @"vehicleRegistrationNumber";
            fieldCell.textField.tag = ftLicense;
            cell = fieldCell;
        }
            break;
            
        case sectionRemark:
        {
            FieldTableViewCell *fieldCell = [tableView dequeueReusableCellWithIdentifier:@"remark cell" forIndexPath:indexPath];
            self.commentTextView = fieldCell.textView;
            
            self.commentTextView.text = self.mileage.comments;
            self.commentTextView.tag = ftComment;
            self.commentTextView.delegate = self;
            self.commentTextView.editable = !self.mileage.isSent.boolValue;
            
            self.commentPlaceHolder = fieldCell.placeHolder;
            self.commentPlaceHolder.attributedText = [[NSAttributedString alloc] initWithString:@"Kommentar" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f],NSForegroundColorAttributeName:[UIColor colorWithWhite:0.75f alpha:1]}];
            self.commentPlaceHolder.tag = ftComment;
            
            [self textViewDidChange:self.commentTextView];
            fieldCell.theKey = @"comments";
            
            cell = fieldCell;
        }
            break;
            
        default:
            break;
    }
    
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:sectionLicense]]) {
        return 122.0f;
    } else if ([indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:sectionDate]] ||
               [indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:sectionTemplate]]){
        return 162;
    }
    
    return 44.0f;
}

- (BOOL) tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    
    if (indexPath.section == sectionVia && !self.mileage.isSent.boolValue) {
        UIButton *button = [self.viaButtons objectAtIndex:indexPath.row];
        if (!button.enabled && self.reversegeocoding > 0) {
            return NO;
        }
        return YES;
    }
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == sectionVia) {
        KMDIntermidiatePoint *intermidiatePoint = [self.mileage.intermidiatePoints objectAtIndex:indexPath.row];
        
        [self.managedObjectContext deleteObject:intermidiatePoint];
        [self.managedObjectContext save:nil];
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveManagedDocument];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionVia] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark PickerView
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    return self.templates.count + 1;
}


- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view{
    UILabel *label = (UILabel *)view;
    if (!label) {
        label = [[UILabel alloc] init];
        label.numberOfLines = 0;
        label.font = [UIFont systemFontOfSize:16.0];
        label.textAlignment = NSTextAlignmentCenter;
    }
    if (row == 0) {
        label.text = @"-";
    } else {
        KMDTemplate *template = [self.templates objectAtIndex:row - 1];
        label.text =  template.templateName;
    }
    
    return label;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    if (row == 0) {
        return @"-";
    }
    
    KMDTemplate *template = [self.templates objectAtIndex:row - 1];
    return template.templateName;
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (!self.templates || self.templates.count == 0) {
        return;
    }
    
    if (row == 0) {
        self.mileage.templateID = nil;
        self.mileage.templateName = nil;
    } else {
        KMDTemplate *template = [self.templates objectAtIndex:row - 1];
        self.mileage.templateName = template.templateName;
        self.mileage.templateID = template.templateID;
    }
    [self updateSubmitButtonValid];
    self.showTemplateSelector = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionTemplate] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark TextField

- (void)textFieldDidBeginEditing:(UITextField *)textField{
    self.keyboardToolbar.delegate = self;
    self.keyboardToolbar.suggestions = nil;
    
//    CGRect rect  = self.view.bounds;
//    UIGraphicsBeginImageContext(rect.size);
//    [self.view drawViewHierarchyInRect:rect afterScreenUpdates:YES];
//    UIImage *blurBackground = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    self.keyboardToolbar.backgroundImage = [blurBackground applyLightEffect];
    
    
    if (textField == self.purposeTextField) {
        self.keyboardToolbar.key = @"purpose";
    } else if (textField == self.fromTextField){
        self.keyboardToolbar.key = @"from";
    } else if (textField == self.toTextField){
        self.keyboardToolbar.key = @"to";
    } else if (textField.tag >= ftVia){
        self.keyboardToolbar.key = @"via";
        self.currentVia = textField;
    } else if (textField == self.licenseTextField){
        self.keyboardToolbar.key = @"license";
    }  else {
        self.keyboardToolbar.key = nil;
    }
    
    if (textField == self.distanceTextField) {
        textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    }
    
    self.currentFirstResponder = textField;
    
    textField.inputAccessoryView = self.keyboardToolbar;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if (textField == self.purposeTextField) {
        [self.fromTextField becomeFirstResponder];
    } else if (textField == self.fromTextField){
        [self.toTextField becomeFirstResponder];
    } else if (textField == self.toTextField){
        [self.distanceTextField becomeFirstResponder];
    } else if (textField == self.distanceTextField){
        [self.licenseTextField becomeFirstResponder];
    } else if (textField.tag >= ftVia){
        [self.toTextField becomeFirstResponder];
    } else if (textField == self.distanceTextField){
        [textField resignFirstResponder];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage])
    {
        return NO;
    }

    if (textField == self.fromTextField ||
        textField == self.toTextField ||
        textField.tag >= ftVia) {
        
        if (textField.text.length > 0) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startAutoComplete:) object:textField];
            
            [self performSelector:@selector(startAutoComplete:) withObject:textField afterDelay:0.15f];
        }
    } else if (textField == self.licenseTextField){
        if (textField.text.length + string.length > 9) {
            return NO;
        }
    }
    [self updateSubmitButtonValid];
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField{
    self.keyboardToolbar.suggestions = nil;
    
    if (textField.tag >= ftVia) {
        KMDIntermidiatePoint *via = [self.mileage.intermidiatePoints objectAtIndex:textField.tag - ftVia];
        via.intermidiateAddress = nil;
        [self calculateDistance:nil];
    }
    
    return YES;
}

- (IBAction)startAutoComplete:(UITextField *)textField{
    [KMDGeocoder autoComplete:textField.text location:self.currentLocation completionBlock:^(NSArray *suggestions) {
        self.keyboardToolbar.suggestions = suggestions;
        if (textField == self.fromTextField) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sectionFrom] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if (textField == self.toTextField){
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sectionTo] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        } else if (textField.tag >= ftVia){
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:textField.tag-ftVia inSection:sectionVia] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        
    }];
}




- (void)textFieldDidEndEditing:(UITextField *)textField{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(startAutoComplete:) object:textField];
    
    if (textField.text.length == 0) {
        textField.text = nil;
    }
    
    
    if (textField == self.purposeTextField) {
        self.mileage.reason = textField.text;
        [[NSUserDefaults standardUserDefaults] setValue:self.mileage.reason forKey:@"lastUsed.purpose"];
    } else if (textField == self.fromTextField){
        self.mileage.startAddress = textField.text;
        [self calculateDistance:nil];
    } else if (textField == self.toTextField){
        self.mileage.endAddress = textField.text;
        [self calculateDistance:nil];
    } else if (textField.tag >= ftVia){
        NSInteger idx = textField.tag -ftVia;
        KMDIntermidiatePoint *intermidiatePoint = [self.mileage.intermidiatePoints objectAtIndex:idx];
        intermidiatePoint.intermidiateAddress = textField.text;
        [self calculateDistance:nil];
    } else if (textField == self.distanceTextField){
        if (self.mileage.distanceOfTripInKilometers != [NSNumber numberWithDouble:textField.text.doubleValue]) {
            self.manualDistance = YES;
            textField.attributedText = [[NSAttributedString alloc] initWithString:textField.text attributes:@{NSForegroundColorAttributeName:[UIColor blackColor]}];
        }
        self.mileage.distanceOfTripInKilometers = [NSNumber numberWithDouble:textField.text.doubleValue];
    } else if (textField == self.licenseTextField){
        self.mileage.vehicleRegistrationNumber = textField.text;
        [[NSUserDefaults standardUserDefaults] setValue:self.mileage.vehicleRegistrationNumber forKey:@"lastUsed.license"];
    }
    
    if (textField.text.length > 0 && self.keyboardToolbar.key) {
        [self.keyboardToolbar updateListWithString:textField.text];
    }
    [self updateSubmitButtonValid];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark TextView
- (void)textViewDidBeginEditing:(UITextView *)textView{
    self.currentFirstResponder = textView;
    //    self.keyboardToolbar.key = @"comment";
    textView.inputAccessoryView = self.keyboardToolbar;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text{
    if ([[[textView textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textView textInputMode] primaryLanguage])
    {
        return NO;
    }
    
    
    return YES;
}
- (void)textViewDidChange:(UITextView *)textView{
    switch (textView.tag) {
        case ftComment:
            if (self.commentPlaceHolder.alpha > 0 && textView.text.length > 0) {
                [UIView animateWithDuration:0.25f animations:^{
                    self.commentPlaceHolder.alpha = 0;
                }];
            } else if (self.commentPlaceHolder.alpha == 0 && textView.text.length == 0){
                [UIView animateWithDuration:0.25f animations:^{
                    self.commentPlaceHolder.alpha = 1;
                }];
            }
            
            break;
            
        default:
            break;
    }
    [self updateSubmitButtonValid];
    
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if (textView.text.length == 0) {
        textView.text = nil;
    }
    self.mileage.comments = textView.text;
    [self updateSubmitButtonValid];
}

#pragma mark KeyboardToolbar
- (void)keyboardToolbarValue:(NSString *)value forKey:(NSString *)key{
    if ([key isEqualToString:@"purpose"]) {
        self.purposeTextField.text = value;
        [self.fromTextField becomeFirstResponder];
    } else if ([key isEqualToString:@"from"]){
        self.fromTextField.text = value;
        [self.toTextField becomeFirstResponder];
    } else if ([key isEqualToString:@"via"]){
        self.currentVia.text = value;
        [self.toTextField becomeFirstResponder];
    } else if ([key isEqualToString:@"to"]){
        self.toTextField.text = value;
        [self.distanceTextField becomeFirstResponder];
    } else if ([key isEqualToString:@"license"]){
        self.licenseTextField.text = value;
        [self.commentTextView becomeFirstResponder];
    } else {
        [self keyboardToolbarDismissKeyboard];
    }
    [self updateSubmitButtonValid];
}

- (void)keyboardToolbarDismissKeyboard{
    [self.purposeTextField resignFirstResponder];
    [self.fromTextField resignFirstResponder];
    [self.viaTextFields enumerateObjectsUsingBlock:^(UITextView *textView, NSUInteger idx, BOOL *stop) {
        [textView resignFirstResponder];
    }];
    [self.toTextField resignFirstResponder];
    [self.distanceTextField resignFirstResponder];
    [self.licenseTextField resignFirstResponder];
    [self.commentTextView resignFirstResponder];
}

#pragma mark Location Manager
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    self.currentLocation = [locations lastObject];
    
    BOOL enableReverseGeocoding = self.currentLocation.horizontalAccuracy < 100 && !self.mileage.isSent.boolValue;
    
    if (self.fromButton.enabled != enableReverseGeocoding && self.reversegeocoding == 0) {
        [self.fromButton setEnabled:enableReverseGeocoding];
        [self.toButton setEnabled:enableReverseGeocoding];
        [self.viaButtons enumerateObjectsUsingBlock:^(UIButton *button, NSUInteger idx, BOOL *stop) {
            button.enabled = enableReverseGeocoding;
        }];
    }
    
    
}

#pragma mark geocoder
- (void)geocoderDidFindAddress:(NSString *)address forKey:(NSString *)key{
    UIButton *button;
    if ([key isEqualToString:@"from"]) {
        button = self.fromButton;
        self.mileage.startAddress = address;
        self.fromTextField.text = address;
    } else if ([key isEqualToString:@"to"]){
        button = self.toButton;
        self.mileage.endAddress = address;
        self.toTextField.text = address;
    }
    
    
    [button.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[UIActivityIndicatorView class]]) {
            [obj removeFromSuperview];
            *stop = YES;
        }
    }];
    button.enabled = YES;
    [self updateSubmitButtonValid];
}





#pragma mark - Notifications
#pragma mark MapPoint
- (void)mapPointDidUpdateAddress:(NSNotification *)notification{
    if ([notification.object isKindOfClass:[KMDMapPoint class]]) {
        KMDMapPoint *mapPoint = notification.object;
        UIButton *button;
        switch (mapPoint.type) {
            case mptStart:
                button = self.fromButton;
                self.fromTextField.text = mapPoint.address;
                self.mileage.endAddress = mapPoint.address;
                break;
                
            case mptEnd:
                button = self.toButton;
                self.toTextField.text = mapPoint.address;
                self.mileage.endAddress = mapPoint.address;
                break;
                
            case mptVia:{
                button = [self.viaButtons objectAtIndex:mapPoint.index];
                UITextField *textField = [self.viaTextFields objectAtIndex:mapPoint.index];
                textField.text = mapPoint.address;
                KMDIntermidiatePoint *intermidiatePoint = [self.mileage.intermidiatePoints objectAtIndex:mapPoint.index];
                intermidiatePoint.intermidiateAddress = mapPoint.address;
            }
                break;
                
            default:
                break;
        }
        self.reversegeocoding --;
        
        [button.subviews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UIActivityIndicatorView class]]) {
                [obj removeFromSuperview];
                *stop = YES;
            }
        }];
        button.enabled = YES;
        [self calculateDistance:nil];
    }
}

#pragma mark - Navigation
- (IBAction)fromReverseGeocode:(UIButton *)sender{
    self.reversegeocoding ++;
    self.locationManager.activityType = CLActivityTypeAutomotiveNavigation;
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    
    sender.enabled = NO;
    UIActivityIndicatorView *a = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    [sender addSubview:a];
    [a startAnimating];
    
    MapPointType mpt;
    NSInteger idx = 0;
    
    switch ((FieldTag)sender.tag) {
        case ftFrom:
            mpt = mptStart;
            break;
            
        case ftTo:
            mpt = mptEnd;
            break;
            
        default:
            mpt = mptVia;
            idx = sender.tag - ftVia;
            break;
    }
    
    
    KMDMapPoint *mapPoint  = [KMDMapPoint mapPointWithLocation:self.currentLocation type:mpt index:idx];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointDidUpdateAddress:) name:mapPointDidUpdateNotification object:mapPoint];
    
    [self updateSubmitButtonValid];
}



- (IBAction)calculateDistance:(UIButton *)sender{
    
    self.distanceTextField.text = @"Beregner afstand";
    
    [KMDGeocoder calculateDistanceOnMileage:self.mileage completionBlock:^(double distance, NSError *error) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        
        if (!sender && self.manualDistance) {
            if (self.distanceTextField.text.integerValue != (NSInteger)distance/1000) {
                
                self.distanceTextField.attributedText = [[NSAttributedString alloc] initWithString:self.distanceTextField.text attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}];
            }
        } else {
            self.manualDistance = NO;
            self.distanceTextField.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%.2f km",distance/1000] attributes:@{NSForegroundColorAttributeName: [UIColor blackColor]}];;
            self.mileage.distanceOfTripInKilometers = [NSNumber numberWithFloat:[self.distanceTextField.text floatValue]];
        }
    }];
    
    [self updateSubmitButtonValid];
}

- (IBAction)addViaPoint:(id)sender{
    KMDIntermidiatePoint *newIntermidiatePoint = [NSEntityDescription insertNewObjectForEntityForName:[KMDIntermidiatePoint entityName] inManagedObjectContext:self.managedObjectContext];
    newIntermidiatePoint.onMileage = self.mileage;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionVia] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    
    BOOL isViaVisible = NO;
    for (id obj in self.tableView.visibleCells) {
        
        if ([[self.tableView indexPathForCell:obj] isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionLicense]]) {
            isViaVisible = YES;
            break;
        }
    };
    
    if (!isViaVisible) {
        
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.mileage.intermidiatePoints.count-1 inSection:sectionVia] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    [self updateSubmitButtonValid];
}


- (IBAction)datePickerValueChanged:(UIDatePicker *)sender{
    self.mileage.depatureTimestamp = sender.date;
    
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:sectionDate]] withRowAnimation:UITableViewRowAnimationFade];
    
}

- (void)fieldTableViewDidUpdateText:(NSString *)value forKey:(NSString *)key tag:(NSInteger)tag{
    if ([key isEqualToString:@"via"]) {
        KMDIntermidiatePoint *intermidiatePoint = [self.mileage.intermidiatePoints objectAtIndex:tag];
        intermidiatePoint.intermidiateAddress = value;
        
    } else {
        
        if (!key) {
            return;
        }
        
        NSAttributeType attributeType = [[[self.mileage.entity attributesByName] objectForKey:key] attributeType];
        
        switch (attributeType) {
            case NSStringAttributeType:
                [self.mileage setValue:value forKey:key];
                break;
                
            case NSInteger16AttributeType:
            case NSInteger32AttributeType:
            case NSInteger64AttributeType:
                [self.mileage setValue:[NSNumber numberWithInteger:value.integerValue] forKey:key];
                break;
                
            case NSDoubleAttributeType:
            case NSFloatAttributeType:
            case NSDecimalAttributeType:
                [self.mileage setValue:[NSNumber numberWithDouble:value.doubleValue] forKey:key];
                break;
            default:
                break;
        }
        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if (self.mileage.isSent.boolValue) {
        return;
    }
    
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionDate]]) {
        self.showDateSelector = !self.showDateSelector;
        [self keyboardToolbarDismissKeyboard];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionDate] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (self.showDateSelector) {
            BOOL isSelectorVisible = NO;
            for (id obj in self.tableView.visibleCells) {
                
                if ([[self.tableView indexPathForCell:obj] isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionTemplate]]) {
                    isSelectorVisible = YES;
                    break;
                }
            };
            
            if (!isSelectorVisible) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:sectionDate] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
    } else if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionTemplate]]){
        self.showTemplateSelector = !self.showTemplateSelector;
        [self keyboardToolbarDismissKeyboard];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionTemplate] withRowAnimation:UITableViewRowAnimationAutomatic];
        if (self.showTemplateSelector) {
            if (self.showTemplateSelector && !self.mileage.templateID) {
                KMDTemplate *template = [self.templates firstObject];
                self.mileage.templateID = template.templateID;
                self.mileage.templateName = template.templateName;
            }
            
            BOOL isSelectorVisible = NO;
            for (id obj in self.tableView.visibleCells) {
                
                if ([[self.tableView indexPathForCell:obj] isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionLicense]]) {
                    isSelectorVisible = YES;
                    break;
                }
            };
            
            if (!isSelectorVisible) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:sectionTemplate] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
    }
}

- (IBAction)submit:(id)sender{
    if (self.mileage.isValid) {
        [self.managedObjectContext save:nil];
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveManagedDocument];
        self.mileage.isSent = @YES;
        [self.mileage submitMileageToBackend];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (IBAction)deleteDraft:(id)sender{
    [self.managedObjectContext deleteObject:self.mileage];
    [self.managedObjectContext.undoManager removeAllActions];
    self.mileage = nil;
    [self.navigationController popViewControllerAnimated:YES];
}

@end
