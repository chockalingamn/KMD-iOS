//
//  Absence+KMD.m
//  leaverequest
//
//  Created by Per Friis on 09/07/14.
//  Copyright (c) 2014 KMD A/S. All rights reserved.
//


#import "Absence+KMD.h"
#import "NSDateFormatter+MDT.h"

#import "KMDChildrenREST.h"
#import "AbsenceSubmitREST.h"

@interface Absence() <KMDChildrenRESTDelegate>
@property (nonatomic, readonly) NSArray *mustHaveExtraList;
@property (nonatomic, readonly) NSArray *omsorgsdage;
@property (nonatomic, readonly) NSArray *tjenstefri;
@property (nonatomic, readonly) NSArray *arbejdsskade;
@property (nonatomic, readonly) NSArray *barsel;

@end

@implementation Absence (KMD)
#pragma mark - properties (readonly)

- (BOOL)isValid{
    if (!self.absenceID || self.absenceID.length == 0) {
        return NO;
    }
    
    if (self.mustHaveExtra && (!self.extraID || self.extraID.length == 0)) {
        return NO;
    }
    
    return YES;
}

- (UIImage *)statusImage{
    return [UIImage imageNamed:self.statusID];
}

- (UIColor *)statusColor{
    if ([self.statusID isEqualToString:@"APPROVED"]) {
        return [UIColor colorWithRed:136.0f/255.0f green:175.0f/255.0f blue:69.0f/255.0f	 alpha:1];
        
    } else if ([self.statusID isEqualToString:@"ERROR"]||[self.statusID isEqualToString:@"REJECTED"]) {
        return [UIColor colorWithRed:194.0f/255.0f green: 0.0f blue:11.0f/255.0f alpha:1.0f];
        
    } else if ([self.statusID isEqualToString:@"SENT"]) {
         return [UIColor colorWithRed:56.0f/255.0f green:178.0f/255.0f blue:249.0f/255.0f	 alpha:1];
    }
    return [UIColor lightGrayColor];
}

// TODO: this is a hardcode of the absencetypes that requires extra data
- (NSArray *)omsorgsdage{
    return @[@"OS",@"OOS"];
}

- (NSArray *)tjenstefri{
    return @[@"TJ",@"TJUL",@"TJUP"];
}

- (NSArray *)arbejdsskade {
    return @[@"AS",@"DAS"];
}

- (NSArray *) barsel {
    return @[@"BA",@"BAF",@"BD",@"BG",@"BU",@"BUD",@"GG",@"NSG"];
}

- (NSArray *)mustHaveExtraList{
    NSMutableArray *_mustHaveExtraList = [[NSMutableArray alloc] initWithArray:self.omsorgsdage];
    [_mustHaveExtraList addObjectsFromArray:self.tjenstefri];
    [_mustHaveExtraList addObjectsFromArray:self.arbejdsskade];
    [_mustHaveExtraList addObjectsFromArray:self.barsel];
    return _mustHaveExtraList;
}

- (ExtraTypes)extraTypeID{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@",self.absenceID];
    if ([self.omsorgsdage filteredArrayUsingPredicate:predicate].count > 0){
        return extraTypeCareDay;
    };
    
    if ([self.tjenstefri filteredArrayUsingPredicate:predicate].count > 0) {
        return extraTypeLeave;
    }
    
    if ([self.arbejdsskade filteredArrayUsingPredicate:predicate].count > 0) {
        return extraTypeWorkRelatedInjury;
    }
    
    if ([self.barsel filteredArrayUsingPredicate:predicate].count > 0) {
        return extraTypeMaternity;
    }
    
    if (self.absenceID.length > 0) {
        return extraTypeUnknown;
    }
    return extraTypeNone;
}

- (BOOL)mustHaveExtra{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF == %@",self.absenceID];
    return [self.mustHaveExtraList filteredArrayUsingPredicate:predicate].count > 0;
}

- (BOOL)wholeDay{
    NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute fromDate:self.startDate];

    if (startComponents.hour == 0 && startComponents.minute == 0) {
        return YES;
    }
    return NO;
}


- (BOOL)oneDay{
    if ([self.startDate timeIntervalSinceDate:self.endDate] < 24.0f*60.0f*60.0f) {
        NSDateComponents *startComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitYear fromDate:self.startDate];
        NSDateComponents *endComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self.endDate];
        return endComponents.day == startComponents.day;
    }
    
    return NO;
}

