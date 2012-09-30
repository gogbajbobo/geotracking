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
@property (nonatomic) NSTimeInterval routeDetectionTimeInterval;
@property (nonatomic, strong) NSArray *locationsArray;
@property (nonatomic, strong) NSArray *allLocationsArray;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) MKMapView *mapView;
@property (nonatomic) BOOL locationManagerRunning;
@property (nonatomic) id caller;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (weak, nonatomic) UILabel *summary;
@property (weak, nonatomic) UILabel *currentValues;

- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (void)clearLocations;
- (void)startConnection;


@end
