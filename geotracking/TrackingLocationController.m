//
//  TrackingLocationController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackingLocationController.h"
#import "AppDelegate.h"
#import "Location.h"
#import "Track.h"
#import "MapAnnotation.h"
#import "TrackerViewController.h"
#import "UDOAuthBasic.h"
#import "TrackerManagedDocument.h"
#import "DataSyncController.h"

#define DB_FILE @"geoTracker.sqlite"
//#define REQUIRED_ACCURACY 15.0

@interface TrackingLocationController() <NSFetchedResultsControllerDelegate, NSURLConnectionDataDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationDistance overallDistance;
@property (nonatomic) CLLocationSpeed averageSpeed;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) BOOL syncing;
@property (nonatomic, strong) Track *currentTrack;
@property (nonatomic, strong) NSTimer *syncingTimer;
@property (nonatomic, strong) NSString *trackerStatus;
@property (nonatomic, strong) DataSyncController *syncer;

@end

@implementation TrackingLocationController

@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize requiredAccuracy = _requiredAccuracy;
@synthesize locationManager = _locationManager;
@synthesize locationsDatabase = _locationsDatabase;
@synthesize locationsArray = _locationsArray;
@synthesize tableView = _tableView;
@synthesize locationManagerRunning = _locationManagerRunning;
@synthesize overallDistance = _overallDistance;
@synthesize averageSpeed = _averageSpeed;
@synthesize caller = _caller;
@synthesize summary = _summary;
@synthesize currentValues = _currentValues;
@synthesize currentAccuracy = _currentAccuracy;
@synthesize resultsController = _resultsController;
@synthesize responseData = _responseData;
@synthesize syncing = _syncing;
@synthesize currentTrack = _currentTrack;
@synthesize lastLocation = _lastLocation;
@synthesize allLocationsArray = _allLocationsArray;
@synthesize trackDetectionTimeInterval = _trackDetectionTimeInterval;
@synthesize selectedTrackNumber = _selectedTrackNumber;
@synthesize numberOfTracks = _numberOfTracks;

#pragma mark - methods


- (DataSyncController *)syncer {
    if (!_syncer) {
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        _syncer = app.syncer;
    }
    return _syncer;
}

- (void)setSyncing:(BOOL)syncing {
    if (_syncing != syncing) {
        _syncing = syncing;
        [self updateInfoLabels];
    }
}

- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Track"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO selector:@selector(compare:)]];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _resultsController.delegate = self;
    }
//    NSLog(@"self.locationsDatabase.managedObjectContext %@", self.locationsDatabase.managedObjectContext);
//    NSLog(@"_resultsController.fetchedObjects %@", _resultsController.fetchedObjects);
    return _resultsController;
}

- (NSArray *)allLocationsArray {
    NSMutableSet *allLocations = [NSMutableSet set];
    for (Track *track in self.resultsController.fetchedObjects) {
        [allLocations unionSet:track.locations];
    }
    return [allLocations sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO selector:@selector(compare:)]]];
}

- (NSArray *)locationsArrayForTrack:(NSInteger)trackNumber {
    if (trackNumber >= 0 && trackNumber < self.resultsController.fetchedObjects.count) {
        return [[[self.resultsController.fetchedObjects objectAtIndex:trackNumber] locations] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO selector:@selector(compare:)]]];
    } else {
        return nil;
    }
}

- (void)setSelectedTrackNumber:(NSInteger)selectedTrackNumber {
    [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:_selectedTrackNumber inSection:0]] setSelected:NO];
    _selectedTrackNumber = selectedTrackNumber;
    self.locationsArray = [self locationsArrayForTrack:selectedTrackNumber];
    [[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:selectedTrackNumber inSection:0]] setSelected:YES];
}

- (UIManagedDocument *)locationsDatabase {
    
    if (!_locationsDatabase) {
        UIBarButtonItem *startButton;
        TrackerViewController *caller;
        if ([self.caller isKindOfClass:[TrackerViewController class]]) {
            caller = self.caller;
        }
        startButton = caller.startButton;
        caller.startButton.enabled = NO;
        
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:DB_FILE];

//        NSLog(@"url %@", url);
//        _locationsDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        _locationsDatabase = [[TrackerManagedDocument alloc] initWithFileURL:url];
        _locationsDatabase.persistentStoreOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        [_locationsDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
        
        NSLog(@"_locationsDatabase %@", [_locationsDatabase.managedObjectModel.entitiesByName allKeys]);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[_locationsDatabase.fileURL path]]) {
            [_locationsDatabase saveToURL:_locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"locationsDatabase UIDocumentSaveForCreating success");
                [self startNewTrack];
                [self performFetch];
            }];
        } else if (_locationsDatabase.documentState == UIDocumentStateClosed) {
            [_locationsDatabase openWithCompletionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"locationsDatabase openWithCompletionHandler success");
                [self performFetch];
            }];
        } else if (_locationsDatabase.documentState == UIDocumentStateNormal) {
            caller.startButton.enabled = YES;
        }
    }
    return _locationsDatabase;
    
}

