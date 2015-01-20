//
//  KMDMileage+utility.m
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
#import "NSDateFormatter+MDT.h"
#import "KMD/User.h"
#import "KMDMileage+utility.h"
#import "KMDIntermidiatePoint+utility.h"
#import "KMDMapPoint.h"
#import "KMDTemplate+utility.h"

@implementation KMDMileage (utility)


#pragma mark - properties
- (NSAttributedString *)displayReason{
    if (self.reason && self.reason.length > 0) {
        return [[NSAttributedString alloc] initWithString:self.reason attributes:@{NSForegroundColorAttributeName:KMDColorDarkGreen}];
    }
    return [[NSAttributedString alloc] initWithString:@"Ny kørsel" attributes:@{NSForegroundColorAttributeName:[UIColor redColor]}];
}

- (NSAttributedString *)displayTeamplateName{
    if (self.templateName && self.templateName.length > 0) {
        return [[NSAttributedString alloc] initWithString:self.templateName];
    }
    
    return [[NSAttributedString alloc] initWithString:@"Kørselstype" attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14.0f],NSForegroundColorAttributeName:[UIColor colorWithWhite:.75f alpha:1]}];
}

- (NSArray *)mappoints{
    NSMutableArray *_mappoints = [[NSMutableArray alloc] initWithCapacity:self.intermidiatePoints.count + 2];
    
    if (!self.startAddress) {
        return nil;
    }
    [_mappoints addObject:[KMDMapPoint mapPointWithAddress:self.startAddress type:mptStart index:-1]];
    for (KMDIntermidiatePoint *intermidiatePoint in self.intermidiatePoints) {
        if (intermidiatePoint.intermidiateAddress && intermidiatePoint.intermidiateAddress.length > 2) {
            [_mappoints addObject:[KMDMapPoint mapPointWithAddress:intermidiatePoint.intermidiateAddress type:mptVia index:-1]];
        }
    }
    if (self.endAddress) {
        [_mappoints addObject:[KMDMapPoint mapPointWithAddress:self.endAddress type:mptEnd index:-1]];
    }
    
    return _mappoints;
}


#pragma mark - class methods

+ (instancetype)newMileageInManagedContext:(NSManagedObjectContext *)context{
    KMDMileage *mileage = [NSEntityDescription insertNewObjectForEntityForName:[KMDMileage entityName] inManagedObjectContext:context];
    mileage.depatureTimestamp = [NSDate date];
    mileage.isSent = @NO;
    mileage.eligibleForDelete = @NO;
    mileage.username = [[User currentUser] username];
    mileage.status = @"NEW";
    
    if (!mileage.reason) {
        mileage.reason = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastUsed.purpose"];
    }
    
    if (!mileage.vehicleRegistrationNumber) {
        mileage.vehicleRegistrationNumber = [[NSUserDefaults standardUserDefaults] valueForKey:@"lastUsed.license"];
    }
    
    [context save:nil];
    [((AppDelegate *)[[UIApplication sharedApplication] delegate]) saveManagedDocument];
    [context.undoManager removeAllActions];

    return mileage;
}

+ (NSString *)entityName{
    return @"Mileage";
}



+ (void)updateMileageRegistrationsFromBackend{
    __block AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    if (appDelegate.sessionTimeOut) {
        return;
    }
    
    
    User *user = [User currentUser];
    user.lastRequestToServer = [NSDate date];
    NSURL *url = user.hostname;
    url = [url URLByAppendingPathComponent:@"KMD.LPE.Mobile.MileageRegistration/MyMileageRegistration/GetMileageList"];
    
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [urlRequest setValue:user.username forHTTPHeaderField:@"UserName"];
    [urlRequest setValue:user.pin forHTTPHeaderField:@"Pincode"];
    [urlRequest setValue:user.authenticationToken forHTTPHeaderField:@"Ticket"];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    
    [appDelegate.downloadQueue addOperationWithBlock:^{
        
        [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            if (connectionError) {
                [[NSNotificationCenter defaultCenter] postNotificationName:mileageFailedTupdateFromBackend object:nil userInfo:@{@"connectionError": connectionError}];
            } else {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                if (httpResponse.statusCode != 200) {
                    
                    NSLog(@"%s %@",__PRETTY_FUNCTION__,httpResponse);
                    NSLog(@"%s %@",__PRETTY_FUNCTION__,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                    
                    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                    
                    NSString *errorTitle = [NSString stringWithFormat:@"Fejl ved kommunikation :%ld",(long)httpResponse.statusCode];
                    NSString *errorMessage = [NSString stringWithFormat:@"Fejl besked:\n%@",[result valueForKey:@"errorReason"]];
                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:mileageFailedTupdateFromBackend object:nil userInfo:@{@"httpHeader":httpResponse,@"response":result}];
                    
                    if ([UIAlertController class]) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:errorTitle message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
                        [alertController addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                            [alertController dismissViewControllerAnimated:YES completion:nil];
                        }]];
                        AppDelegate *appDel = [[UIApplication sharedApplication]delegate];
                        
                        [appDel.window.rootViewController presentViewController:alertController animated:YES completion:^{
                            
                        }];
                    } else {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:errorTitle message:errorMessage delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                        [alertView show];
                        
                    }
                } else {
                    NSError *error;
                    id result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    
                    if ([result isKindOfClass:[NSArray class]] && !error) {
                        [appDelegate.managedObjectContext performBlock:^{
                            [KMDMileage updateMileageFromArray:result inManagedObjectContext:appDelegate.managedObjectContext];
                            
                            [[NSNotificationCenter defaultCenter] postNotificationName:mileageDidUpdateFromBackend object:nil];
                        }];
                        
                    } else {
                        NSLog(@"%s %@\n%@",__PRETTY_FUNCTION__,error.localizedDescription,result);
                    }
                }
            }
        }];
    }];
    
}

