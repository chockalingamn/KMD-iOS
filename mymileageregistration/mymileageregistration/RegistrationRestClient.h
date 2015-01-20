#import <Foundation/Foundation.h>

#import "KMD/KmdRestClient.h"

#define KMDTripRegistrationFieldStartAddress @"startAddress"
#define KMDTripRegistrationFieldEndAddress @"endAddress"
#define KMDTripRegistrationFieldDistance @"distanceOfTripInKilometers"
#define KMDTripRegistrationFieldDate @"departureTimestamp"
#define KMDTripRegistrationFieldVehicleRegistrationNumber @"vehicleRegistrationNumber"
#define KMDTripRegistrationFieldTemplateID @"templateID"
#define KMDTripRegistrationFieldReason @"cause"


@class NSManagedObjectID, Registration, User;


@interface RegistrationRestClient : KmdRestClient

- (void)sendRegistrations:(NSArray *)registrations done:(void (^)(NSArray *, NSArray *))doneBlock;
- (void)sendRegistration:(Registration *)registration success:(void (^)(void))successBlock failure:(void (^)(NSError *))failure;

@end
