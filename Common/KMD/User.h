#import <Foundation/Foundation.h>


#define KMDLoginProtocolAuthenticationTokenKey @"ticket"
#define KMDLoginProtocolVersionNumberKey @"versionNumber"
#define KMDLoginProtocolChangePasswordKey @"changePassword"

/// Session times out if server has not been contacted
/// within 30 min.
///
#define KMDLocalSessionTimeoutInterval 30*60

#define KMDErrorInvalidServerResponse 500

@interface User : NSObject

+ (User *)currentUser;
+ (void)setCurrentUser:(User *)user;

// #ifdef DEBUG
+ (NSString *)currentEnv;
+ (void)setCurrentEnv:(NSString *)env;
// #endif

/// The user's username.
///
@property (nonatomic, copy) NSString *username;


/// The token that should be set on all requests.
///
@property (nonatomic, copy) NSString *authenticationToken;


/// The PIN code used for BigIP authentication.
///
@property (nonatomic, copy) NSString *pin;


/// Indicates if the user has to change password
///
@property (nonatomic) bool changePassword;

/// The maximum required version of the server
///
@property (nonatomic) NSString *serverVersionNumber;

/// Time of the last request to the server
///
/// The field is used to maintain timeout of session
/// on the client side that is different from the
/// server session.
///
@property (copy) NSDate *lastRequestToServer;

/// The host the user should use for communication.
///
/// This is to allow DEMO users to log in.
///
@property (readonly, nonatomic, copy) NSURL *hostname;

+ (NSURL *)hostnameFromUsername:(NSString *)username;
+ (NSURL *)loginHostnameFromUsername:(NSString *)username;

@end
