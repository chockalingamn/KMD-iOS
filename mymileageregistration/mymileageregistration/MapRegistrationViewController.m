//
//  MapRegistrationViewController.m
//  mymileageregistration
//
//  Created by Per Friis on 03/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import MapKit;
#import "KMDKeyboardToolbar.h"
#import "KMDIntermidiatePoint+utility.h"
#import "KMDMapPoint.h"
#import "MapRegistrationViewController.h"
#import "UIImage+ImageEffects.h"
#import "KMDMileageTableViewCell.h"
#import "KMDGeocoder.h"
#import "KMDTemplate+utility.h"

typedef NS_ENUM(NSInteger, Sections){
    sectionMap,
    sectionPurpose,
    sectionTemplate,
    sectionLicense,
    sectionRemark
};

@interface MapRegistrationViewController ()<MKMapViewDelegate, UITextFieldDelegate, UITextViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,KMDKeyboardToolbarDelegate,UIAlertViewDelegate>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UITextField *purposTextField;
@property (nonatomic, weak) IBOutlet UIButton *templateButton;
@property (nonatomic, weak) IBOutlet UIView *pickerContainerView;
@property (nonatomic, weak) IBOutlet UIView *containerView;
@property (nonatomic, weak) IBOutlet UITextField *licencePlateTextField;
@property (nonatomic, weak) IBOutlet UITextView *remarkTextView;
@property (nonatomic, weak) IBOutlet UILabel *remarkPlaceHolder;
@property (nonatomic, weak) IBOutlet UIPickerView *templatePickerView;


@property (nonatomic, weak) IBOutlet KMDKeyboardToolbar *keyboardToolbar;

@property (nonatomic, strong) NSMutableArray *mapPoints;

@property (nonatomic, readonly) AppDelegate *appDelegate;
@property (nonatomic, readonly) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, readwrite) BOOL showTemplatePicker;

@property (nonatomic, readonly) NSArray *templates;

@end

@implementation MapRegistrationViewController
#pragma mark - Properties
@synthesize templates = _templates;
- (NSArray *)templates{
    if (!_templates) {
        _templates = [KMDTemplate templatesInManagedObjectContext:self.appDelegate.managedObjectContext];
    }
    return _templates;
}

- (void)setMileage:(KMDMileage *)mileage{
    _mileage = mileage;
    [self updateView];
}



- (NSMutableArray *)mapPoints{
    if (!_mapPoints) {
        _mapPoints = [[NSMutableArray alloc] init];
    }
    return _mapPoints;
}

- (AppDelegate *)appDelegate{
    return (AppDelegate *)[UIApplication sharedApplication].delegate;
}

- (NSManagedObjectContext *)managedObjectContext{
    return self.appDelegate.managedObjectContext;
}

#pragma mark - Utility
- (void)updateView{
    self.purposTextField.text = _mileage.reason;
    
    if (_mileage.templateName.length > 0) {
        [self.templateButton setTitle:_mileage.templateName forState:UIControlStateNormal];
        self.templateButton.titleLabel.textColor = [UIColor blackColor];
    }
    
    self.licencePlateTextField.text = _mileage.vehicleRegistrationNumber;
    
    self.remarkTextView.text = _mileage.comments;
    [self textViewDidChange:self.remarkTextView];
    
    if (!_mapPoints) {
        if (_mileage.startAddress) {
            KMDMapPoint *start = [[KMDMapPoint alloc] initWithAddress:_mileage.startAddress type:mptStart];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointUpdated:) name:mapPointDidUpdateNotification object:start];
            [self.mapPoints addObject:start];
        }
        if (_mileage.intermidiatePoints.count > 0) {
            
            [_mileage.intermidiatePoints enumerateObjectsUsingBlock:^(KMDIntermidiatePoint *obj, NSUInteger idx, BOOL *stop) {
                KMDMapPoint *viaPoint = [[KMDMapPoint alloc] initWithAddress:obj.intermidiateAddress type:mptVia];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointUpdated:) name:mapPointDidUpdateNotification object:viaPoint];
                [self.mapPoints addObject: viaPoint];
            }];
        }
        
        if (_mileage.endAddress) {
            KMDMapPoint *endPoint =[[KMDMapPoint alloc] initWithAddress:_mileage.endAddress type:mptEnd];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointUpdated:) name:mapPointDidUpdateNotification object:endPoint];
            [self.mapPoints addObject:endPoint];
        }
    }
    
    if (_mapPoints) {
        [self.mapView addAnnotations:self.mapPoints];
    }
    
    [self.managedObjectContext.undoManager disableUndoRegistration];
    
    [self updateSubmitButtonValid];
}