- (void)performFetch {
    NSError *error;
    if (![self.resultsController performFetch:&error]) {
        NSLog(@"performFetch error %@", error.localizedDescription);
    } else {
        if (self.resultsController.fetchedObjects.count > 0) {
            self.currentTrack = [self.resultsController.fetchedObjects objectAtIndex:0];
        }
        [self.tableView reloadData];
        [self updateInfoLabels];
    }
}

- (NSInteger)numberOfTracks {
    return self.resultsController.fetchedObjects.count;
}

- (void)startNewTrack {
    Track *track = (Track *)[NSEntityDescription insertNewObjectForEntityForName:@"Track" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    [track setXid:[self newid]];
    [track setOverallDistance:[NSNumber numberWithDouble:0.0]];
    [track setStartTime:[NSDate date]];
    [self.syncer changesCountPlusOne];
//    NSLog(@"newTrack %@", track);
    self.currentTrack = track;
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newTrack UIDocumentSaveForOverwriting success");
    }];
}

- (void)addLocation:(CLLocation *)currentLocation {

    NSDate *timestamp = currentLocation.timestamp;
    if ([currentLocation.timestamp timeIntervalSinceDate:self.lastLocation.timestamp] > self.trackDetectionTimeInterval) {
        [self startNewTrack];
//        NSLog(@"%f",[currentLocation distanceFromLocation:self.lastLocation]);
//        NSLog(@"%f",(2 * self.distanceFilter));
        if ([currentLocation distanceFromLocation:self.lastLocation] < (2 * self.distanceFilter)) {
            Location *location = (Location *)[NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
            [location setLatitude:[NSNumber numberWithDouble:self.lastLocation.coordinate.latitude]];
            [location setLongitude:[NSNumber numberWithDouble:self.lastLocation.coordinate.longitude]];
            [location setHorizontalAccuracy:[NSNumber numberWithDouble:self.lastLocation.horizontalAccuracy]];
            [location setSpeed:[NSNumber numberWithDouble:-1]];
            [location setCourse:[NSNumber numberWithDouble:-1]];
            [location setTimestamp:[NSDate date]];
            [location setXid:[self newid]];
            [self.syncer changesCountPlusOne];
            [self.currentTrack setStartTime:location.timestamp];
            [self.currentTrack addLocationsObject:location];
//            NSLog(@"copy lastLocation to new Track as first location");
        } else {
//            NSLog(@"no");
        }
        timestamp = [NSDate date];
    }
    NSNumber *overallDistance = [NSNumber numberWithDouble:[self.currentTrack.overallDistance doubleValue] + [currentLocation distanceFromLocation:self.lastLocation]];
    self.currentTrack.overallDistance = ([overallDistance doubleValue] < 0) ? [NSNumber numberWithDouble:0.0] : overallDistance;

    Location *location = (Location *)[NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    [location setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [location setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [location setHorizontalAccuracy:[NSNumber numberWithDouble:currentLocation.horizontalAccuracy]];
    [location setSpeed:[NSNumber numberWithDouble:currentLocation.speed]];
    [location setCourse:[NSNumber numberWithDouble:currentLocation.course]];
    [location setTimestamp:timestamp];
    [location setXid:[self newid]];
    [self.syncer changesCountPlusOne];

    if (self.currentTrack.locations.count == 0) {
        self.currentTrack.startTime = location.timestamp;
    }
    self.currentTrack.finishTime = location.timestamp;
    self.currentTrack.timestamp = location.timestamp;
    self.currentTrack.synced = [NSNumber numberWithBool:NO];
    [self.currentTrack addLocationsObject:location];
    
//    NSLog(@"currentLocation %@",currentLocation);


    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"addLocation UIDocumentSaveForOverwriting success");
        self.lastLocation = currentLocation;
    }];
    [self updateInfoLabels];

}

- (CLLocation *)lastLocation {
    if (!_lastLocation) {
        NSData *lastLocationData = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastLocation"];
        if (!lastLocationData) {
            _lastLocation = nil;
        } else {
            _lastLocation = [NSKeyedUnarchiver unarchiveObjectWithData:lastLocationData];
        }
    }
    return _lastLocation;
}

- (void)setLastLocation:(CLLocation *)lastLocation {
    _lastLocation = lastLocation;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSData *lastLocationData = [NSKeyedArchiver archivedDataWithRootObject:lastLocation];
    [settings setObject:lastLocationData forKey:@"lastLocation"];
    [settings synchronize];
}


- (CLLocationDistance)overallDistance {

    CLLocationDistance overallDistance = 0.0;
    for (Track *track in self.resultsController.fetchedObjects) {
        overallDistance = overallDistance + [track.overallDistance doubleValue];
    }
    return overallDistance;

}

- (CLLocationSpeed)averageSpeed {
    
    NSTimeInterval trackOverallTime = 0;
    for (Track *track in self.resultsController.fetchedObjects) {
        trackOverallTime = trackOverallTime + [track.finishTime timeIntervalSinceDate:track.startTime];
    }
    CLLocationSpeed averageSpeed = 0.0;
    if (trackOverallTime != 0) {
        averageSpeed = 3.6 * self.overallDistance / trackOverallTime;
    }
    return averageSpeed;
    
}

- (void)updateInfoLabels {
    
    NSNumberFormatter *distanceNumberFormatter = [[NSNumberFormatter alloc] init];
    [distanceNumberFormatter setMaximumFractionDigits:0];
    
    NSNumberFormatter *speedNumberFormatter = [[NSNumberFormatter alloc] init];
    [speedNumberFormatter setMaximumFractionDigits:1];

    if (!self.trackerStatus) {
        self.trackerStatus = @"";
    }
    self.summary.text = [NSString stringWithFormat:@"%@m, %@km/h %@",[distanceNumberFormatter stringFromNumber:[NSNumber numberWithDouble:self.overallDistance]],[speedNumberFormatter stringFromNumber:[NSNumber numberWithDouble:self.averageSpeed]], self.trackerStatus];
    if (self.currentAccuracy > 0) {
        self.currentValues.text = [NSString stringWithFormat:@"DA %gm, RA %gm, DF %gm, CA %gm", self.desiredAccuracy, self.requiredAccuracy, self.distanceFilter, self.currentAccuracy];
    } else {
        self.currentValues.text = [NSString stringWithFormat:@"DA %gm, RA %gm, DF %gm", self.desiredAccuracy, self.requiredAccuracy, self.distanceFilter];
    }
}

- (NSTimeInterval)trackDetectionTimeInterval {
    if (!_trackDetectionTimeInterval) {
        NSNumber *trackDetectionTimeInterval = [[NSUserDefaults standardUserDefaults] objectForKey:@"trackDetectionTimeInterval"];
        if (trackDetectionTimeInterval == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            _trackDetectionTimeInterval = 300;
            [settings setObject:[NSNumber numberWithDouble:_trackDetectionTimeInterval] forKey:@"trackDetectionTimeInterval"];
            [settings synchronize];
        } else {
            _trackDetectionTimeInterval = [trackDetectionTimeInterval doubleValue];
        }
    }
    return _trackDetectionTimeInterval;
}

- (void)setTrackDetectionTimeInterval:(NSTimeInterval)trackDetectionTimeInterval {
    _trackDetectionTimeInterval = trackDetectionTimeInterval;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:_trackDetectionTimeInterval] forKey:@"trackDetectionTimeInterval"];
    [settings synchronize];
}

