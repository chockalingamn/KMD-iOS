//
//  KMDGeocoder.m
//  mymileageregistration
//
//  Created by Per Friis on 09/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//


static NSString *const googleMapsApi = @"http://maps.googleapis.com/maps/api/";
static NSString *const googleGeocoder = @"geocode/json?sensor=trues&latlng=%f,%f";
static NSString *const googleDistance =  @"distancematrix/json?sensor=true&origins=%@&destinations=%@";

#import "KMDGeocoder.h"
#import "KMDMapPoint.h"
#import "KMDIntermidiatePoint+utility.h"
@interface KMDGeocoder()
@property (nonatomic,strong) NSCharacterSet *allowedChars;
@end



@implementation KMDGeocoder

- (NSCharacterSet *)allowedChars{
    if (!_allowedChars) {
        _allowedChars = [NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"];
    }
    return _allowedChars;
}

+ (NSCharacterSet *)allowedChars{
    return [NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[]"];
}

+ (void)reverseGeocode:(CLLocation *)location completionHandler:(void (^)(NSString *, NSError *))completionBlock{
    if (!completionBlock) {
        return;
    }
    AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
    
    NSURL *url = [NSURL URLWithString:[googleMapsApi stringByAppendingFormat:googleGeocoder,location.coordinate.latitude,location.coordinate.longitude]];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:appDelegate.downloadQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,connectionError.localizedDescription);
            completionBlock(nil,connectionError);
        } else {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            
            if (httpResponse.statusCode == 200) {
                NSError *error;
                id jsonData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                
                if ([jsonData isKindOfClass:[NSDictionary class]]) {
                    id results = [jsonData objectForKey:@"results"];
                    if ([results isKindOfClass:[NSArray class]]) {
                        NSDictionary *firstResult = [results firstObject];
                        completionBlock([firstResult valueForKey:@"formatted_address"],nil);
                    }
                }
            } else {
                completionBlock(nil,[NSError errorWithDomain:@"KDM-GoogleMaps" code:httpResponse.statusCode userInfo:@{@"result": [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]}]);
                
                NSLog(@"%s %@",__PRETTY_FUNCTION__,httpResponse);
                NSLog(@"%s %@",__PRETTY_FUNCTION__,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            }
        }
    }];
}


+ (void)calculateDistanceOnMileage:(KMDMileage *)mileage completionBlock:(void(^)(double distance, NSError *error)) completionBlock{
    NSArray *arrayOfPoints = mileage.mappoints;
    
    if (arrayOfPoints.count < 2 || ![[arrayOfPoints firstObject] isKindOfClass:[KMDMapPoint class]]) {
        completionBlock(-1,[NSError errorWithDomain:@"KMD distance" code:-1 userInfo:@{@"error":@"The passed array is invalid",@"array":arrayOfPoints?arrayOfPoints:[[NSNull alloc]init]}]);
        return;
    }
    
    // TODO: need more flexible and elegant way
    
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        
        
        CGFloat distance = 0;
        
        for (NSInteger idx = 0; idx < arrayOfPoints.count -1; idx ++) {
            KMDMapPoint *origins = arrayOfPoints[idx],
            *destinations = arrayOfPoints[idx+1];
            
            
            
            NSURL *url = [NSURL URLWithString:[googleMapsApi stringByAppendingFormat:googleDistance,[origins.address stringByAddingPercentEncodingWithAllowedCharacters:[KMDGeocoder allowedChars]],[destinations.address stringByAddingPercentEncodingWithAllowedCharacters:[KMDGeocoder allowedChars]]]];
            
            NSHTTPURLResponse *response;
            NSError *error;
            
            NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:&response error:&error];
            
            if (!error && response.statusCode == 200) {
                NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
                NSDictionary *distanceD = [[[[[result objectForKey:@"rows"] firstObject] objectForKey:@"elements"] firstObject] objectForKey:@"distance"];
                destinations.distanceFomLastPoint = [[distanceD valueForKey:@"value"] floatValue];
                distance += [[distanceD valueForKey:@"value"] floatValue];
            } else {
                NSLog(@"%s %@",__PRETTY_FUNCTION__,response);
            }
        }
        
        NSArray *viaPoints = [arrayOfPoints filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"type == %d",mptVia]];
        [viaPoints enumerateObjectsUsingBlock:^(KMDMapPoint *mapPoint, NSUInteger idx, BOOL *stop) {
            if (idx < mileage.intermidiatePoints.count) {
                KMDIntermidiatePoint *intermidiatePoint = [mileage.intermidiatePoints objectAtIndex:idx];
                intermidiatePoint.distanceFromLastAddress = [NSNumber numberWithDouble:mapPoint.distanceFomLastPoint/1000];
            }
        }];
        
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            completionBlock(distance,nil);
        }];
     }];
}

static NSString *const googleAutocompleteFormat = @"https://maps.googleapis.com/maps/api/place/autocomplete/json?input=%@&types=address&location=%.5f,%.5f&radius=500000&components=country:dk&key=AIzaSyDTy6aJcSlSCmCRG6JxmRaE19UfyHXuMS0";


+ (void)autoComplete:(NSString *)string location:(CLLocation *)location completionBlock:(void (^)(NSArray *))completionBlock{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:googleAutocompleteFormat,[string stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],location.coordinate.latitude,location.coordinate.longitude]];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (connectionError) {
            NSLog(@"%s %@",__PRETTY_FUNCTION__,connectionError.localizedDescription);
        } else {
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
            if ([result isKindOfClass:[NSDictionary class]]) {
                if ([[result valueForKey:@"status"] isEqualToString:@"OK"]) {
                    NSMutableArray *array = [[NSMutableArray alloc] init];
                    for (NSDictionary *description in [result valueForKey:@"predictions"]) {
                        [array addObject:[description valueForKey:@"description"]];
                    }
                    completionBlock(array);
                } else {
                    completionBlock(nil);
                    NSLog(@"%s %@",__PRETTY_FUNCTION__,[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                }
            }
        }
    }];
    
}

@end
