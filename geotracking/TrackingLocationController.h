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
#import <CoreData/CoreData.h>
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>


@interface TrackingLocationController : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;
@property (nonatomic) CLLocationAccuracy currentAccuracy;
@property (nonatomic) CLLocationAccuracy requiredAccuracy;
@property (nonatomic) NSTimeInterval trackDetectionTimeInterval;
@property (nonatomic, strong) NSArray *locationsArray;
@property (nonatomic, strong) NSArray *allLocationsArray;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) BOOL locationManagerRunning;
@property (nonatomic) id caller;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (weak, nonatomic) UILabel *summary;
@property (weak, nonatomic) UILabel *currentValues;
@property (nonatomic) NSInteger selectedTrackNumber;
@property (nonatomic) NSInteger numberOfTracks;
@property (nonatomic, strong) UIManagedDocument *locationsDatabase;


- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (void)clearLocations;
//- (void)startConnection;
- (NSArray *)locationsArrayForTrack:(NSInteger)trackNumber;
- (NSString *)newid;

@end
