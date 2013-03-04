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
#import "STGTSettingsController.h"
#import "STGTGeoTrackable.h"
#import "STGTTrackerManagedDocument.h"


@interface STGTTrackingLocationController : NSObject <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) CLLocationAccuracy currentAccuracy;
@property (nonatomic, strong) NSArray *locationsArray;
@property (nonatomic, strong) NSArray *allLocationsArray;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) BOOL locationManagerRunning;
//@property (nonatomic) id caller;
@property (nonatomic, strong) CLLocation *lastLocation;
@property (weak, nonatomic) UILabel *summary;
@property (weak, nonatomic) UILabel *currentValues;
@property (nonatomic) NSInteger selectedTrackNumber;
@property (nonatomic) NSInteger numberOfTracks;
//@property (nonatomic, strong) UIManagedDocument *locationsDatabase;
//@property (nonatomic) BOOL syncing;
@property (nonatomic, strong) NSString *trackerStatus;
@property (nonatomic, strong) STGTSettings *settings;
@property (nonatomic, strong) id <STGTSession> session;
@property (nonatomic, strong) STGTTrackerManagedDocument *document;


//- (void)initDatabase:(void (^)(BOOL success))completionHandler;
- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (void)clearLocations;
- (void)clearAllData;
- (NSArray *)locationsArrayForTrack:(NSInteger)trackNumber;
- (NSString *)newid;
- (void)updateInfoLabels;
- (void)trackerInit;
//+ (STGTTrackingLocationController *)sharedTracker;

@end