- (NSMutableDictionary *)dictionary{
    NSDictionary *keyReplacement = @{@"absenceID":          @"AbsenceTypeID",
                                     @"reasonTypeID":       @"ReasonID",
                                     @"childID":            @"ChildID",
                                     @"requestID":          @"AbsenceRequestID",
                                     @"nComment":           @"Comment",
                                     @"oldAbsenceTypeID":   @"AbsenceTypeIDOld",
                                     @"oldStartDate":       @"StartDateOld",
                                     @"oldEndDate":         @"EndDateOld"};
    
    NSSet *excludeKeys  = [[NSSet alloc] initWithArray:@[[ABSENCE_NAME lowercaseString] ,
                            [COMMENTS lowercaseString] ,
                            [STATUS_ID lowercaseString] ,
                            [STATUS_TEXT lowercaseString] ,
                            [USER_ID lowercaseString] ,
                            [CHILD_CPR lowercaseString] ,
                            [MATERNITY_ID lowercaseString] ,
                            [REASON_TYPE_ID lowercaseString] ,
                            [REASON_TYPE_TEXT lowercaseString] ,
                            [WORK_INJURY_DATE lowercaseString] ,
                            [WORK_INJURY_ID lowercaseString] ,
                            [ACTUAL_DELIVERY_DATE lowercaseString] ,
                            [EXPECTED_DILIVERY_DATE lowercaseString],
                            [HOURS lowercaseString]]];
    
    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    
    NSDictionary *attributes = [[self entity] attributesByName];
    
    for (NSString *key in [attributes allKeys]) {
        if ([excludeKeys containsObject:[key lowercaseString]]) {
            continue;
        }
       
        id value = [self valueForKey:key];
        
        if (!value){
            continue;
        }
        
        if ([value isKindOfClass:[NSDate class]]) {
            if ([value timeIntervalSinceDate:[NSDate higendDate]]<0) {
                value = [[NSDateFormatter rfc3339GMT] stringFromDate:value];
            } else {
                value = @"9999-12-31T00:00:00Z";
            }
        }

        NSString *alternativeKey = [keyReplacement valueForKey:key];
        if (alternativeKey) {
            data[alternativeKey] = value;
        } else {
      
            data[[[[key substringToIndex:1] capitalizedString] stringByAppendingString:[key substringFromIndex:1]]] = value;
        }
    }
    
    if (self.extraTypeID == extraTypeLeave) {
        data[@"reasonID"]= self.reasonTypeID;
    }
    
    if(self.extraID) {
        data[@"ExtraDataID"] = self.extraID;
    }
    
    return data;
   
}

#pragma mark read/write properties
- (AbsenceSubmitStatus)status{
    if ([self.statusID isEqualToString:@"APPROVED"]) {
        return statusApproved;
    } else if ([self.statusID isEqualToString:@"ERROR"]) {
        return statusError;
    } else if ([self.statusID isEqualToString:@"SENT"]) {
        return statusSubmitted;
    } else if (self.statusID){
        return statusUnknown;
    }
    
    return statusNone;
}

- (void)setStatus:(AbsenceSubmitStatus)status{
    switch (status) {
        case statusNone:
            self.statusID = nil;
            self.statusText = @"Ukendt";
            break;
            
        case statusApproved:
            self.statusID = @"APPROVED";
            self.statusText = @"Godkendt";
            break;
            
        case statusError:
            self.statusID = @"ERROR";
            self.statusText = @"Fejl";
            break;
            
        case statusSubmitted:
            self.statusID = @"SENT";
            self.statusText = @"Afsendt";
            break;
            
        default:
            self.statusID = nil;
            self.statusText = @"Ukendt";
            break;
    }
}


- (void)setExtraID:(NSString *)extraID{
    switch (self.extraTypeID) {
        case extraTypeLeave:
            self.reasonTypeID = extraID;
            break;
            
        case extraTypeCareDay:
            self.childID = extraID;
            break;
            
        case extraTypeMaternity:
            self.maternityID = extraID;
            break;
            
        case extraTypeWorkRelatedInjury:
            self.workInjuryID = extraID;
            break;
            
        default:
            break;
    }
}

