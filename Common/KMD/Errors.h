#import <Foundation/Foundation.h>


#define KMDErrorDomain @"KMD"


#define KMDLocalErrorCode 100
#define KMDRemoteErrorCode 500

#define KMDLocalSessionTimeoutErrorCode 101

#define KMDServerResponseValidationErrorCode 400
#define KMDServerResponseFileNotFound 404
#define KMDServerResponseAuthenticationErrorCode 401
#define KMDServerResponseServerFailure 500
#define KMDServerResponseOtherErrorCode 600
#define KMDServerResponseNetworkFailure 700


@interface Errors : NSObject

/// If you encounter an error in the code and there is no solution, use this.
///
/// It will display a UIAlertView and let the user close the app.
///
+ (void)fatalError:(NSError *)error;

/// Creates an error with given reason and code.
///
/// adds domain to error
///
+ (NSError *)errorWithReason:(NSString *)errorReason errorCode:(NSInteger) errorCode;

/// Converts an error from connection or server problems into a client readable error.
///
/// If you recieve an error from the server and you don't know what to do with it
/// you can use this code. If on the other hand you receive a protocol specific error
/// e.g. a 401 that you have defined is a "Login Failed" in your login protocol
/// you should handle it yourself.
///
/// This method will populate `error` with a message in NSLocalizedDescriptionKey key,
/// and the `KMD` error domain. The NSUnderlyingErrorKey will contain the `serverError`.
///
/// If the `response` is not nil, the response's status code will be used to determine,
/// the type of error we encountered. If `json` is also not nil and contains a `errorReason`
/// field it will be used as the description of the error.
///
/// @depricated
///
+ (BOOL)populateError:(NSError **)error withServerError:(NSError *)serverError response:(NSHTTPURLResponse *)response json:(id)json;

/// Converts an error from connection or server problems into a client readable error.
///
/// If you recieve an error from the server and you don't know what to do with it
/// you can use this code. If on the other hand you receive a protocol specific error
/// e.g. a 401 that you have defined is a "Login Failed" in your login protocol
/// you should handle it yourself.
///
/// @returns an error with a message in NSLocalizedDescriptionKey key,
/// and the `KMD` error domain. The NSUnderlyingErrorKey will contain the `connectionError`.
///
/// @param response if not nil, the response's status code will be used to determine,
/// the type of error we encountered.
/// @param json if not nil and contains a `errorReason` field it will be used as the description of the error.
///
+ (NSError *)errorFromResponse:(NSHTTPURLResponse *)response connectionError:(NSError *)connectionError json:(id)json;

/// Displays the error's description in a UIAlertView.
///
/// If the error is nil, nothing happens.
///
+ (void)displayError:(NSError *)error;


/// Displays a UIAlertView with the title and message.
///
+ (void)displayErrorWithTitle:(NSString *)title message:(NSString *)message;

@end