- (CLLocationAccuracy)desiredAccuracy {
    if (!_desiredAccuracy) {
        NSNumber *desiredAccuracy = [[NSUserDefaults standardUserDefaults] objectForKey:@"desiredAccuracy"];
        if (desiredAccuracy == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
                _desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            [settings setObject:[NSNumber numberWithDouble:_desiredAccuracy] forKey:@"desiredAccuracy"];
            [settings synchronize];
        } else {
            _desiredAccuracy = [desiredAccuracy doubleValue];
        }
    }
    return _desiredAccuracy;
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    _desiredAccuracy = desiredAccuracy;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:desiredAccuracy] forKey:@"desiredAccuracy"];
    [settings synchronize];
    self.locationManager.desiredAccuracy = desiredAccuracy;
    [self updateInfoLabels];
}

- (CLLocationAccuracy)requiredAccuracy {
    if (!_requiredAccuracy) {
        NSNumber *requiredAccuracy = [[NSUserDefaults standardUserDefaults] objectForKey:@"requiredAccuracy"];
        if (requiredAccuracy == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            _requiredAccuracy = 10.0;
            [settings setObject:[NSNumber numberWithDouble:_requiredAccuracy] forKey:@"requiredAccuracy"];
            [settings synchronize];
        } else {
            _requiredAccuracy = [requiredAccuracy doubleValue];
        }
    }
    return _requiredAccuracy;
}

