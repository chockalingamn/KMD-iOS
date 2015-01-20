#import "KMDLoginViewController.h"
#import "KMDChangePasswordViewController.h"
#import "KMDAboutViewController.h"
#import "KMDLoginAPIClient.h"

#import "DejalActivityView.h"
#import "KMD/KMDAppearance.h"

#import "User.h"

#import "KMDChooseEnvironmentViewController.h"


static UIImage *__backgroundImage;
static NSString *__applicationName;
static NSString *__title;

@interface KMDLoginViewController() <UIAlertViewDelegate>
@property (nonatomic, strong) UIAlertView *loginRequestActivityAlertView;
@end


@implementation KMDLoginViewController
{
    __weak IBOutlet UIButton *_loginButton;
#if DEBUG
    __strong UIButton *_envButton;
#endif
    
    // States regarding activity alerts during call to backend.
#define kLoginRequestActivityAlertStateOff 0
#define kLoginRequestActivityAlertStateSendingWithoutCancelOption 1
#define kLoginRequestActivityAlertStateSendingWithCancelOption 2
    
    NSInteger _loginRequestActivityAlertStates;
}

@synthesize delegate = _delegate;
@synthesize isCancelButtonVisible = _isCancelButtonVisible;

@synthesize _usernameTextField;
@synthesize _passwordTextField;
@synthesize _pinCodeTextField;


+ (void)setBackgroundImage:(UIImage *)image
{
    __backgroundImage = image;
}


+ (void)setApplicationName:(NSString *)applicationName
{
    __applicationName = applicationName;
}

+ (void)setTitle:(NSString *)title
{
    __title = title;
}


+ (id)createInstance
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"KMD.bundle/Login" bundle:nil];
    return [storyboard instantiateViewControllerWithIdentifier:@"Login"];
}


+ (UINavigationController *)createInstanceEmbeddedInNavigationViewController
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"KMD.bundle/Login" bundle:nil];
    return [storyboard instantiateInitialViewController];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    UIImageView *backgroundView = [[UIImageView alloc] init];
    
    if (__backgroundImage)
    {
        backgroundView.image = __backgroundImage;
    }
    
    self.tableView.backgroundView = backgroundView;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    if (__title)
    {
        self.navigationItem.title = __title;
    }
    else
    {
        self.navigationItem.title = @"Log ind";
    }
    
    _usernameTextField.textColor = [UIColor blackColor];
    if (self.isCancelButtonVisible)
    {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Annuller" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelClicked:)];
        if (User.currentUser.username && ![User.currentUser.username isEqualToString:@""])
        {
            _usernameTextField.text = User.currentUser.username;
            _usernameTextField.enabled = false;
            _usernameTextField.textColor = [UIColor grayColor];
        }
    }
    
    _loginRequestActivityAlertStates = kLoginRequestActivityAlertStateOff;
    
    // Login Button
    
    _loginButton.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    _loginButton.layer.borderWidth = 0.5f;
    _loginButton.layer.cornerRadius = 5.0f;
    
//    [_loginButton setBackgroundImage:[[UIImage imageNamed:@"KMD.bundle/button_green"] stretchableImageWithLeftCapWidth:13 topCapHeight:23] forState:UIControlStateNormal];
//    [_loginButton setBackgroundImage:[[UIImage imageNamed:@"KMD.bundle/button_green_down"] stretchableImageWithLeftCapWidth:13 topCapHeight:23] forState:UIControlStateHighlighted];
    
#if DEBUG
    _envButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_envButton setAccessibilityLabel:@"EnvButton"];
    [_envButton addTarget:self action:@selector(changeEnvButtonPressed:) forControlEvents:UIControlEventTouchDown];
    _envButton.frame = CGRectMake(10.0, 250.0, 300.0, 40.0);
    CGPoint c = _loginButton.center;
    c.y += CGRectGetHeight(_loginButton.frame) + 8.0f;
    [self.view addSubview:_envButton];
#endif
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _passwordTextField.text = @"";
    
