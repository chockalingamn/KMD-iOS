#import "KMDLoginAPIClient.h"

#import "User.h"
#import "Errors.h"


@implementation KMDLoginClient
{
    #define kServicePathLogon          @"/KMD.YH.Mobile.Gateway/LogonService/SAP/Logon"
    #define kServicePathChangePassword @"/KMD.YH.Mobile.Gateway/LogonService/SAP/ChangePassword"
}


- (id)initWithBaseURL:(NSURL *)baseURL
{
    if (self = [super initWithBaseURL:baseURL])
    {
        [self registerHTTPOperationClass:AFJSONRequestOperation.class];
        [self setDefaultHeader:@"Content-Type" value:@"application/json"];
    }

    return self;
}


- (void)sendUsername:(NSString *)username password:(NSString *)password pin:(NSString  *)pin applicationName: (NSString *)applicationName success:(void (^)(User *user))successBlock failure:(void (^)(NSError *error))failureBlock
{
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:kServicePathLogon parameters:nil];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    [request setTimeoutInterval:60];
    
    [request addValue:username forHTTPHeaderField:@"UserName"];
    [request addValue:pin forHTTPHeaderField:@"Pincode"];


    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:username forKey:@"username"];
    [userInfo setValue:password forKey:@"password"];
    [userInfo setValue:applicationName forKey:@"applicationName"];
    [userInfo setValue:@"iOS" forKey:@"os"];
    
    #ifdef DEBUG
    NSLog(@"Login in with userInfo:\n%@", userInfo);
    #endif

    NSError *error;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
    if (error) [Errors fatalError:error];


    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
    {
        NSError *parsingError = nil;
        User *user = [self userWithJSON:JSON error:&parsingError];

        NSError *versionError = nil;
        [self validateServerVersionRquirement:user.serverVersionNumber error:&versionError];
        
        if (parsingError)
        {
            if (failureBlock) failureBlock(parsingError);
        }
        else if (versionError)
        {
            if (failureBlock) failureBlock(versionError);
        }
        else
        {
            user.username = username;
            user.pin = pin;
            user.lastRequestToServer = [NSDate date];

            if (successBlock) successBlock(user);
        }
    }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
    {
        NSError *localError;

        if (response && response.statusCode == KMDInvalidUsernamePassword)
        {
            [self populateError:&localError Code:KMDInvalidUsernamePassword message:@"Brugernavn eller kodeord er ugyldigt."];
        }
        else if (error && error.code == KMDInvalidPINErrorCode)
        {
            [self populateError:&localError Code:KMDInvalidPINErrorCode message:@"Enten er der ingen forbindelse til serveren, eller måske er din PIN-kode forkert."];
        }
        else
        {
            [Errors populateError:&localError withServerError:error response:response json:JSON];
        }
        
        if (failureBlock) failureBlock(localError);
    }];
    

    [self enqueueHTTPRequestOperation:operation];
}

- (void)sendUsername:(NSString *)username password:(NSString *)password pin:(NSString  *)pin applicationName: (NSString *)applicationName newPassord:(NSString *)aNewPassword success:(void (^)(User *user))successBlock failure:(void (^)(NSError *error))failureBlock
{
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" path:kServicePathChangePassword parameters:nil];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData];
    
    [request setTimeoutInterval:20];
    
    [request addValue:username forHTTPHeaderField:@"UserName"];
    [request addValue:pin forHTTPHeaderField:@"Pincode"];
    
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:username forKey:@"username"];
    [userInfo setValue:password forKey:@"password"];
    [userInfo setValue:aNewPassword forKey:@"newPassword"];
    [userInfo setValue:applicationName forKey:@"applicationName"];
    //[userInfo setValue:@"MileageRegistration" forKey:@"applicationName"];
    [userInfo setValue:@"iOS" forKey:@"os"];
    
    NSLog(@"Request: %@", request.description);
    NSLog(@"Base URL: %@", self.baseURL);
    NSLog(@"Sending data: %@", [userInfo description]);
    
    NSError *error;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:userInfo options:0 error:&error];
    NSLog(@"%s - her 2",__PRETTY_FUNCTION__);
    if (error) [Errors fatalError:error];
    
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
    success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON)
         {
             NSError *parsingError = nil;
             User *user = [self userWithJSON:JSON error:&parsingError];

             NSError *versionError = nil;
             [self validateServerVersionRquirement:user.serverVersionNumber error:&versionError];
             
             if (parsingError)
             {
                 if (failureBlock) failureBlock(parsingError);
             }
             else if (versionError)
             {
                if (failureBlock) failureBlock(versionError);
             }
             else
             {
                 user.username = username;
                 user.pin = pin;
                 user.lastRequestToServer = [NSDate date];

                 if (successBlock) successBlock(user);
             }
             
         }
    failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON)
         {
             NSError *localError;
             
             if (response && response.statusCode == KMDInvalidUsernamePassword)
             {
                 [self populateError:&localError Code:KMDInvalidUsernamePassword message:@"Det nuværende password er ugyldigt."];
             }
             else if (error && error.code == KMDInvalidPINErrorCode)
             {
                 [self populateError:&localError Code:KMDInvalidPINErrorCode message:@"Enten er der ingen forbindelse til serveren, eller måske er din PIN-kode forkert."];
             }
             else
             {
                 [Errors populateError:&localError withServerError:error response:response json:JSON];
             }
             
             if (failureBlock) failureBlock(localError);
         }];

    
    [self enqueueHTTPRequestOperation:operation];
}