- (void)updateSubmitButtonValid{
    if ([self.navigationItem.rightBarButtonItem.title isEqualToString:@"Send"]) {
        [self.navigationItem.rightBarButtonItem setEnabled:self.mileage.isValid];
    }    
}

- (void)viewAllAnnotations{
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in _mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0.1, 0.1);
        zoomRect = MKMapRectUnion(zoomRect, pointRect);
    }
    [_mapView setVisibleMapRect:zoomRect animated:YES];
}


- (void) calculateDistance{
    [KMDGeocoder calculateDistanceOnMileage:self.mileage completionBlock:^(double distance, NSError *error) {
        if (distance >= 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
            self.title = [NSString stringWithFormat:@"%.2f km",distance/1000];
                self.mileage.distanceOfTripInKilometers = [NSNumber numberWithFloat:distance/1000];
            });
        }
    }];
    
}

#pragma mark - view lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Start" style:UIBarButtonItemStylePlain target:self action:@selector(addStartPoint:)] animated:YES];
    
//    [self.appDelegate.locationManager startUpdatingLocation];
    self.tableView.tableFooterView = [[UIView alloc] init];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self updateView];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    [self.managedObjectContext.undoManager removeAllActions];
}


- (void)viewWillDisappear:(BOOL)animated{
 
    if (!self.mileage.isSent.boolValue){// && self.managedObjectContext.undoManager.canUndo) {
        self.appDelegate.editedMileage = self.mileage;
    } else {
        self.appDelegate.editedMileage = nil;
    }

    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - delegate
- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView{
    return 5;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case sectionTemplate:
            if (self.showTemplatePicker) {
                return 2;
            }
            return 1;
            
        default:
            return 1;
            break;
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    KMDMileageTableViewCell *cell;
    switch (indexPath.section) {
        case sectionPurpose:
            cell = [tableView dequeueReusableCellWithIdentifier:@"textfield cell" forIndexPath:indexPath];
            self.purposTextField = cell.textField;
            self.purposTextField.text = self.mileage.reason;
            self.purposTextField.placeholder = @"Formål";
            self.purposTextField.delegate = self;
            break;
            
        case sectionMap:
            cell = [tableView dequeueReusableCellWithIdentifier:@"map cell" forIndexPath:indexPath];
            self.mapView = cell.mapView;
            self.mapView.showsUserLocation = YES;
            self.mapView.delegate = self;
            break;
            
        case sectionTemplate:
            if (indexPath.row == 0) {
                cell = [tableView dequeueReusableCellWithIdentifier:@"standard cell"];
                cell.textLabel.attributedText = self.mileage.displayTeamplateName;
            } else if (indexPath.row == 1){
                cell = [tableView dequeueReusableCellWithIdentifier:@"picker cell"];
                self.templatePickerView = cell.pickerView;
                self.templatePickerView.dataSource = self;
                self.templatePickerView.delegate = self;
                [self.templatePickerView performSelector:@selector(reloadAllComponents) onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
            }
            break;
            
        case sectionLicense:
            cell = [tableView dequeueReusableCellWithIdentifier:@"textfield cell" forIndexPath:indexPath];
            self.licencePlateTextField = cell.textField;
            self.licencePlateTextField.text = self.mileage.vehicleRegistrationNumber;
            self.licencePlateTextField.placeholder = @"Registreringsnummer";
            self.licencePlateTextField.delegate = self;
            break;
            
        case sectionRemark:
            cell = [tableView dequeueReusableCellWithIdentifier:@"textview cell" forIndexPath:indexPath];
            self.remarkTextView = cell.textView;
            self.remarkTextView.delegate = self;
            self.remarkPlaceHolder = cell.textViewPlaceholderLabel;
            self.remarkPlaceHolder.text = @"Kommentar";
            self.remarkTextView.text = self.mileage.comments;
            [self textViewDidChange:self.remarkTextView];
            break;
            
        default: // this should never happens
            cell = [tableView dequeueReusableCellWithIdentifier:@"standard cell" forIndexPath:indexPath];
            cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Please contact KMD, this is a error" attributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]}];
            break;
    }
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionMap]]) {
        if (CGRectGetHeight([UIScreen mainScreen].bounds) > 480.0f){
            return 280.0f;
        } else {
            return 200.0f;
        }
    } else if ([indexPath isEqual:[NSIndexPath indexPathForRow:1 inSection:sectionTemplate] ]){
        return 162.0f;
    } else if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionRemark] ]){
        return 82.0f;
    }
    return 44.0f;
}


