- (NSString *)extraID{
    switch (self.extraTypeID) {
        case extraTypeLeave:
            return self.reasonTypeID;
            break;
            
        case extraTypeMaternity:
            return self.maternityID;
            break;
            
        case extraTypeCareDay:
            return self.childID;
            break;
            
        case extraTypeWorkRelatedInjury:
            return self.workInjuryID;
            break;
            
        default:
            break;
    }
    
    return nil;
}

- (void)setExtraValue:(id)extraValue{
    switch (self.extraTypeID) {
        case extraTypeLeave:
            if ([extraValue isKindOfClass:[NSString class]]) {
                self.reasonTypeText = extraValue;
            }
            break;
            
        case extraTypeMaternity:
            if ([extraValue isKindOfClass:[NSDate class]]) {
                self.actualDeliveryDate = extraValue;
            }
            break;
            
            
        case extraTypeCareDay:
            if ([extraValue isKindOfClass:[NSString class]]){
                self.childName = extraValue;
            }
            break;
            
        case extraTypeWorkRelatedInjury:
            if ( [extraValue isKindOfClass:[NSDate class]]){
                self.workInjuryDate = extraValue;
            }
            
        default:
            break;
    }
}

- (id)extraValue{
    switch (self.extraTypeID) {
        case extraTypeLeave:
            return self.reasonTypeText;
            break;
            
        case extraTypeMaternity:
            if (self.actualDeliveryDate) {
                return self.actualDeliveryDate;
            } else {
                return self.expectedDeliveryDate;
            }
            break;
            
        case extraTypeCareDay:
            if (self.childName) {
                return self.childName;
            }
            return [[KMDChildrenREST sharedInstance] childNameForID:self.childID];
            break;
        case extraTypeWorkRelatedInjury:
            return self.workInjuryDate;
            break;
            
        default:
            break;
    }
    return nil;
}

- (NSString *)extraValueDisplayString{
    switch (self.extraTypeID) {
        case extraTypeMaternity:
            if (self.extraValue) {
                return [NSString stringWithFormat:@"Termin %@",[[NSDateFormatter displayDateWithYear] stringFromDate:self.extraValue]];
            } else {
                return @"";
            }
            break;
            
            
        default:
            break;
    }
    return self.extraValue;
}


- (NSString *)durationDisplayString{
    if (self.hours.doubleValue < 0) {
        return @"-";
    }
    NSInteger t = (NSInteger)[self.endDate timeIntervalSinceDate:self.startDate];

    NSInteger minutes = (t / 60) % 60;
    NSInteger hours = (t / 3600);
    return [NSString stringWithFormat:@"%dt %dm",hours,minutes];
}

- (BOOL)openEnded{
    BOOL value = [self.endDate timeIntervalSinceDate:[NSDate higendDate]] >= 0;
    return value;
}

- (void)setOpenEnded:(BOOL)openEnded{
    if (openEnded) {
        self.endDate = [NSDate higendDate];
    } else if(self.startDate) {
        self.endDate = self.startDate;
    } else {
        self.endDate = [NSDate date];
    }
}

#pragma mark - Class methods
#pragma mark public

+ (void)addArrayOfAbsenceDictionary:(NSArray *)array absenceExtra:(NSArray *)extraArray inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    
    [managedObjectContext performBlock:^{
        for (NSDictionary *absenceDic in array) {
            [Absence addAbsenceFromDictionary:absenceDic withExtra:extraArray inManagedObjectContext:managedObjectContext];
        }
        [managedObjectContext save:nil];
    }];
}

+ (void)cleanAbsenceTableInManagedObjectContext:(NSManagedObjectContext *)managedObjectContect{
    [managedObjectContect performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Absence"];
        
        NSError *error = nil;
        NSArray *fetchedObjects = [managedObjectContect executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        }
        if (fetchedObjects) {
            for (id obj in fetchedObjects) {
                [managedObjectContect deleteObject:obj];
            }
        }
    }];
}

+ (Absence *)haveOpenRegistrationInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Absence"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"endDate" ascending:YES]];
    
    
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    
    
    for (Absence *absence in fetchedObjects) {
        if (absence.openEnded) {
            return absence;
        }
    }
    
    return nil;
}

