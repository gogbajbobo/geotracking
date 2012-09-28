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
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>


@interface TrackingLocationController : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;
@property (nonatomic) CLLocationAccuracy currentAccuracy;

- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (void)clearLocations;
- (void)startConnection;

@property (nonatomic, strong) NSArray *locationsArray;
@property (nonatomic, strong) UIManagedDocument *locationsDatabase;

- (void)addLocation:(CLLocation *)currentLocation;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) MKMapView *mapView;
@property (weak, nonatomic) UILabel *summary;
@property (weak, nonatomic) UILabel *currentValues;
@property (nonatomic) BOOL locationManagerRunning;
@property (nonatomic) id caller;
@property (nonatomic) BOOL sendAnnotationsToMap;

@end