#pragma mark MapView
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation{
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    MKPinAnnotationView * av = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
    if (!av) {
        av = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotation"];
    }
    
    if ([annotation isKindOfClass:[KMDMapPoint class]]) {
        KMDMapPoint *mappoint = annotation;
        switch (mappoint.type) {
            case mptStart:
                av.pinColor = MKPinAnnotationColorGreen;
                break;
                
            case mptVia:
                av.pinColor = MKPinAnnotationColorPurple;
                break;
                
            case mptEnd:
                av.pinColor = MKPinAnnotationColorRed;
                break;
                
            default:
                break;
        }
    }
    av.canShowCallout = YES;

    return av;
    
}


#pragma mark TextField
- (void)textFieldDidBeginEditing:(UITextField *)textField{
    if (textField == self.purposTextField) {
        self.keyboardToolbar.key = @"purpose";
        
    } else if (textField == self.licencePlateTextField){
        self.keyboardToolbar.key = @"license";
    }
    
    self.keyboardToolbar.delegate = self;
    textField.inputAccessoryView = self.keyboardToolbar;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    if ([[[textField textInputMode] primaryLanguage] isEqualToString:@"emoji"] || ![[textField textInputMode] primaryLanguage])
    {
        return NO;
    }
    
    if (textField == self.licencePlateTextField){
        if (textField.text.length + string.length > 9) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    [textField resignFirstResponder];
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField{
    if (textField.text.length == 0) {
        textField.text = nil;
    }
    
    if (textField == self.purposTextField) {
        self.mileage.reason = textField.text;
        [[NSUserDefaults standardUserDefaults] setValue:self.mileage.reason forKey:@"lastUsed.purpose"];
    } else if (textField == self.licencePlateTextField){
        self.mileage.vehicleRegistrationNumber = textField.text;
        [[NSUserDefaults standardUserDefaults] setValue:self.mileage.vehicleRegistrationNumber forKey:@"lastUsed.license"];
    }
    if (textField.text.length > 0) {
        [self.keyboardToolbar updateListWithString:textField.text];
    }
    [self updateSubmitButtonValid];
}


#pragma mark TextView
- (void)textViewDidBeginEditing:(UITextView *)textView{
    self.keyboardToolbar.key = nil;
    self.keyboardToolbar.delegate = self;
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
    if (textView == self.remarkTextView) {
        if (textView.text.length > 0 && self.remarkPlaceHolder.alpha > 0) {
            [UIView animateWithDuration:0.1f animations:^{
                self.remarkPlaceHolder.alpha = 0;
            }];
        } else if (textView.text.length == 0 && self.remarkPlaceHolder.alpha == 0){
            [UIView animateWithDuration:0.1f animations:^{
                self.remarkPlaceHolder.alpha = 1;
            }];
        }
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    if (textView.text.length == 0) {
        textView.text = nil;
    }
    self.mileage.comments = textView.text;
    [self updateSubmitButtonValid];
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

#pragma mark PickerView - delegate
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
    self.showTemplatePicker = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionTemplate] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateSubmitButtonValid];
}



#pragma mark - notifications
#pragma mark MapPoint
- (void)mapPointUpdated:(NSNotification *) notification{
    if ([notification.object isKindOfClass:[KMDMapPoint class]]) {
        KMDMapPoint *mapPoint = notification.object;
        switch (mapPoint.type) {
            case mptStart:
                self.mileage.startAddress = mapPoint.address;
                break;
                
            case mptEnd:
                self.mileage.endAddress = mapPoint.address;
                break;
                
            case mptVia:{
                KMDIntermidiatePoint *intermidatePoint = [self.mileage.intermidiatePoints objectAtIndex:mapPoint.index];
                intermidatePoint.intermidiateAddress = mapPoint.address;
            }
            default:
                break;
        }

        [self.mapView selectAnnotation:mapPoint animated:YES];

    }
   
    [self calculateDistance];
    [self updateSubmitButtonValid];
}


#pragma mark keyboardToolbar


- (void)keyboardToolbarValue:(NSString *)value forKey:(NSString *)key{
    if ([key isEqualToString:@"purpose"]) {
        self.purposTextField.text = value;
        [self.purposTextField resignFirstResponder];
    } else if ([key isEqualToString:@"license"]){
        self.licencePlateTextField.text = value;
        [self.licencePlateTextField resignFirstResponder];
    }
    [self updateSubmitButtonValid];
}


- (void)keyboardToolbarDismissKeyboard{
    [self.purposTextField resignFirstResponder];
    [self.licencePlateTextField resignFirstResponder];
    [self.remarkTextView resignFirstResponder];
}





#pragma mark - user interaction

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self.purposTextField resignFirstResponder];
    [self.licencePlateTextField resignFirstResponder];
    [self.remarkTextView resignFirstResponder];
    
    if ([indexPath isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionTemplate]]) {
        self.showTemplatePicker = !self.showTemplatePicker;
        
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionTemplate] withRowAnimation:UITableViewRowAnimationAutomatic];
        
        BOOL isSelectorVisible = NO;
        for (id obj in self.tableView.visibleCells) {
            
            if ([[self.tableView indexPathForCell:obj] isEqual:[NSIndexPath indexPathForRow:0 inSection:sectionTemplate+1]]) {
                isSelectorVisible = YES;
                break;
            }
        };

        
        if (!isSelectorVisible) {
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:sectionTemplate] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
    }
}

