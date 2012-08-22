//
//  TrackingLocationController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackingLocationController.h"

@interface TrackingLocationController()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CLLocation *currentLocation;

@end

@implementation TrackingLocationController

@synthesize locationManager = _locationManager;
@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize currentLocation = _currentLocation;

- (void)startTrackingLocation {
    NSLog(@"startTrackingLocation");
    [self initLocationManager];
    [self trackingLocation];
//    [self stopTrackingLocation];
}

- (void)initLocationManager {
    if (!self.locationManager) self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter = self.distanceFilter;
    self.locationManager.desiredAccuracy = self.desiredAccuracy;
}

- (void)trackingLocation {
    [self.locationManager startUpdatingLocation];
    NSLog(@"currentLocation %@",self.currentLocation);
    NSLog(@"%f",self.currentLocation.coordinate.latitude);
    NSLog(@"%f",self.currentLocation.coordinate.longitude);
    NSLog(@"%@",self.currentLocation.altitude);
    NSLog(@"%@",self.currentLocation.horizontalAccuracy);
    NSLog(@"%@",self.currentLocation.verticalAccuracy);
    NSLog(@"%@",self.currentLocation.timestamp);
    NSLog(@"%@",self.currentLocation.description);
    NSLog(@"%@",self.currentLocation.speed);
    NSLog(@"%@",self.currentLocation.course);
}

- (CLLocation *)getCurrentLocation {
    [self startTrackingLocation];
    return self.currentLocation;
//    [self stopTrackingLocation];
}

- (void)stopTrackingLocation {
    NSLog(@"stopTrackingLocation");
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    self.currentLocation = newLocation;
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 5.0) return;
    if (newLocation.horizontalAccuracy < 0) return;
}

@end
