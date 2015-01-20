#import "User.h"

//#ifdef DEBUG
static NSString *__currentEnv = @"udv";
//#endif

static User *__currentUser;


@implementation User

@synthesize username = _username;
@synthesize authenticationToken = _authenticationToken;
@synthesize pin = _pin;
@synthesize changePassword = _changePassword;
@synthesize serverVersionNumber = _serverVersionNumber;
@synthesize lastRequestToServer = _lastRequestToServer;


+ (User *)currentUser
{
    return __currentUser;
}


+ (void)setCurrentUser:(User *)user
{
    __currentUser = user;
}


// #ifdef DEBUG
+ (NSString *)currentEnv
{
    return __currentEnv;
}


+ (void)setCurrentEnv:(NSString *)env
{
    __currentEnv = env;
}
// #endif


- (NSURL *)hostname
{
    return [User hostnameFromUsername: self.username];
}


+ (NSURL *)hostnameFromUsername:(NSString *)username
{
    NSString *env = [User getEnv:username];
    NSString *urlString = [NSString stringWithFormat:@"https://%@-mobile.kmd.dk/", env];

    #ifdef DEBUG
    if ([@"localhost" isEqualToString:__currentEnv] )
        urlString = @"http://localhost:9998/";
    #endif

    NSLog(@"Logon environment: %@", urlString);
    return [NSURL URLWithString:urlString];
}

+ (NSURL *)loginHostnameFromUsername:(NSString *)username
{
    NSString *env = [User getEnv:username];
    NSString *urlString = [NSString stringWithFormat:@"https://%@-infra-mobile.kmd.dk/", env];

    #ifdef DEBUG
    if ([@"localhost" isEqualToString:__currentEnv] )
        urlString = @"http://localhost:9998/";
    #endif
    
    NSLog(@"Logon environment: %@", urlString);
    return [NSURL URLWithString:urlString];
}

+ (NSString *)getEnv:(NSString *)username
{
    unichar firstLetterOfTheUsername = [username characterAtIndex:0];
    BOOL isDemoUser = ([[NSCharacterSet characterSetWithCharactersInString:@"XxZz"] characterIsMember:firstLetterOfTheUsername]);
    NSString *env = (isDemoUser) ? @"dem" : @"cap";

    #ifdef DEBUG
    if (![@"prod" isEqualToString:__currentEnv])
        env = __currentEnv;
    #endif

    return env;
}
@end
