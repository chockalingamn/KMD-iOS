//
//  MapPoint.h
//  mymileageregistration
//
//  Created by Per Friis on 03/09/14.
//  Copyright (c) 2014 KMD a/s. All rights reserved.
//

#import <Foundation/Foundation.h>
@import MapKit;
@import CoreLocation;

static NSString *const mapPointDidUpdateNotification = @"mapPointDidUpdateNotification";

typedef NS_ENUM(NSInteger, MapPointType) {
    mptUnknown = -1,
    mptStart,
    mptVia,
    mptEnd
};

@interface KMDMapPoint : NSObject <MKAnnotation>
@property (nonatomic, readonly) MapPointType type;
@property (nonatomic, readonly) NSString *address;
@property (nonatomic, readwrite) NSInteger index;
@property (nonatomic, readwrite) double distanceFomLastPoint;

+ (instancetype) mapPointWithLocation:(CLLocation *)location type:(MapPointType)type index:(NSInteger) idx;

+ (instancetype) mapPointWithAddress:(NSString *)address type:(MapPointType)type index:(NSInteger) idx;

- (instancetype) initWithCoordinate:(CLLocationCoordinate2D) coordinate type:(MapPointType)type;

- (instancetype) initWithAddress:(NSString *)address type:(MapPointType) type;


@end
