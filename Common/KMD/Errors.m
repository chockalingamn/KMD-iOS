#import "Errors.h"

#import "UIAlertView+Blocks.h"


@implementation Errors

+ (void)fatalError:(NSError *)error
{
    NSAssert(error != nil, @"The error reported should not be null.");

    NSString *message = [NSString stringWithFormat:@"Programmet skal genstartes. %@", [error localizedDescription]]; 
    
    RIButtonItem *button = [[RIButtonItem alloc] init];
    
    button.label = @"Luk App";
    button.action = ^{ exit(1); };
    
  //  [[[UIAlertView alloc] initWithTitle:@"Der opstod en fejl" message:message cancelButtonItem:button otherButtonItems:nil] show];
    [[[UIAlertView alloc] initWithTitle:@"Der opstod en fejl" message:message delegate:self cancelButtonTitle:@"Close app" otherButtonTitles:nil] show];
}

+ (NSError *)errorWithReason:(NSString *)errorReason errorCode:(NSInteger) errorCode
{
    NSError *error;
    
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:errorReason forKey:NSLocalizedDescriptionKey];
    
    error = [NSError errorWithDomain:KMDErrorDomain code:errorCode userInfo:userInfo];

    return error;
}

+ (NSError *)errorFromResponse:(NSHTTPURLResponse *)response connectionError:(NSError *)connectionError json:(id)json
{
    NSError *error;
    [Errors populateError:&error withServerError:connectionError response:response json:json];
    return error;
}


+ (BOOL)populateError:(NSError **)error withServerError:(NSError *)serverError response:(NSHTTPURLResponse *)response json:(id)json
{
    if (error)
    {        
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        
        // Determine the type of error.
        
        NSString *errorReason = @"Ukendt fejl.";
        NSInteger errorCode = KMDServerResponseOtherErrorCode;
        
        if (serverError && response == nil)
        {
            [userInfo setValue:serverError forKey:NSUnderlyingErrorKey];
            
            if (serverError.code == 303)
            {
                errorReason = @"Serveren kan ikke nås fra din nuværende netværksforbindelse. (303)";
                errorCode = KMDServerResponseNetworkFailure;
            }
            else if (serverError.code == -1005)
            {
                errorReason = @"Serveren har lukket forbindelsen. Prøv igen.";
                errorCode = KMDServerResponseNetworkFailure;
            }
            else if (serverError.code == -1003)
            {
                errorReason = @"Serveren kan ikke nås fra dette netværk. (-1003)";
                errorCode = KMDServerResponseNetworkFailure;
            }
            else {
                errorReason = [serverError localizedDescription];
            }
        }
        else if (response)
        {
            if (response.statusCode == 200)
            {
                // The request was fine but something went wrong when trying
                // to understand the response. Not much we can do but relay the error.
                
                errorReason = @"Serverens svar kan ikke læses.";
            }
            else if (response.statusCode == 500)
            {
                // An internal server error occured.
                
                errorReason = @"Der opstod en fejl hos serveren.";
                errorCode = KMDServerResponseServerFailure;
            }
            else if (response.statusCode == 400)
            {
                // The client has sent a bad request the reason for the error
                // should be in the response JSON.
                
                errorReason = (json) ? [json valueForKey:@"errorReason"] : [serverError localizedDescription];
                errorCode = KMDServerResponseValidationErrorCode;
            }
            else if (response.statusCode == 401)
            {
                errorCode = KMDServerResponseAuthenticationErrorCode;
            }
            else
            {
                errorReason = [serverError localizedDescription];
            }
        }
        else
        {
            errorReason = [serverError localizedDescription];
        }
        
        [userInfo setValue:[serverError localizedDescription] forKey:NSLocalizedFailureReasonErrorKey];
        [userInfo setValue:errorReason forKey:NSLocalizedDescriptionKey];
        [userInfo setValue:serverError forKey:NSUnderlyingErrorKey];
        
        *error = [NSError errorWithDomain:KMDErrorDomain code:errorCode userInfo:userInfo];
        
        if (errorCode == KMDServerResponseOtherErrorCode)
        {
            NSLog(@"%@ %@", *error, [*error userInfo]);
        }
    }
    
    return YES;
}

+ (void)displayError:(NSError *)error
{
    if (!error) return;
    
    [[[UIAlertView alloc] initWithTitle:@"Fejl" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}


+ (void)displayErrorWithTitle:(NSString *)title message:(NSString *)message
{
    [[[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

@end