#if DEBUG
    if (!_usernameTextField.text || [_usernameTextField.text isEqualToString:@""]) _usernameTextField.text = @"zabsemp1";
    //@"T04797_A_POR";//@"t4797forman1"
    if (!_passwordTextField.text || [_passwordTextField.text isEqualToString:@""]) _passwordTextField.text = @"Kmd12345";
    if (!_pinCodeTextField.text || [_pinCodeTextField.text isEqualToString:@""]) _pinCodeTextField.text = @"123456";
    // Set env on button
    NSString *buttonText = [NSString stringWithFormat:@"Backend: %@", User.currentEnv];
    [_envButton setTitle:buttonText forState:UIControlStateNormal];
#else
    _usernameTextField.text = [NSUserDefaults.standardUserDefaults objectForKey:@"dk.kmd.username"];
    _pinCodeTextField.text = [NSUserDefaults.standardUserDefaults objectForKey:@"dk.kmd.pinkode"];
    _passwordTextField.text = @""; // To ensure a password is not stored in the text field when going to background.
#endif
    
    // Simulate Text Change to validate input on load.
    
    [self textField:nil shouldChangeCharactersInRange:NSMakeRange(0, 0) replacementString:nil];
    
    self.view.userInteractionEnabled = YES;
    

}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (IBAction)loginTouched:(id)sender
{
    if (_loginRequestActivityAlertStates != kLoginRequestActivityAlertStateOff) {
        return;
    }
    
    NSString *username = _usernameTextField.text;
    NSString *password = _passwordTextField.text;
    NSString *pinCode = _pinCodeTextField.text;
    
    KMDLoginClient *client = [[KMDLoginClient alloc] initWithBaseURL:[User loginHostnameFromUsername:username]];
    
    [DejalBezelActivityView activityViewForView:self.view withLabel:@"Logger ind…"];
    
    _loginRequestActivityAlertStates = kLoginRequestActivityAlertStateSendingWithoutCancelOption;
//    NSTimer *activityAlertTimer = [NSTimer scheduledTimerWithTimeInterval:KMDCancelLoginAttemptTimeInterval target:self selector:@selector(activityAlertTimerTicked:) userInfo:nil repeats:YES];
    
    self.navigationItem.rightBarButtonItem.enabled = NO;
    self.view.userInteractionEnabled = NO;
    
    [client sendUsername:username password:password pin:pinCode applicationName:__applicationName success:^(User *user)
     {
         if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateOff)
         {
             // Request was cancelled.
             return;
         }
         // Remove modal dialogs
         if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateSendingWithCancelOption)
         {
             [_loginRequestActivityAlertView dismissWithClickedButtonIndex:0 animated:YES];
         }
         else if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateSendingWithoutCancelOption)
         {
             [DejalBezelActivityView removeView];
//             [activityAlertTimer invalidate];
         }
         
         User.currentUser = user;
         
         [NSUserDefaults.standardUserDefaults setValue:username forKey:@"dk.kmd.username"];
         [NSUserDefaults.standardUserDefaults setValue:pinCode forKey:@"dk.kmd.pinkode"];
         
         if (user.changePassword)
         {
             [self performSegueWithIdentifier:@"Skift Password" sender:self];
         } else {
             [_delegate loginSuccessful:self user:user];
         }
         _loginRequestActivityAlertStates = kLoginRequestActivityAlertStateOff;
     }
                 failure:^(NSError *error)
     {
         if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateOff)
         {
             // Request was cancelled.
             return;
         }
         // Remove modal dialogs
         if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateSendingWithCancelOption)
         {
             [_loginRequestActivityAlertView dismissWithClickedButtonIndex:0 animated:YES];
         }
         else if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateSendingWithoutCancelOption)
         {
             [DejalBezelActivityView removeView];
//             [activityAlertTimer invalidate];
         }
         
         self.navigationItem.rightBarButtonItem.enabled = YES;
         self.view.userInteractionEnabled = YES;
         
         dispatch_async(dispatch_get_main_queue(), ^{
             // The UI code needs to be executed on the main queue.
             [[[UIAlertView alloc] initWithTitle:@"Fejl" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
         });
         _loginRequestActivityAlertStates = kLoginRequestActivityAlertStateOff;
     }];
}

