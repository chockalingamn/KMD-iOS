#import <UIKit/UIKit.h>

#import "User.h"

/// Time interval before user is offered button
/// to cancel login request.
/// Interval in seconds
///
#define KMDCancelLoginAttemptTimeInterval 10.0

@protocol KMDLoginViewControllerDelegate;


@interface KMDLoginViewController : UITableViewController <UITextFieldDelegate>

@property (nonatomic, weak) id<KMDLoginViewControllerDelegate> delegate;

+ (id)createInstance;
+ (UINavigationController *)createInstanceEmbeddedInNavigationViewController;

/// If set this image will be used for the view's background for every new instance created.
///
+ (void)setBackgroundImage:(UIImage *)image;

/// The application name to identify itself with to the server.
///
+ (void)setApplicationName:(NSString *)applicationName;

/// If set this title will be displayed in the login view's navigation bar.
///
+ (void)setTitle:(NSString *)title;

/// If YES this will show a "Cancel" button on the left side of the navigation controller.
///
/// Default value is NO.
/// When clicked the delegate's loginCancelled is called.
///
@property (nonatomic, assign) BOOL isCancelButtonVisible;


@property (nonatomic, weak) IBOutlet UITextField *_usernameTextField;
@property (nonatomic, weak) IBOutlet UITextField *_passwordTextField;
@property (nonatomic, weak) IBOutlet UITextField *_pinCodeTextField;

@end

@protocol KMDLoginViewControllerDelegate <NSObject>
@optional

- (void)loginSuccessful:(UIViewController *)viewController user:(User *)user;
- (void)loginCancelled:(UIViewController *)viewController;

@end