#pragma mark - Response Handling


- (User *)userWithJSON:(id)json error:(NSError **)error
{
    User *user = [[User alloc] init];
    

    if (![json isKindOfClass:NSDictionary.class])
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"The response is not a JSON object literal." forKey:NSLocalizedFailureReasonErrorKey];
        if (error) *error = [[NSError alloc] initWithDomain:@"KMD" code:0 userInfo:userInfo];
        return nil;
    }
    
    NSDictionary *response = json;

    if (![self valueForKey:KMDLoginProtocolAuthenticationTokenKey isDefinedInDictionary:response])
    {
        return [self populateError:error withMissingKey:KMDLoginProtocolAuthenticationTokenKey];
    }
    else
    {
        user.authenticationToken = [response valueForKey:KMDLoginProtocolAuthenticationTokenKey];
    }
    
    if (![self valueForKey:KMDLoginProtocolChangePasswordKey isDefinedInDictionary:response])
    {
        return [self populateError:error withMissingKey:KMDLoginProtocolChangePasswordKey];
    }
    else
    {
        user.changePassword = [[response valueForKey:KMDLoginProtocolChangePasswordKey] boolValue];
    }
    
    if (![self valueForKey:KMDLoginProtocolVersionNumberKey isDefinedInDictionary:response])
    {
        return [self populateError:error withMissingKey:KMDLoginProtocolVersionNumberKey];
    }
    else
    {
        user.serverVersionNumber = [json valueForKey:KMDLoginProtocolVersionNumberKey];
    }
    
    return user;
}


- (BOOL)valueForKey:(NSString *)key isDefinedInDictionary:(NSDictionary *)json
{
    // The Login service can at times return 'JSON null' which is converted
    // to NSNull, or it could be undefined in the JSON.

    id value = [json valueForKey:key];

    return (value && value != (id)NSNull.null);
}


- (id)populateError:(NSError **)error withMissingKey:(NSString *)missingKey
{
    if (error)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Field '%@' missing from login response.", missingKey] forKey:NSLocalizedFailureReasonErrorKey];
        *error = [NSError errorWithDomain:KMDErrorDomain code:KMDErrorInvalidServerResponse userInfo:userInfo];
    }
    
    return nil;
}


- (BOOL)populateError:(NSError **)error Code:(NSInteger)code message:(NSString *)message
{
    if (error)
    {
        message = [message stringByAppendingFormat:@" (%d)", code];
        
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:KMDErrorDomain code:code userInfo:userInfo];
    }
    
    return YES;
}

#pragma mark - Version validation

-(BOOL)validateServerVersionRquirement:(NSString *)currentServerVersionString error:(NSError **)error
{
    // The value below is hardcoded compatability requirement. Adjust to match the server version setup
    int maximumCompatibleServerVersion = 1;
    int currentServerVersion = [currentServerVersionString intValue];
    BOOL isVersionValid = (currentServerVersion <= maximumCompatibleServerVersion);
    
    if (!isVersionValid)
    {
        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:@"Denne version af app'en er for gammel. Du skal opdatere for at kunne fortsætte." forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:KMDErrorDomain code:KMDLocalErrorCode userInfo:userInfo];
    }
    return isVersionValid;
}

@end
