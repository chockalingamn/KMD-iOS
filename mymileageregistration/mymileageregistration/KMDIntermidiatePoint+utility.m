//
//  KMDIntermidiatePoint+utility.m
//  mymileageregistration
//
//  Created by Per Friis on 28/08/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
#import "KMDMileage+utility.h"
#import "KMDIntermidiatePoint+utility.h"

@implementation KMDIntermidiatePoint (utility)
+ (NSString *)entityName{
    return @"IntermidiatePoint";
}

+ (void)addPointsFromArray:(NSArray *)array addToMileage:(KMDMileage *)mileage{
    for (id obj in mileage.intermidiatePoints) {
        [mileage.managedObjectContext deleteObject:obj];
    }
    
    for (NSDictionary *dictionary in array) {
        KMDIntermidiatePoint *iPoint = [NSEntityDescription insertNewObjectForEntityForName:[KMDIntermidiatePoint entityName] inManagedObjectContext:mileage.managedObjectContext];
        
        for (id key in dictionary) {
            NSAttributeDescription *attrDesc = [iPoint.entity.attributesByName objectForKey:key];
            switch (attrDesc.attributeType) {
                case NSDecimalAttributeType:
                case NSDoubleAttributeType:
                case NSFloatAttributeType:
                    [iPoint setValue:[NSNumber numberWithDouble:[[dictionary valueForKey:key] doubleValue] ] forKey:key];
                    break;
                    
                case NSInteger16AttributeType:
                case NSInteger32AttributeType:
                case NSInteger64AttributeType:
                    [iPoint setValue:[NSNumber numberWithInteger:[[dictionary valueForKey:key] integerValue]] forKey:key];
                    break;
                    
                case NSDateAttributeType:
                    break;
                    
                default:
                    [iPoint setValue:[dictionary valueForKey:key] forKey:key];
                    break;
            }
            
        }
        
        iPoint.onMileage = mileage;
    }
}





+ (NSInteger)addIntermidiatePointToMileage:(KMDMileage *)onMilage withCoordinates:(CLLocationCoordinate2D)coordinate{
    KMDIntermidiatePoint *intermidiatePoint = [NSEntityDescription insertNewObjectForEntityForName:[KMDIntermidiatePoint entityName] inManagedObjectContext:onMilage.managedObjectContext];
    intermidiatePoint.latitude = [NSNumber numberWithDouble:coordinate.latitude];
    intermidiatePoint.longitude = [NSNumber numberWithDouble:coordinate.longitude];
    
    intermidiatePoint.onMileage = onMilage;
    
    return [onMilage.intermidiatePoints indexOfObject:intermidiatePoint];
}










- (NSString *)entityName{
    return [KMDIntermidiatePoint entityName];
}

- (CLLocationCoordinate2D)coordinate{
    return CLLocationCoordinate2DMake(self.latitude.doubleValue, self.longitude.doubleValue);
}

- (NSString *)title{
    return self.intermidiateAddress;
}
@end