- (void)setRequiredAccuracy:(CLLocationAccuracy)requiredAccuracy {
    _requiredAccuracy = requiredAccuracy;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:requiredAccuracy] forKey:@"requiredAccuracy"];
    [settings synchronize];
    [self updateInfoLabels];
}

- (CLLocationDistance)distanceFilter {
    if (!_distanceFilter) {
        NSNumber *distanceFilter = [[NSUserDefaults standardUserDefaults] objectForKey:@"distanceFilter"];
        if (distanceFilter == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            _distanceFilter = 50.0;
            [settings setObject:[NSNumber numberWithDouble:_distanceFilter] forKey:@"distanceFilter"];
            [settings synchronize];
        } else {
            _distanceFilter = [distanceFilter doubleValue];
        }
    }
    return _distanceFilter;
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    _distanceFilter = distanceFilter;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:distanceFilter] forKey:@"distanceFilter"];
    [settings synchronize];
    self.locationManager.distanceFilter = distanceFilter;
    [self updateInfoLabels];
}

- (void)clearLocations {
    if (!self.locationManagerRunning) {
        //    NSLog(@"self.locationsDatabase %@, self.resultsController %@, self.lastLocation %@", self.locationsDatabase, self.resultsController, self.lastLocation);
        [self.locationsDatabase closeWithCompletionHandler:^(BOOL success) {
            self.locationsDatabase = nil;
            self.resultsController = nil;
            self.lastLocation = nil;
            NSError *error;
            NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            url = [url URLByAppendingPathComponent:DB_FILE];
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
//            NSLog(@"removeItemAtURL error %@", error.localizedDescription);
            [self.tableView reloadData];
        }];
    } else {
        NSLog(@"LocationManager is running, stop it first");
    }
}


- (void)startTrackingLocation {
    [[self locationManager] startUpdatingLocation];
    self.locationManagerRunning = YES;
    self.syncingTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:1800 target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:self.syncingTimer forMode:NSDefaultRunLoopMode];
}

- (void)stopTrackingLocation {
    [[self locationManager] stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
    self.locationManagerRunning = NO;
//    [self startConnection];
    [self.syncingTimer invalidate];
}

- (void)onTimerTick:(NSTimer *)timer {
//    NSLog(@"timer tick at %@", [NSDate date]);
//    [self startConnection];
}

- (NSString *)newid
{
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(nil);
    if (uuid) {
        uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuid);
        CFRelease(uuid);
    }
    
    return uuidString;
}


#pragma mark - CLLocationManager

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = self.distanceFilter;
        _locationManager.desiredAccuracy = self.desiredAccuracy;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {

    CLLocation *newLocation = [locations lastObject];
//    CLLocation *newLocation = self.locationManager.location;
//    NSLog(@"newLocation %@",newLocation);
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    self.currentAccuracy = newLocation.horizontalAccuracy;
    [self updateInfoLabels];
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy <= self.requiredAccuracy) {
//        NSLog(@"addLocation");
        [self addLocation:newLocation];
    }

}

#pragma mark - NSURLConnection

