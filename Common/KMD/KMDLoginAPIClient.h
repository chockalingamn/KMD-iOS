#import "AFNetworking/AFNetworking.h"


// TODO: This is actually connection lost, but you cannot tell the difference.
#define KMDInvalidPINErrorCode -1005
#define KMDInvalidUsernamePassword 401 // TODO: This should be 401... but its not.
#define KMDInvalidVersion 1266

@class User;


@interface KMDLoginClient : AFHTTPClient

/// Designated Initializer.
///
- (id)initWithBaseURL:(NSURL *)baseURL;

- (void)sendUsername:(NSString *)username password:(NSString *)password pin:(NSString  *)pin applicationName: (NSString *)applicationName success:(void (^)(User *user))successBlock failure:(void (^)(NSError *error))failureBlock;

- (void)sendUsername:(NSString *)username password:(NSString *)password pin:(NSString  *)pin applicationName: (NSString *)applicationName newPassord:(NSString *)aNewPassword success:(void (^)(User *user))successBlock failure:(void (^)(NSError *error))failureBlock;

@end

