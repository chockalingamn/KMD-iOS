//
//  MapPoint.m
//  mymileageregistration
//
//  Created by Per Friis on 03/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//
@import AddressBook;

#import "KMDMapPoint.h"
#import "KMDGeocoder.h"

@interface KMDMapPoint()
@property (nonatomic, readwrite)CLLocationCoordinate2D cor;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, readwrite) MapPointType type;
@property (nonatomic, readonly) CLLocation *location;

@end

@implementation KMDMapPoint

+ (instancetype)mapPointWithLocation:(CLLocation *)location type:(MapPointType)type index:(NSInteger)idx{
    KMDMapPoint *mapPoint = [[KMDMapPoint alloc] initWithCoordinate:location.coordinate type:type];
    mapPoint.index = idx;
    
    return mapPoint;
}


+ (instancetype)mapPointWithAddress:(NSString *)address type:(MapPointType)type index:(NSInteger)idx{
    KMDMapPoint *mapPoint = [[KMDMapPoint alloc] initWithAddress:address type:type];
    mapPoint.index = idx;
    
    return mapPoint;
}


- (instancetype)initWithAddress:(NSString *)address type:(MapPointType)type{
    self = [super init];
    if (self) {
        _type = type;
        _address = address;
        _cor = CLLocationCoordinate2DMake(0, 0);
        [self updateLocation];
    }
    return self;
}

- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate type:(MapPointType)type{
    self = [super init];
    if (self) {
        _type = type;
        _cor = coordinate;
        _address = [NSString stringWithFormat:@"søger adresse (%f,%f)",_cor.latitude,_cor.longitude];
        [self updateAddress];
    }
    return self;
}



- (CLLocationCoordinate2D)coordinate{
    return _cor;
}

- (NSString *)title{
    return _address;
}

- (CLLocation *)location{
    return  [[CLLocation alloc] initWithLatitude:self.coordinate.latitude longitude:self.coordinate.longitude];
}


- (void)updateAddress{
    [KMDGeocoder reverseGeocode:self.location completionHandler:^(NSString *formattedAddress, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            
        
        self.address = formattedAddress;
        [[NSNotificationCenter defaultCenter] postNotificationName:mapPointDidUpdateNotification object:self];
            });
    }];
}

- (void)updateLocation{
    CLGeocoder *geocoder = [[CLGeocoder alloc]init];
    
    [geocoder geocodeAddressString:self.address completionHandler:^(NSArray *placemarks, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:mapPointDidUpdateNotification object:self];
    }];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"%f,%f\n%@\nindex:%ld",self.coordinate.latitude,self.coordinate.longitude,self.address,(long)self.index];
}

@end