+ (void)updateMileageFromArray:(NSArray *)array inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"isSent == YES"];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (KMDMileage *mileage in fetchedObjects) {
        mileage.eligibleForDelete = @YES;
    }
    
    
    for (NSDictionary *dictionary in array) {
        [KMDMileage addMileageFromDic:dictionary inManagedObjectContext:managedObjectContext];
    }
    
    
    fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"eligibleForDelete == YES"];
    
    
    fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    for (id obj in fetchedObjects) {
        [managedObjectContext deleteObject:obj];
    }
}

+ (id)addMileageFromDic:(NSDictionary *)dictionary inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    KMDMileage *mileage;
    if (![[dictionary valueForKey:@"workFlowID"] isEqualToString:@"000000000000"]) {
        mileage = [KMDMileage findMileageByWorkflowID:[dictionary valueForKey:@"workFlowID"] inManagedObjectContect:managedObjectContext];
    }
    
    if (!mileage) {
        mileage = [NSEntityDescription insertNewObjectForEntityForName:[KMDMileage entityName] inManagedObjectContext:managedObjectContext];
        mileage.workFlowID = [dictionary valueForKey:@"workFlowID"];
        mileage.isSent = @YES;
        mileage.username = [User currentUser].username;
    }
    
    
    NSArray *skipKeys = @[@"workFlowID",@"intermidiatePoints",@"departureTimestamp"];
    
    for (id key in dictionary.allKeys) {
        if ([[skipKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@",key]] count] == 0) {
            if ([mileage.entity.propertiesByName objectForKey:key]) {
                [mileage setValue:[dictionary objectForKey:key] forKey:key];
            }
        }
    };
    mileage.depatureTimestamp = [[NSDateFormatter rfc3339NoTime] dateFromString:[dictionary valueForKey:@"departureTimestamp"]];
    
    mileage.templateName = [KMDTemplate templateNameFor:[dictionary valueForKey:@"templateID"]];
    
    [KMDIntermidiatePoint addPointsFromArray:[dictionary objectForKey:@"intermidiatePoints"] addToMileage:mileage];
    mileage.status = [dictionary valueForKey:@"statusID"];
    
    mileage.eligibleForDelete = @NO;
    
    return mileage;
}


+ (id)findMileageByWorkflowID:(NSString *)workflowID inManagedObjectContect:(NSManagedObjectContext *)managedObjectContext{
    return [KMDMileage findMileageByPredicate:[NSPredicate predicateWithFormat:@"workFlowID == %@",workflowID] inManagedObjectContext:managedObjectContext];
}

+ (id)findMileageByPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
    fetchRequest.predicate = predicate;
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"workFlowID" ascending:YES]];
    
    
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil || fetchedObjects.count > 1) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    return [fetchedObjects firstObject];
}

+ (void)cleanEmplyMileageRegistrations{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDMileage entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"username = %@ && distanceOfTripInKilometers = nil && endAddress = nil && reason = nil  && startAddress = nil && templateID = nil && vehicleRegistrationNumber = nil && comments = nil",[[User currentUser] username]];
    
    __block AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    [fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [appDelegate.managedObjectContext deleteObject:obj];
    }];
    
}

#pragma mark - methods

- (NSString *)entityName{
    return [KMDMileage entityName];
}

- (BOOL)isValid{
    
    if (!self.reason || self.reason.length == 0) {
        return NO;
    }
    
    if (!self.vehicleRegistrationNumber) {
        return NO;
    }
    
    if (!self.templateName || self.templateName.length <= 0) {
        return NO;
    }
    
    if (!self.startAddress || self.startAddress.length <= 0) {
        return NO;
    }
    
    if (!self.endAddress || self.endAddress.length <= 0) {
        return NO;
    }
    
    if (!self.distanceOfTripInKilometers || self.distanceOfTripInKilometers.floatValue <= 0) {
        return NO;
    }
    
    return YES;
}


