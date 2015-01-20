//
//  KMDTemplate+utility.m
//  mymileageregistration
//
//  Created by Per Friis on 09/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import "KMDTemplate+utility.h"
#import "KMD/User.h"


@implementation KMDTemplate (utility)
+ (NSString *)entityName{
    return @"Template";
}

+ (NSDate *)lastRefreshed{
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"templateDownloadedAt"];
}

+ (void)setLastRefreshed:(NSDate *)lastRefreshed{
    [[NSUserDefaults standardUserDefaults] setObject:lastRefreshed forKey:@"templateDownloadedAt"];
}

+ (NSArray *)templatesInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDTemplate entityName]];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"templateID" ascending:YES]];
    
    
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    return fetchedObjects;
}

+ (void)updateTemplateFromBackend{
    User *user = [User currentUser];
    NSURL *url = user.hostname;
    
    url = [url URLByAppendingPathComponent:@"KMD.LPE.Mobile.MileageRegistration/MyMileageRegistration/GetMileageTemplates"];

    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    
    [urlRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [urlRequest setValue:user.username forHTTPHeaderField:@"UserName"];
    [urlRequest setValue:user.pin forHTTPHeaderField:@"Pincode"];
    [urlRequest setValue:user.authenticationToken forHTTPHeaderField:@"Ticket"];

    
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,connectionError.localizedDescription);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            if (httpResponse.statusCode == 200) {
                __block AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
                if (appDelegate.managedObjectContext) {
                    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDTemplate entityName]];
                    NSArray *fetchedObjects = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
                    if (fetchedObjects) {
                        [fetchedObjects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                            [appDelegate.managedObjectContext deleteObject:obj];
                        }];
                    }
                    
                    [KMDTemplate setLastRefreshed:[NSDate date]];
                    [appDelegate.managedObjectContext performBlock:^{
                        NSError *error;
                        id res = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                        
                        if ([res isKindOfClass:[NSArray class]] && !error) {
                            [KMDTemplate addTemplatesFromArray:res inManagedObjectContext:appDelegate.managedObjectContext];
                            [[NSNotificationCenter defaultCenter] postNotificationName:templateUpdatedFromBackendNotification object:nil];
                        } else {
                            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
                        }
                    }];
                }
            }
        }
    }];
}


+ (void)addTemplatesFromArray:(NSArray *)array inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    for (NSDictionary *templateDictionary in array) {
        [KMDTemplate addTemplateFromDictionary:templateDictionary inManagedObjectContext:managedObjectContext];
    }
}

+ (id)addTemplateFromDictionary:(NSDictionary *)dic inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    KMDTemplate *template = [KMDTemplate findTemplateByID:[dic valueForKey:@"ID"] inManagedObjectContext:managedObjectContext];
    
    if (!template) {
        template = [NSEntityDescription insertNewObjectForEntityForName:[KMDTemplate entityName] inManagedObjectContext:managedObjectContext];
        template.templateID = [dic valueForKey:@"ID"];
    }
    
    template.templateName = [dic valueForKey:@"Name"];
    
    

    return template;
}

+ (id)findTemplateByID:(NSString *)templateID inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDTemplate entityName]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"templateID == %@",templateID];
    
    
    NSError *error = nil;
    NSArray *fetchedObjects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (fetchedObjects == nil) {
        NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
    }
    return [fetchedObjects firstObject];
}

+ (NSString *)templateNameFor:(NSString *)templateID{
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    __block KMDTemplate *template;
    [appDelegate.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[KMDTemplate entityName]];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"templateID == %@",templateID];
        
        
        NSError *error = nil;
        NSArray *fetchedObjects = [appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        if (fetchedObjects == nil) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,error.localizedDescription);
        }
        template = [fetchedObjects firstObject];
    }];

    
    
    return template.templateName;
}


@end