- (IBAction)showTemplatePicker:(id)sender{
    [self keyboardToolbarDismissKeyboard];
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view drawViewHierarchyInRect:self.view.bounds afterScreenUpdates:YES];
    UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
 
    CGRect pickerViewRect = self.pickerContainerView.frame;
    pickerViewRect.origin.y = CGRectGetHeight(self.view.bounds);
    self.pickerContainerView.frame = pickerViewRect;
    self.pickerContainerView.alpha = 0;
    pickerViewRect.origin.y = CGRectGetHeight(self.view.bounds) - CGRectGetHeight(pickerViewRect);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([viewImage CGImage], pickerViewRect);
    
    UIImage *img = [[UIImage imageWithCGImage:imageRef] applyLightEffect];
    self.pickerContainerView.backgroundColor = [UIColor colorWithPatternImage:img];
    
    
    [self.view addSubview:self.pickerContainerView];
    [UIView animateWithDuration:0.5f animations:^{
        self.pickerContainerView.frame = pickerViewRect;
        self.pickerContainerView.alpha = 1;
    }];
    
}

- (IBAction)hideTemplatePicker:(id)sender{
    if (sender) { // then animate
        CGRect rect = self.pickerContainerView.frame;
        rect.origin.y = CGRectGetHeight(self.view.frame);
        [UIView animateWithDuration:0.5f animations:^{
            self.pickerContainerView.alpha = 0;
            self.pickerContainerView.frame = rect;
        } completion:^(BOOL finished) {
            [self.pickerContainerView removeFromSuperview];
        }];
    } else {
        [self.pickerContainerView removeFromSuperview];
    }
}

- (IBAction)addStartPoint:(id)sender{
    self.mileage.depatureTimestamp = [NSDate date];
    self.title = @"0.00 km";

    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Via" style:UIBarButtonItemStyleDone target:self action:@selector(addViaPoint:)]];
    
    [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Stop" style:UIBarButtonItemStyleDone target:self action:@selector(endPoint:)] animated:YES];
    
    KMDMapPoint *startPoint = [[KMDMapPoint alloc] initWithCoordinate:self.mapView.userLocation.location.coordinate type:mptStart];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointUpdated:) name:mapPointDidUpdateNotification object:startPoint];
    [self.mapView addAnnotation:startPoint];
    [self.mapPoints addObject:startPoint];
}

- (IBAction)addViaPoint:(id)sender{
    CLLocationCoordinate2D coordinate = self.mapView.userLocation.location.coordinate;
    
    NSInteger index = [KMDIntermidiatePoint addIntermidiatePointToMileage:self.mileage withCoordinates:coordinate];
    
    KMDMapPoint *viaPoint = [[KMDMapPoint alloc] initWithCoordinate:self.mapView.userLocation.location.coordinate type:mptVia];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointUpdated:) name:mapPointDidUpdateNotification object:viaPoint];
    viaPoint.index = index;
    
    [self.mapView addAnnotation:viaPoint];
    [self.mapPoints addObject:viaPoint];
}

- (IBAction)endPoint:(id)sender{
    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Send" style:UIBarButtonItemStyleDone target:self action:@selector(submit:)];
    
    KMDMapPoint *endPoint = [[KMDMapPoint alloc] initWithCoordinate:self.mapView.userLocation.location.coordinate type:mptEnd];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mapPointUpdated:) name:mapPointDidUpdateNotification object:endPoint];
    [self.mapView addAnnotation:endPoint];
    [self.mapPoints addObject:endPoint];
    
    [self viewAllAnnotations];
    
    [self updateSubmitButtonValid];
    [self calculateDistance];
}


- (IBAction)submit:(id)sender{
    if (self.mileage.isValid) {
        [self.managedObjectContext save:nil];
        [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveManagedDocument];

        self.mileage.isSent = @YES;
        [self.mileage submitMileageToBackend];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