- (void)submitMileageToBackend{
    __block AppDelegate *appDelegate = (id)[[UIApplication sharedApplication] delegate];
    if (appDelegate.sessionTimeOut) {
        return;
    }
    
    self.isSent = @YES;
    self.submitError = nil;
    
    User *user = [User currentUser];
    user.lastRequestToServer = [NSDate date];
    NSURL *url = user.hostname;
    url = [url URLByAppendingPathComponent:@"KMD.LPE.Mobile.MileageRegistration/MyMileageRegistration/ReportMileage"];
    
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    
    [urlRequest setValue:user.username forHTTPHeaderField:@"UserName"];
    [urlRequest setValue:user.pin forHTTPHeaderField:@"Pincode"];
    [urlRequest setValue:user.authenticationToken forHTTPHeaderField:@"Ticket"];
    
    urlRequest.HTTPMethod = @"POST";
    
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    [urlRequest setValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Accept"];
    
    
    
    
    __block NSDictionary *payloadDic = [self dictionary];
    
    if (![NSJSONSerialization isValidJSONObject:payloadDic]) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,payloadDic);
        self.submitError = @"Fejl i lokale data";
        return;
    }
    
    
    NSData *payload = [NSJSONSerialization dataWithJSONObject:payloadDic options:0 error:nil];
    
    [urlRequest setHTTPBody:payload];
    
    
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,connectionError.localizedDescription);
            self.isSent = @NO;
            self.status = nil;
            self.submitError = connectionError.localizedDescription;
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (httpResponse.statusCode != 200) {
                NSDictionary *errorDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                
                NSLog(@"%s \n%@\n%@\n%@",__PRETTY_FUNCTION__,httpResponse,errorDic,payloadDic);
                
                [self.managedObjectContext performBlock:^{
                    self.isSent = @NO;
                    self.submitError = [errorDic valueForKey:@"errorReason"];
                }];
            } else {
                [self.managedObjectContext performBlock:^{
                    self.isSent = @YES;
                    self.status = @"";
                }];
            }
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:milageBackendMightHaveUpdates object:self.managedObjectContext];
    }];
    
    
}

- (NSDictionary *)dictionary{
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    
    
    // attributes that have to be handled special or is not of interest to the service
    NSArray *skipKeys = @[@"intermediatePoints",@"depatureTimestamp",@"reason",@"endLatitude",@"endLongitude",@"isSent",@"startLatitude",@"startLongitude",@"templateName",@"username",@"submitError",@"distanceOfTripInKilometers"];
    
    // handle all the easy onens, attribute name/type is the same as the webservices wants
    for (id key in self.entity.attributesByName.allKeys) {
        if ([[skipKeys filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF == %@",key]] count] == 0 &&
            [self valueForKey:key]) {
            [dictionary setObject:[self valueForKey:key] forKey:key];
        }
    }
    
    [dictionary setObject:self.reason forKey:@"cause"]; // in the get, the field is called reason, but the post it's cause!
    [dictionary setObject:[[NSDateFormatter rfc3339] stringFromDate:[NSDate stripMinutesAndSecondsFromDate:self.depatureTimestamp]] forKey:@"departureTimestamp"];
    
    [dictionary setObject:[NSString stringWithFormat:@"%.2f",self.distanceOfTripInKilometers.doubleValue] forKey:@"distanceOfTripInKilometers"];
    
    if (self.intermidiatePoints.count > 0) {
        NSMutableArray *vias = [[NSMutableArray alloc] initWithCapacity:self.intermidiatePoints.count];
        for (KMDIntermidiatePoint *via in self.intermidiatePoints) {
            if (via.intermidiateAddress) {
                [vias addObject:@{@"intermidiateAddress":via.intermidiateAddress,@"distanceFromLastAddress":@0,@"manualDistance":@0}];
            }
        }
        if (vias.count > 0) {
            [dictionary setObject:vias forKey:@"intermediatePoints"];
        }
    }
    
    return dictionary;
}

- (void)validateAndUpdateError{
    if (!self.isValid) {
        NSString *errorMessage = @"Du mangler at udfylde ";
        if (!self.reason) {
            errorMessage = @"Formål, ";
        }
        if (!self.startAddress) {
            errorMessage = [errorMessage stringByAppendingString:@"Startadresse, "];
        }
        if (!self.endAddress) {
            errorMessage = [errorMessage stringByAppendingString:@"Slutadresse, "];
        }
        if (self.distanceOfTripInKilometers.floatValue <= 0) {
            errorMessage = [errorMessage stringByAppendingString:@"Distance, "];
        }
        if (!self.templateID){
            errorMessage = [errorMessage stringByAppendingString:@"Kørselstype, "];
        }
        if (!self.vehicleRegistrationNumber) {
            errorMessage = [errorMessage stringByAppendingString:@"Bil, "];
        }
        
        errorMessage = [errorMessage substringToIndex:errorMessage.length - 2];
        
        NSRange range = [errorMessage rangeOfString:@"," options:NSBackwardsSearch];
        if (range.location != NSNotFound) {
            range.length = errorMessage.length - range.location;
            errorMessage = [errorMessage stringByReplacingOccurrencesOfString:@", " withString:@" og " options:NSBackwardsSearch range:range];
        }
        
        self.submitError = errorMessage;
    }
}

@end
