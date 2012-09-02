//
//  TrackingLocationController.h
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface TrackingLocationController : NSObject <CLLocationManagerDelegate,UITableViewDataSource>

@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;

- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (void)clearLocations;

@property (nonatomic, strong) NSMutableArray *locationsArray;
@property (nonatomic, strong) UIManagedDocument *locationsDatabase;

- (void)addLocation:(CLLocation *)currentLocation;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) BOOL locationManagerRunning;
@property (nonatomic) id caller;
@property (nonatomic) BOOL sendAnnotationsToMap;

@end