//- (void)activityAlertTimerTicked:(NSTimer*)timer
//{
//    [timer invalidate];
//    if (_loginRequestActivityAlertStates == kLoginRequestActivityAlertStateSendingWithoutCancelOption)
//    {
//        [DejalBezelActivityView removeViewAnimated:YES];
//        
//        self.loginRequestActivityAlertView = [[UIAlertView alloc] init];
//        self.loginRequestActivityAlertView.title = @"Logger ind...";
//        self.loginRequestActivityAlertView.message = @"Svaret er lang tid om at komme tilbage.\nAfbryd, hvis du ikke ønskert at vente længere.\n\n\n";
//        self.loginRequestActivityAlertView.delegate = self;
//        [self.loginRequestActivityAlertView addButtonWithTitle:@"Afbryd"];
//        self.loginRequestActivityAlertView.tag = 2;
//        [self.loginRequestActivityAlertView show];
//        
//        
//        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
//        indicator.center = CGPointMake(CGRectGetWidth(self.loginRequestActivityAlertView.bounds) / 2, CGRectGetHeight(self.loginRequestActivityAlertView.bounds) - 88);
//        [indicator startAnimating];
//        [self.loginRequestActivityAlertView addSubview:indicator];
//        [self.loginRequestActivityAlertView setNeedsDisplay];
//        
//        _loginRequestActivityAlertStates = kLoginRequestActivityAlertStateSendingWithCancelOption;
//    }
//}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    switch (alertView.tag) {
        case 2: // long response on login
            NSLog(@"%s - cancel login",__PRETTY_FUNCTION__);
            self.navigationItem.rightBarButtonItem.enabled = YES;
            self.view.userInteractionEnabled = YES;
            _loginRequestActivityAlertStates = kLoginRequestActivityAlertStateOff;
            break;
            
        default:
            break;
    }
}

- (void)cancelClicked:(id)sender
{
    [self.delegate loginCancelled:self];
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *username = ([textField isEqual:_usernameTextField]) ? [_usernameTextField.text stringByReplacingCharactersInRange:range withString:string] : _usernameTextField.text;
    NSString *password = ([textField isEqual:_passwordTextField]) ? [_passwordTextField.text stringByReplacingCharactersInRange:range withString:string] : _passwordTextField.text;
    NSString *pinCode = ([textField isEqual:_pinCodeTextField]) ? [_pinCodeTextField.text stringByReplacingCharactersInRange:range withString:string] : _pinCodeTextField.text;
    
    BOOL isValue = YES;

    if (textField == _pinCodeTextField && textField.text.length == 5) {
        textField.text = [textField.text stringByAppendingString:string];
    }
    
    isValue &= ![username isEqualToString:@""];
    isValue &= ![password isEqualToString:@""];
    isValue &= ![pinCode isEqualToString:@""];
    
    [self setLoginButtonEnabled:isValue];
    
    if (textField == _pinCodeTextField && pinCode.length == 6 && isValue) {
        [self loginTouched:nil];
        return NO;
    }

    
    
    return YES;
}


- (BOOL)textFieldShouldClear:(UITextField *)textField
{
    // After clearing the login button is never enabled.
    
    [self setLoginButtonEnabled:NO];
    
    return YES;
}


- (void)setLoginButtonEnabled:(BOOL)enabled
{
    _loginButton.enabled = enabled;
}


#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 16.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    tableView.backgroundColor = [UIColor clearColor];
    tableView.opaque = NO;
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // Select the text field when the cell is clicked.
    
    for (UIView *subview in cell.subviews)
    {
        if ([subview isKindOfClass:UITextField.class])
        {
            [subview becomeFirstResponder];
            break;
        }
    }
    
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"Skift Password"])
    {
        [KMDChangePasswordViewController setBackgroundImage:__backgroundImage];
        [KMDChangePasswordViewController setApplicationName:__applicationName];
        KMDChangePasswordViewController *cpViewController = (KMDChangePasswordViewController *) segue.destinationViewController;
        cpViewController.username = _usernameTextField.text;
        cpViewController.pinCode =_pinCodeTextField.text;
        cpViewController.delegate = _delegate;
    } else if ([segue.identifier isEqualToString:@"about"])
    {
        [KMDAboutViewController setBackgroundImage:__backgroundImage];
        //KMDAboutViewController *aboutVC = (KMDAboutViewController *) segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"coose environment"]){
        [KMDChooseEnvironmentViewController setBacgroundImage:__backgroundImage];
    }
    
}

#if DEBUG
#pragma mark - Change env

-(void)changeEnvButtonPressed:(id)sender
{
    [self performSegueWithIdentifier:@"coose environment" sender:nil];
}
#endif
@end