+ (void)updateChildren{
    KMDChildrenREST *childRest = [KMDChildrenREST sharedInstance];
    [childRest fetchFromBackEnd];
    KMDAppDelegate *appDel =[[UIApplication sharedApplication] delegate];
    [appDel.managedObjectContext performBlockAndWait:^{
        
        
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Absence"];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"childID <> nil"];
        NSError *error = nil;
        NSArray *fetchedObjects = [appDel.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        }
        for (Absence *a in fetchedObjects) {
            NSPredicate *idPre= [NSPredicate predicateWithFormat:@"ID = %@",a.childID];
            NSArray *result = [childRest.children filteredArrayUsingPredicate:idPre];
            NSDictionary *c = result.firstObject;
            a.childName = [NSString stringWithFormat:@"%@ %@",c[@"FirstName"],c[@"LastName"]];
        }
    }];
}

#pragma mark private
+ (id)addAbsenceFromDictionary:(NSDictionary *)abDic withExtra:(NSArray *)extra inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    Absence *absence;
    if (![abDic[START_DATE] isKindOfClass:[NSNull class]] &&
        ![abDic[END_DATE] isKindOfClass:[NSNull class]] &&
        ![abDic[ABSENCE_ID] isKindOfClass:[NSNull class]])  {
        absence = [Absence findAbsenceWithType:abDic[ABSENCE_ID] start:[Absence dateFromDate:abDic[START_DATE] time:abDic[START_TIME]] end:[Absence dateFromDate:abDic[END_DATE] time:abDic[END_TIME]] inManagedObjectContext:managedObjectContext];
    }
    
    if (!absence) {
        absence = [NSEntityDescription insertNewObjectForEntityForName:@"Absence" inManagedObjectContext:managedObjectContext];
        [absence updateDataFromDictionary:abDic];
        
        // add the extra if it is there (this solution don't give any core data errors)
        for (NSDictionary *d in extra) {
            if ([absence.requestID isEqualToString:d[REQUEST_ID]]) {
                [absence updateWithExtraDic:d];
            }
        }
    }

    return absence;
}

+ (id)findAbsenceWithType:(NSString *)absenceType start:(NSDate *)startDate end:(NSDate *)endDate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    return [Absence findAbsenceWithPredicate: [NSPredicate predicateWithFormat:@"absenceID = %@ AND startDate = %@ AND endDate = %@",absenceType,startDate,endDate] inManagedObjectContext:managedObjectContext];
}

+ (id)findAbsenceWithRequestID:(NSString *)requestID inManagedObjectContext:(NSManagedObjectContext *) managedObjectContext{
    return [Absence findAbsenceWithPredicate:[NSPredicate predicateWithFormat:@"requestID = %@",requestID] inManagedObjectContext:managedObjectContext];
}

+ (id)findAbsenceWithPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    Absence *absence;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Absence"];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    absence = [[managedObjectContext executeFetchRequest:fetchRequest error:&error] firstObject];
    
    return absence;
}

+ (NSDate *)dateFromDate:(NSString *)dateString time:(NSString *)timeString{
    if (dateString.length == 0) {
        return nil;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    
    NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc]init];
    dateTimeFormatter.dateFormat = @"YYYY-MM-ddHH:mm";

    NSDate *date;
    
    if ([timeString isKindOfClass:[NSNull class]] || [timeString length] == 0) {
        // no time
        date = [dateFormatter dateFromString:dateString];
    } else {
        NSString *dateTimeString = [dateString stringByAppendingString:timeString];
        date = [dateTimeFormatter dateFromString:dateTimeString];
    }
    return date;
}

#pragma mark - instance Methods


