//
//  KMDChangePasswordViewController.m
//  KMD Common
//
//  Created by Henning Böttger on 21/11/12.
//  Copyright (c) 2012 KMD A/S. All rights reserved.
//

#import "DejalActivityView.h"

#import "KMDChangePasswordViewController.h"
#import "KMDLoginAPIClient.h"
#import "User.h"

static UIImage *__backgroundImage;
static NSString *__applicationName;

@interface KMDChangePasswordViewController ()

@end

@implementation KMDChangePasswordViewController
{
    __weak IBOutlet UIButton *_changePasswordButton;
}

@synthesize delegate = _delegate;
@synthesize username = _username;
@synthesize pinCode = _pinCode;

@synthesize _currentPasswordTextField;
@synthesize _aNewPasswordTextField;
@synthesize _retypedNewPasswordTextField;


+ (void)setBackgroundImage:(UIImage *)image
{
    __backgroundImage = image;
}

+ (void)setApplicationName:(NSString *)applicationName
{
    __applicationName = applicationName;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSAssert(_delegate != nil, @"A delegate must have been set");
    NSAssert(_username != nil, @"A username must have been set");
    NSAssert(_pinCode != nil, @"A pin code must have been set");

    UIImageView *backgroundView = [[UIImageView alloc] init];
    if (__backgroundImage)
    {
        backgroundView.image = __backgroundImage;
    }
    self.tableView.backgroundView = backgroundView;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    self.navigationItem.title = @"Skift Password";
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Annuller" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelClicked:)];
    
    // Change Password Button
//    [_changePasswordButton setBackgroundImage:[[UIImage imageNamed:@"KMD.bundle/button_green"] stretchableImageWithLeftCapWidth:13 topCapHeight:23] forState:UIControlStateNormal];
//    [_changePasswordButton setBackgroundImage:[[UIImage imageNamed:@"KMD.bundle/button_green_down"] stretchableImageWithLeftCapWidth:13 topCapHeight:23] forState:UIControlStateHighlighted];

    // Simulate Text Change to validate input on load.
    [self textField:nil shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Button delegates

- (IBAction)changePasswordTouched:(id)sender
{
    NSLog(@"Executing change password...");
    NSString *currentPassword = _currentPasswordTextField.text;
    NSString *aNewPassword = _aNewPasswordTextField.text;
    NSString *retypedNewPassword = _retypedNewPasswordTextField.text;
    
    KMDLoginClient *client = [[KMDLoginClient alloc] initWithBaseURL:[User loginHostnameFromUsername:_username]];
    
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Skifter password…"];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.view.userInteractionEnabled = NO;
    
    [client sendUsername:(NSString *)_username password:currentPassword pin:_pinCode applicationName:__applicationName newPassord:aNewPassword success:^(User *user)
     {
         NSLog(@"Succesfully changed password.");
         User.currentUser = user;
         
         [NSUserDefaults.standardUserDefaults setValue:_username forKey:@"dk.kmd.username"];
         [NSUserDefaults.standardUserDefaults setValue:_pinCode forKey:@"dk.kmd.pinkode"];
         
         [DejalActivityView removeView];
         
         dispatch_async(dispatch_get_main_queue(), ^{
             // The UI code needs to be executed on the main queue.
             [[[UIAlertView alloc] initWithTitle:@"Information" message:@"Dit password er ændret" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
         });

         NSLog(@"Calling delegate for succesfull login...");
         [_delegate loginSuccessful:self user:user];
     }
    failure:^(NSError *error)
     {
         [DejalBezelActivityView removeView];
         
         self.navigationItem.rightBarButtonItem.enabled = YES;
         self.view.userInteractionEnabled = YES;
         
         dispatch_async(dispatch_get_main_queue(), ^{
             // The UI code needs to be executed on the main queue.
             [[[UIAlertView alloc] initWithTitle:@"Fejl" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
         });
     }];
    
}

- (void)cancelClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *currentPassword = ([textField isEqual:_currentPasswordTextField]) ? [_currentPasswordTextField.text stringByReplacingCharactersInRange:range withString:string] : _currentPasswordTextField.text;
    NSString *aNewPassword = ([textField isEqual:_aNewPasswordTextField]) ? [_aNewPasswordTextField.text stringByReplacingCharactersInRange:range withString:string] : _aNewPasswordTextField.text;
    NSString *retypedPassword = ([textField isEqual:_retypedNewPasswordTextField]) ? [_retypedNewPasswordTextField.text stringByReplacingCharactersInRange:range withString:string] : _retypedNewPasswordTextField.text;
    
    BOOL doesNewPasswordMatch = [aNewPassword isEqualToString:retypedPassword];
    _retypedNewPasswordTextField.textColor = doesNewPasswordMatch ? [UIColor blackColor] : [UIColor redColor];
    
    BOOL isValue = YES;
    
    isValue &= ![currentPassword isEqualToString:@""];
    isValue &= ![aNewPassword isEqualToString:@""];
    isValue &= ![retypedPassword isEqualToString:@""];
    isValue &= doesNewPasswordMatch;
    
    [self setChangePasswordButtonEnabled:isValue];
    
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    // After clearing the login button is never enabled.
    
    [self setChangePasswordButtonEnabled:NO];
    
    return YES;
}


- (void)setChangePasswordButtonEnabled:(BOOL)enabled
{
    _changePasswordButton.enabled = enabled;
}

@end