//- (void)startConnection {
//    if (!self.syncing) {
//        NSData *requestData = [self requestData];
//        if (requestData) {
//            NSURL *requestURL = [NSURL URLWithString:@"https://system.unact.ru/asa/?_host=oldcat&_svc=iexp/gt"];
//            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
//            [request setHTTPMethod:@"POST"];
//            [request setHTTPBody:requestData];
//            [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
//            NSLog(@"request %@", request);
//            NSLog(@"authenticateRequest %@", [[UDOAuthBasic sharedOAuth] authenticateRequest:(NSURLRequest *) request]);
////            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
////            if (!connection) {
////                NSLog(@"connection error");
////                self.trackerStatus = @"SYNC FAIL";
////                [self updateInfoLabels];
////                self.syncing = NO;
////            }
//        } else {
//            NSLog(@"No data to sync");
//        }
//    } else {
//        NSLog(@"Already in syncing proccess");
//    }
//}
//
//- (NSData *)requestData {
//    
//    NSPredicate *notSynced = [NSPredicate predicateWithFormat:@"SELF.synced == 0"];
//    NSArray *notSyncedLocations = [self.allLocationsArray filteredArrayUsingPredicate:notSynced];
//    NSLog(@"notSyncedLocations.count %d",notSyncedLocations.count);
//
//    NSArray *notSyncedTracks = [self.resultsController.fetchedObjects filteredArrayUsingPredicate:notSynced];
//    NSLog(@"notSyncedTracks.count %d",notSyncedTracks.count);
//
//    if (notSyncedLocations.count > 0) {
//        
//        self.trackerStatus = @"SYNC";
//        self.syncing = YES;
//
//        xmlTextWriterPtr xmlTextWriter;
//        xmlBufferPtr xmlBuffer;
//
//        xmlBuffer = xmlBufferCreate();
//        xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
//        
//        xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
//        
//            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "post");
//        
//// Locations
//        
//                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
//                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[@"Location" UTF8String]);
//
//                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "fields");
//                        NSEntityDescription *locationEntity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
//                        NSArray *entityProperties = [locationEntity.propertiesByName allKeys];
//                        for (NSString *propertyName in entityProperties) {
//                            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
//                                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "field");
//                                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
//                                xmlTextWriterEndElement(xmlTextWriter); //field
//                            }
//                        }
//                    xmlTextWriterEndElement(xmlTextWriter); //fields
//
//                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
//                        for (Location *location in notSyncedLocations) {
//                            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
//                            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[location.xid UTF8String]);
//                            NSMutableString *locationValues = [NSMutableString string];
//                            for (NSString *propertyName in entityProperties) {
//                                if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
//                                    if ([propertyName isEqualToString:@"track"]) {
//                                        [locationValues appendFormat:@"%@,",location.track.xid];
//                                    } else {
//                                        [locationValues appendFormat:@"%@,",[location valueForKey:propertyName]];
//                                    }
//                                }
//                            }
//                            if (locationValues.length > 0) [locationValues deleteCharactersInRange:NSMakeRange([locationValues length] - 1, 1)];
//                            xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[locationValues UTF8String]);
//                            xmlTextWriterEndElement(xmlTextWriter); //d
//                        }
//                    xmlTextWriterEndElement(xmlTextWriter); //cvs
//        
//                xmlTextWriterEndElement(xmlTextWriter); //set-of
//
//// Tracks
//        
//                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
//                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[@"Track" UTF8String]);
//
//                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "fields");
//                    NSEntityDescription *trackEntity = [NSEntityDescription entityForName:@"Track" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
//                    entityProperties = [trackEntity.propertiesByName allKeys];
//                    for (NSString *propertyName in entityProperties) {
//                        if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"]||[propertyName isEqualToString:@"locations"])) {
//                            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "field");
//                            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
//                            xmlTextWriterEndElement(xmlTextWriter); //field
//                        }
//                    }
//                    xmlTextWriterEndElement(xmlTextWriter); //fields
//
//                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
//                    for (Track *track in notSyncedTracks) {
//                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
//                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[track.xid UTF8String]);
//                        NSMutableString *trackValues = [NSMutableString string];
//                        for (NSString *propertyName in entityProperties) {
//                            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"]||[propertyName isEqualToString:@"locations"])) {
//                                    [trackValues appendFormat:@"%@,",[track valueForKey:propertyName]];
//                            }
//                        }
//                        if (trackValues.length > 0) [trackValues deleteCharactersInRange:NSMakeRange([trackValues length] - 1, 1)];
//                        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[trackValues UTF8String]);
//                        xmlTextWriterEndElement(xmlTextWriter); //d
//                    }
//                    xmlTextWriterEndElement(xmlTextWriter); //cvs
////
//                xmlTextWriterEndElement(xmlTextWriter); //set-of
//        
//        
//            xmlTextWriterEndElement(xmlTextWriter); //post
//        
//        xmlTextWriterEndDocument(xmlTextWriter);
//        xmlFreeTextWriter(xmlTextWriter);
//        
//        NSData *requestData = [NSData dataWithBytes:(xmlBuffer->content) length:(xmlBuffer->use)];
//        xmlBufferFree(xmlBuffer);
//        
////        NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
//        
//        return requestData;
//    } else {
//        return nil;
//    }
//}
//
//#pragma mark - NSURLConnectionDataDelegate
//
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    self.responseData = [NSMutableData data];
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    [self.responseData appendData:data];
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    
////    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
////    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
//    NSXMLParser *responseParser = [[NSXMLParser alloc] initWithData:self.responseData];
//    responseParser.delegate = self;
//    if (![responseParser parse]) {
//        NSLog(@"[responseParser parserError] %@", [responseParser parserError].localizedDescription);
//        self.trackerStatus = @"PARSER FAIL";
//        [self updateInfoLabels];
//        self.syncing = NO;
//    }
//    responseParser = nil;
//}
//
//#pragma mark - NSXMLParserDelegate
//
//- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
//
//    if ([elementName isEqualToString:@"ok"]) {
//        NSPredicate *matchedXid = [NSPredicate predicateWithFormat:@"SELF.xid == %@",[attributeDict valueForKey:@"xid"]];
//        NSArray *matchedObjects = [self.allLocationsArray filteredArrayUsingPredicate:matchedXid];
//        if (matchedObjects.count > 0) {
//            Location *location = [matchedObjects lastObject];
//            location.synced = [NSNumber numberWithBool:YES];
//            location.lastSyncTimestamp = [NSDate date];
//        } else {
//            matchedObjects = [self.resultsController.fetchedObjects filteredArrayUsingPredicate:matchedXid];
//            if (matchedObjects.count > 0) {
//                Track *track = [matchedObjects lastObject];
////                if (![track.xid isEqualToString:self.currentTrack.xid]) {
//                    track.synced = [NSNumber numberWithBool:YES];
////                }
//                track.lastSyncTimestamp = [NSDate date];
//            }
//        }
////        NSLog(@"%@", [matchedObjects lastObject]);
//    }
//
//}
//
//- (void)parserDidEndDocument:(NSXMLParser *)parser {
//    
//    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"setSynced UIDocumentSaveForOverwriting success");
//        self.trackerStatus = @"";
//        [self updateInfoLabels];
//        self.syncing = NO;
//        if (!self.locationManagerRunning) {
//            [self startConnection];
//        }
//    }];
//
//}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Tracks";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Track *track = (Track *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];

    NSDateFormatter *startDateFormatter = [[NSDateFormatter alloc] init];
    [startDateFormatter setDateStyle:NSDateFormatterShortStyle];
    [startDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSDateFormatter *finishDateFormatter = [[NSDateFormatter alloc] init];
    [finishDateFormatter setDateStyle:NSDateFormatterNoStyle];
    [finishDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSNumberFormatter *distanceNumberFormatter = [[NSNumberFormatter alloc] init];
    [distanceNumberFormatter setMaximumFractionDigits:0];
    
    NSNumberFormatter *speedNumberFormatter = [[NSNumberFormatter alloc] init];
    [speedNumberFormatter setMaximumFractionDigits:1];
    
    NSTimeInterval trackOverallTime = [track.finishTime timeIntervalSinceDate:track.startTime];
    NSNumber *speed = [NSNumber numberWithDouble:0.0];
    
    if (trackOverallTime > 0) {
        speed = [NSNumber numberWithDouble:(3.6 * [track.overallDistance doubleValue] / trackOverallTime)];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@m %@km/h %dpoints", [distanceNumberFormatter stringFromNumber:track.overallDistance], [speedNumberFormatter stringFromNumber:speed], track.locations.count];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ — %@", [startDateFormatter stringFromDate:track.startTime], [finishDateFormatter stringFromDate:track.finishTime]];

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        return UITableViewCellEditingStyleNone;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Track *track = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        for (Location *location in track.locations) {
//            NSLog(@"location to delete %@", location);
            [self.locationsDatabase.managedObjectContext deleteObject:location];
        }
//        NSLog(@"track to delete %@", track);
        [self.locationsDatabase.managedObjectContext deleteObject:track];
        [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"UIDocumentSaveForOverwriting success");
        }];
    }

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    self.selectedTrackNumber = indexPath.row;
    self.locationsArray = [self locationsArrayForTrack:indexPath.row];
    return indexPath;

}


#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
                
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [self updateInfoLabels];

    } else if (type == NSFetchedResultsChangeInsert) {
        
//        NSLog(@"NSFetchedResultsChangeInsert");

        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];

    } else if (type == NSFetchedResultsChangeUpdate) {

//        NSLog(@"NSFetchedResultsChangeUpdate");

        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

    }
}

@end