- (void)updateDataFromDictionary:(NSDictionary *)abDic{
    
    
    if (![abDic[ABSENCE_ID] isKindOfClass:[NSNull class]] && [abDic[ABSENCE_ID] length]> 0) {
        self.absenceID = abDic[ABSENCE_ID];
        self.oldAbsenceTypeID = self.absenceID;
    }
    
    if (![abDic[ABSENCE_NAME] isKindOfClass:[NSNull class]] && [abDic[ABSENCE_NAME] length]> 0) {
        self.absenceName = abDic[ABSENCE_NAME];
    }
    
    if (![abDic[COMMENTS] isKindOfClass:[NSNull class]] && [abDic[COMMENTS] length]> 0) {
        self.comments = abDic[COMMENTS];
    }
    
    if (![abDic[END_DATE] isKindOfClass:[NSNull class]] && [abDic[END_DATE] length]> 0) {
        self.endDate = [Absence dateFromDate:abDic[END_DATE] time:abDic[END_TIME]];
        self.oldEndDate = self.endDate;
    }
    
    if (![abDic[HOURS] isKindOfClass:[NSNull class]]  && [abDic[HOURS] length]> 0) {
        // TODO: check if the , vs . is an issue
    
        self.hours = [NSNumber numberWithDouble:[[(NSString *)abDic[HOURS] stringByReplacingOccurrencesOfString:@"," withString:@"."] doubleValue]];
    }
    
    if (![abDic[NAME] isKindOfClass:[NSNull class]]  && [abDic[NAME] length]> 0) {
        self.name = abDic[NAME];
    }
    
    if (![abDic[NEW_COMMENT] isKindOfClass:[NSNull class]]  && [abDic[NEW_COMMENT] length]> 0) {
        self.nComment = abDic[NEW_COMMENT];
    }
    
    if (![abDic[REQUEST_ID] isKindOfClass:[NSNull class]]  && [abDic[REQUEST_ID] length]> 0) {
        self.requestID = abDic[REQUEST_ID];
    }
    
    if (![abDic[START_DATE] isKindOfClass:[NSNull class]]  && [abDic[START_DATE] length]> 0) {
        
        self.startDate = [Absence dateFromDate:abDic[START_DATE] time:abDic[START_TIME]];
        self.oldStartDate = self.startDate;
    }
    
    if (![abDic[STATUS_ID] isKindOfClass:[NSNull class]]  && [abDic[STATUS_ID] length]> 0) {
        self.statusID = abDic[STATUS_ID];
    }
    
    if (![abDic[STATUS_TEXT] isKindOfClass:[NSNull class]]  && [abDic[STATUS_TEXT] length]> 0) {
        self.statusText = abDic[STATUS_TEXT];
    }
    
    if (![abDic[USER_ID] isKindOfClass:[NSNull class]]  && [abDic[USER_ID] length]> 0) {
        self.userID = abDic[USER_ID];
    }
}

- (void)updateWithExtraDic:(NSDictionary *)extraDic{
    // AbsenceExtra
    if (![extraDic[ACTUAL_DELIVERY_DATE] isKindOfClass:[NSNull class]]  && [extraDic[ACTUAL_DELIVERY_DATE] length]> 0) {
        self.actualDeliveryDate = [Absence dateFromDate:extraDic[ACTUAL_DELIVERY_DATE] time:@""];
    }
    
    if (![extraDic[CHILD_CPR] isKindOfClass:[NSNull class]]  && [extraDic[CHILD_CPR] length]> 0) {
        self.childCPR = extraDic[CHILD_CPR];
    }
    
    if (![extraDic[CHILD_ID] isKindOfClass:[NSNull class]]  && [extraDic[CHILD_ID] length]> 0) {
        self.childID = extraDic[CHILD_ID];
    }
    
    if (![extraDic[EXPECTED_DILIVERY_DATE] isKindOfClass:[NSNull class]]  && [extraDic[EXPECTED_DILIVERY_DATE] length]> 0) {
        self.expectedDeliveryDate = [Absence dateFromDate:extraDic[EXPECTED_DILIVERY_DATE] time:@""];
    }
    
    if (![extraDic[MATERNITY_ID] isKindOfClass:[NSNull class]]  && [extraDic[MATERNITY_ID] length]> 0) {
        self.maternityID = extraDic[MATERNITY_ID];
    }
    
    if (![extraDic[REASON_TYPE_ID] isKindOfClass:[NSNull class]]  && [extraDic[REASON_TYPE_ID] length]> 0) {
        self.reasonTypeID = extraDic[REASON_TYPE_ID];
    }
    
    if (![extraDic[REASON_TYPE_TEXT] isKindOfClass:[NSNull class]]  && [extraDic[REASON_TYPE_TEXT] length]> 0) {
        self.reasonTypeText = extraDic[REASON_TYPE_TEXT];
    }
    
    if (![extraDic[WORK_INJURY_DATE] isKindOfClass:[NSNull class]]  && [extraDic[WORK_INJURY_DATE] length]> 0) {
        self.workInjuryDate = [Absence dateFromDate:extraDic[WORK_INJURY_DATE] time:@""];
    }
    
    if (![extraDic[WORK_INJURY_ID] isKindOfClass:[NSNull class]]  && [extraDic[WORK_INJURY_ID] length]> 0) {
        self.workInjuryID = extraDic[WORK_INJURY_ID];
    } 
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        [self.managedObjectContext save:nil];
    }
}

@end
