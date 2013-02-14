//
//  TrackingLocationController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTTrackingLocationController.h"
#import "STGTLocation.h"
#import "STGTTrack.h"
#import "STGTMapAnnotation.h"
#import "STGTTrackerViewController.h"
#import "STGTTrackerManagedDocument.h"
#import "STGTDataSyncController.h"
#import "STGTSettings.h"
#import "STGTAuthBasic.h"

#define DB_FILE @"geoTracker.sqlite"
#define REQUIRED_ACCURACY 15.0

@interface STGTTrackingLocationController() <NSFetchedResultsControllerDelegate, NSURLConnectionDataDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationDistance overallDistance;
@property (nonatomic) CLLocationSpeed averageSpeed;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) STGTTrack *currentTrack;
@property (nonatomic, strong) STGTDataSyncController *syncer;
@property (nonatomic, strong) NSTimer *timer;


@end

@implementation STGTTrackingLocationController

@synthesize locationManager = _locationManager;
@synthesize locationsDatabase = _locationsDatabase;
@synthesize locationsArray = _locationsArray;
@synthesize tableView = _tableView;
@synthesize locationManagerRunning = _locationManagerRunning;
@synthesize overallDistance = _overallDistance;
@synthesize averageSpeed = _averageSpeed;
//@synthesize caller = _caller;
@synthesize summary = _summary;
@synthesize currentValues = _currentValues;
@synthesize currentAccuracy = _currentAccuracy;
@synthesize resultsController = _resultsController;
@synthesize responseData = _responseData;
@synthesize currentTrack = _currentTrack;
@synthesize lastLocation = _lastLocation;
@synthesize allLocationsArray = _allLocationsArray;
@synthesize selectedTrackNumber = _selectedTrackNumber;
@synthesize numberOfTracks = _numberOfTracks;

#pragma mark - methods

+ (STGTTrackingLocationController *)sharedTracker
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedTracker = nil;
    dispatch_once(&pred, ^{
        _sharedTracker = [[self alloc] init];
    });
    return _sharedTracker;
}

- (STGTDataSyncController *)syncer {
    if (!_syncer) {
        _syncer = [STGTDataSyncController sharedSyncer];
    }
    return _syncer;
}

- (STGTSettings *)settings {
    if (!_settings && self.locationsDatabase.documentState == UIDocumentStateNormal) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTSettings"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        NSError *error;
        STGTSettings *settings = (STGTSettings *)[[self.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error] lastObject];

        if (!settings) {
            settings = (STGTSettings *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTSettings" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
            [settings setValuesForKeysWithDictionary:[STGTSettingsController defaultSettings]];
//            [settings setValue:[self newid] forKey:@"xid"];
            
            [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                NSLog(@"settings create UIDocumentSaveForOverwriting success");
            }];
            
        } else {
            NSLog(@"settings load from locationsDatabase success");
        }
        [settings addObserver:self forKeyPath:@"distanceFilter" options:NSKeyValueObservingOptionNew context:nil];
        [settings addObserver:self forKeyPath:@"desiredAccuracy" options:NSKeyValueObservingOptionNew context:nil];
        [settings addObserver:self forKeyPath:@"requiredAccuracy" options:NSKeyValueObservingOptionNew context:nil];
        [settings addObserver:self forKeyPath:@"trackerAutoStart" options:NSKeyValueObservingOptionNew context:nil];
        [settings addObserver:self forKeyPath:@"localAccessToSettings" options:NSKeyValueObservingOptionNew context:nil];

//        NSLog(@"settings.xid %@", settings.xid);
//        NSLog(@"settings.lts %@", settings.lts);
//        NSLog(@"settings.distanceFilter %@", settings.distanceFilter);
        _settings = settings;
    }
    return _settings;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSLog(@"observeValueForKeyPath");
//    NSLog(@"object %@", object);
//    NSLog(@"change %@", change);
    if ([keyPath isEqualToString:@"distanceFilter"] || [keyPath isEqualToString:@"desiredAccuracy"] || [keyPath isEqualToString:@"requiredAccuracy"]) {
        self.locationManager.distanceFilter = [self.settings.distanceFilter doubleValue];
        self.locationManager.desiredAccuracy = [self.settings.desiredAccuracy doubleValue];
        [self updateInfoLabels];
    } else if ([keyPath isEqualToString:@"trackerAutoStart"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerAutoStartChanged" object:self];
    } else if ([keyPath isEqualToString:@"localAccessToSettings"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerAccessToSettingsChanged" object:self];
    }
    
//    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"observeValueForKeyPath change: UIDocumentSaveForOverwriting success");
//    }];
    
    
//    NSTimer *timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:10 target:self selector:@selector(timerTest) userInfo:nil repeats:NO];
////    NSLog(@"[timer isValid] %d", [timer isValid]);
//    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
////    NSLog(@"[timer isValid] %d", [timer isValid]);
//    [timer invalidate];
////    NSLog(@"[timer isValid] %d", [timer isValid]);
////    NSLog(@"[self.timer isValid] %d", [self.timer isValid]);

}

//- (void)timerTest {
////    NSLog(@"test");
//}

- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTTrack"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO selector:@selector(compare:)]];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.locationsDatabase.managedObjectContext sectionNameKeyPath:@"dayAsString" cacheName:nil];
        _resultsController.delegate = self;
    }
//    NSLog(@"self.locationsDatabase.managedObjectContext %@", self.locationsDatabase.managedObjectContext);
//    NSLog(@"_resultsController.fetchedObjects %@", _resultsController.fetchedObjects);
    return _resultsController;
}

- (NSArray *)allLocationsArray {
    NSMutableSet *allLocations = [NSMutableSet set];
    for (STGTTrack *track in self.resultsController.fetchedObjects) {
        [allLocations unionSet:track.locations];
    }
    return [allLocations sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:NO selector:@selector(compare:)]]];
}

- (NSArray *)locationsArrayForTrack:(NSInteger)trackNumber {
    if (trackNumber >= 0 && trackNumber < self.resultsController.fetchedObjects.count) {
        return [[[self.resultsController.fetchedObjects objectAtIndex:trackNumber] locations] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:NO selector:@selector(compare:)]]];
    } else {
        return nil;
    }
}

- (void)setSelectedTrackNumber:(NSInteger)selectedTrackNumber {
    NSLog(@"selectedTrackNumber %d", selectedTrackNumber);
    NSLog(@"self.tableView indexPathForSelectedRow %@", [self.tableView indexPathForSelectedRow]);
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:NO];
    _selectedTrackNumber = selectedTrackNumber;
    self.locationsArray = [self locationsArrayForTrack:selectedTrackNumber];
    
    NSInteger sectionNumber = 0;
    for (id <NSFetchedResultsSectionInfo> sectionInfo in [self.resultsController sections]) {
        NSLog(@"_________________");
        NSLog(@"sectionInfo numberOfObjects %d", [sectionInfo numberOfObjects]);
        if ([sectionInfo numberOfObjects] > selectedTrackNumber) {
            NSLog(@"[sectionInfo numberOfObjects] > selectedTrackNumber");
            NSLog(@"indexPathForRow inSection %@", [NSIndexPath indexPathForRow:selectedTrackNumber inSection:sectionNumber]);
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:selectedTrackNumber inSection:sectionNumber] animated:NO scrollPosition:UITableViewScrollPositionNone];
            NSLog(@"self.tableView indexPathForSelectedRow %@", [self.tableView indexPathForSelectedRow]);
            break;
        } else {
            selectedTrackNumber -= [sectionInfo numberOfObjects];
            sectionNumber++;
            NSLog(@"selectedTrackNumber- %d", selectedTrackNumber);
            NSLog(@"sectionNumber %d", sectionNumber);
        }
    }
    
}

- (UIManagedDocument *)locationsDatabase {
    
    if (!_locationsDatabase) {
    
        [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerBusy" object:self];

        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:DB_FILE];

//        NSLog(@"url %@", url);
//        _locationsDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        _locationsDatabase = [[STGTTrackerManagedDocument alloc] initWithFileURL:url];
        _locationsDatabase.persistentStoreOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
        [_locationsDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
        
//        NSLog(@"fileExistsAtPath: %d", [[NSFileManager defaultManager] fileExistsAtPath:[_locationsDatabase.fileURL path]]);
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[_locationsDatabase.fileURL path]]) {
            [_locationsDatabase saveToURL:_locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                [_locationsDatabase closeWithCompletionHandler:^(BOOL success) {
                    [_locationsDatabase openWithCompletionHandler:^(BOOL success) {
                        NSLog(@"locationsDatabase UIDocumentSaveForCreating success");
                        [self trackerInit];
                        [self startNewTrack];
                        [self performFetch];
                    }];
                }];
            }];
        } else if (_locationsDatabase.documentState == UIDocumentStateClosed) {
            [_locationsDatabase openWithCompletionHandler:^(BOOL success) {
                NSLog(@"locationsDatabase openWithCompletionHandler success");
                [self trackerInit];
                [self performFetch];
            }];
        } else if (_locationsDatabase.documentState == UIDocumentStateNormal) {
            [self trackerInit];
        }
    }
    return _locationsDatabase;
}

- (void)trackerInit {
    NSLog(@"trackerInit");
    [[STGTDataSyncController sharedSyncer] setAuthDelegate:[STGTAuthBasic sharedOAuth]];
    [[STGTDataSyncController sharedSyncer] startSyncer];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerReady" object:self];
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];

//    [self testDeleteTrack];

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
    STGTTrack *track = (STGTTrack *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTTrack" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
//    [track setXid:[self newid]];
    [track setOverallDistance:[NSNumber numberWithDouble:0.0]];
    NSDate *ts = [NSDate date];
    [track setStartTime:ts];
//    [self.syncer changesCountPlusOne];
//    NSLog(@"newTrack %@", track);
    self.currentTrack = track;
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newTrack UIDocumentSaveForOverwriting success");
    }];
}

- (void)addLocation:(CLLocation *)currentLocation {

    NSDate *timestamp = currentLocation.timestamp;
    if ([currentLocation.timestamp timeIntervalSinceDate:self.lastLocation.timestamp] > [self.settings.trackDetectionTime doubleValue]) {
        [self startNewTrack];
        if ([currentLocation distanceFromLocation:self.lastLocation] < (2 * [self.settings.distanceFilter doubleValue])) {
            NSDate *ts = [NSDate date];
            STGTLocation *location = (STGTLocation *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTLocation" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
            [location setLatitude:[NSNumber numberWithDouble:self.lastLocation.coordinate.latitude]];
            [location setLongitude:[NSNumber numberWithDouble:self.lastLocation.coordinate.longitude]];
            [location setHorizontalAccuracy:[NSNumber numberWithDouble:self.lastLocation.horizontalAccuracy]];
            [location setSpeed:[NSNumber numberWithDouble:-1]];
            [location setCourse:[NSNumber numberWithDouble:-1]];
            [location setAltitude:[NSNumber numberWithDouble:self.lastLocation.altitude]];
            [location setVerticalAccuracy:[NSNumber numberWithDouble:self.lastLocation.verticalAccuracy]];
//            [location setXid:[self newid]];
//            [self.syncer changesCountPlusOne];
            [self.currentTrack setStartTime:ts];
            [self.currentTrack addLocationsObject:location];
//            NSLog(@"copy lastLocation to new Track as first location");
        } else {
//            NSLog(@"no");
            self.lastLocation = currentLocation;
        }
        timestamp = [NSDate date];
    }
    NSNumber *overallDistance = [NSNumber numberWithDouble:[self.currentTrack.overallDistance doubleValue] + [currentLocation distanceFromLocation:self.lastLocation]];
    self.currentTrack.overallDistance = ([overallDistance doubleValue] < 0) ? [NSNumber numberWithDouble:0.0] : overallDistance;

    STGTLocation *location = (STGTLocation *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTLocation" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    [location setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [location setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [location setHorizontalAccuracy:[NSNumber numberWithDouble:currentLocation.horizontalAccuracy]];
    [location setSpeed:[NSNumber numberWithDouble:currentLocation.speed]];
    [location setCourse:[NSNumber numberWithDouble:currentLocation.course]];
    [location setAltitude:[NSNumber numberWithDouble:currentLocation.altitude]];
    [location setVerticalAccuracy:[NSNumber numberWithDouble:currentLocation.verticalAccuracy]];
//    [location setXid:[self newid]];
//    [self.syncer changesCountPlusOne];

    if (self.currentTrack.locations.count == 0) {
        self.currentTrack.startTime = timestamp;
    }
    self.currentTrack.finishTime = timestamp;
    [self.currentTrack addLocationsObject:location];
    
//    NSLog(@"currentLocation %@",currentLocation);

    self.lastLocation = currentLocation;

    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"addLocation UIDocumentSaveForOverwriting success");
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
    for (STGTTrack *track in self.resultsController.fetchedObjects) {
        overallDistance = overallDistance + [track.overallDistance doubleValue];
    }
    return overallDistance;

}

- (CLLocationSpeed)averageSpeed {
    
    NSTimeInterval trackOverallTime = 0;
    for (STGTTrack *track in self.resultsController.fetchedObjects) {
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
    
    NSString *numberOfNotSyncedItems;
    NSNumber *number = [[STGTDataSyncController sharedSyncer] numberOfUnsynced];
    if (number > 0) {
        numberOfNotSyncedItems = [number stringValue];
    } else {
        numberOfNotSyncedItems = @"";
    }
    
    self.summary.text = [NSString stringWithFormat:@"%@m, %@km/h %@ /%@",[distanceNumberFormatter stringFromNumber:[NSNumber numberWithDouble:self.overallDistance]],[speedNumberFormatter stringFromNumber:[NSNumber numberWithDouble:self.averageSpeed]], self.trackerStatus, numberOfNotSyncedItems];
    if (self.currentAccuracy > 0) {
        self.currentValues.text = [NSString stringWithFormat:@"DA %@m, RA %@m, DF %@m, CA %gm", self.settings.desiredAccuracy, self.settings.requiredAccuracy, self.settings.distanceFilter, self.currentAccuracy];
    } else {
        self.currentValues.text = [NSString stringWithFormat:@"DA %@m, RA %@m, DF %@m", self.settings.desiredAccuracy, self.settings.requiredAccuracy, self.settings.distanceFilter];
    }
}

//- (void)testDeleteTrack {
//    NSDate *localDate = [NSDate date];
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
//    NSString *string = [dateFormatter stringFromDate:localDate];
//    NSDate *todayStart = [dateFormatter dateFromString:string];
//    NSLog(@"localDate %@", localDate);
//    NSLog(@"todayStart %@", todayStart);
//
//    double days = 5;
//    double hours = 5;
//    double seconds = (days * 24 * 3600) + (hours * 3600);
//    NSDate *testDate = [NSDate dateWithTimeInterval:-seconds sinceDate:todayStart];
//    NSLog(@"testDate %@", testDate);
//    [self deleteTracksOlderThan:testDate];
//    
//}

- (void)deleteTracksOlderThan:(NSDate *)date {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTTrack"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sqts" ascending:YES selector:@selector(compare:)]];
    [request setIncludesSubentities:YES];
    request.predicate = [NSPredicate predicateWithFormat:@"SELF.ts < SELF.lts && SELF.ts < %@", date];
    NSError *error;
    NSArray *result = [self.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
    NSLog(@"result.count %d", result.count);
    for (STGTTrack *track in result) {
//        NSLog(@"track %@", track);
//        [self deleteTrack:track];
    }

}

- (void)deleteTrack:(STGTTrack *)track {
    [self.locationsDatabase.managedObjectContext deleteObject:track];
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"deleteTrack UIDocumentSaveForOverwriting success");
    }];
}

- (void)clearLocations {
    BOOL wasRunning = self.locationManagerRunning;
    if (wasRunning) {
        [self stopTrackingLocation];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerBusy" object:self];
    if ([self.settings.localAccessToSettings boolValue]) {
        for (STGTTrack *track in self.resultsController.fetchedObjects) {
            [self deleteTrack:track];
        }
        self.lastLocation = nil;
        [self startNewTrack];
    } else {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ts < SELF.lts"];
        NSArray *syncedObjects = [self.resultsController.fetchedObjects filteredArrayUsingPredicate:predicate];
        for (STGTTrack *track in syncedObjects) {
            [self deleteTrack:track];
        }
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerReady" object:self];
    if (wasRunning) {
        [self startTrackingLocation];
    }
}

- (void)clearAllData {
    if (!self.locationManagerRunning) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerBusy" object:self];
        [[STGTDataSyncController sharedSyncer] stopSyncer];
        [self.locationsDatabase closeWithCompletionHandler:^(BOOL success) {
            [self.settings removeObserver:self forKeyPath:@"distanceFilter"];
            [self.settings removeObserver:self forKeyPath:@"desiredAccuracy"];
            [self.settings removeObserver:self forKeyPath:@"requiredAccuracy"];
            self.settings = nil;
            self.locationsDatabase = nil;
            self.resultsController = nil;
            self.lastLocation = nil;
            [self.timer invalidate];
            NSError *error;
            NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
            url = [url URLByAppendingPathComponent:DB_FILE];
            [[NSFileManager defaultManager] removeItemAtURL:url error:&error];
            [self.tableView reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerReady" object:self];
        }];
    } else {
        NSLog(@"LocationManager is running, stop it first");
    }
}

- (void)startTrackingLocation {
    [[self locationManager] startUpdatingLocation];
    self.locationManagerRunning = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerStart" object:self];
    NSLog(@"startTrackingLocation");
}

- (void)stopTrackingLocation {
    [[self locationManager] stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
    self.locationManagerRunning = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTTrackerStop" object:self];
    NSLog(@"stopTrackingLocation");
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


- (double)currentTime {
    NSDate *localDate = [NSDate date];
    NSDateFormatter *hourFormatter = [[NSDateFormatter alloc] init];
    hourFormatter.dateFormat = @"HH";
    double hour = [[hourFormatter stringFromDate:localDate] doubleValue];
    NSDateFormatter *minuteFormatter = [[NSDateFormatter alloc] init];
    minuteFormatter.dateFormat = @"mm";
    double minute = [[minuteFormatter stringFromDate:localDate] doubleValue];
    double currentTime = hour + minute/60;
    
//    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
//    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
//    NSString *string = [dateFormatter stringFromDate:localDate];
//    double timerTime = 13.25;
//    double seconds = timerTime * 3600;
//    NSLog(@"localDate %@", localDate);
//    NSLog(@"dateFromString %@", [dateFormatter dateFromString:string]);
//    NSLog(@"dateWithTimeInterval %@", [NSDate dateWithTimeInterval:seconds sinceDate:[dateFormatter dateFromString:string]]);

    return currentTime;
}

- (void)checkTrackerAutoStart {
    if ([self.settings.trackerStartTime doubleValue] < [self.settings.trackerFinishTime doubleValue]) {
//        NSLog(@"trackerStartTime < trackerFinishTime");
        if ([self currentTime] > [self.settings.trackerStartTime doubleValue] && [self currentTime] < [self.settings.trackerFinishTime doubleValue]) {
            if (!self.locationManagerRunning) {
                [self startTrackingLocation];
            }
        } else {
            if (self.locationManagerRunning) {
                [self stopTrackingLocation];
            }
        }
    } else {
//        NSLog(@"trackerStartTime > trackerFinishTime");
        if ([self currentTime] < [self.settings.trackerStartTime doubleValue] && [self currentTime] > [self.settings.trackerFinishTime doubleValue]) {
            if (self.locationManagerRunning) {
                [self stopTrackingLocation];
            }
        } else {
            if (!self.locationManagerRunning) {
                [self startTrackingLocation];
            }
        }            
    }
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:60 target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
    }
    return _timer;
}

- (void)onTimerTick:(NSTimer *)timer {
    if ([self.settings.trackerAutoStart boolValue]) {
        [self checkTrackerAutoStart];
    } else {
//        NSLog(@"No autostart");
    }

}



#pragma mark - CLLocationManager

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = [self.settings.distanceFilter doubleValue];
        _locationManager.desiredAccuracy = [self.settings.desiredAccuracy doubleValue];
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
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy <= [self.settings.requiredAccuracy doubleValue]) {
//        NSLog(@"addLocation");
        [self addLocation:newLocation];
    }

}



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
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];

    double ddistance = 0;
    for (STGTTrack *track in [sectionInfo objects]) {
        ddistance += [track.overallDistance doubleValue];
    }
    int idistance = ddistance;

    NSString *tr;
    if ([sectionInfo numberOfObjects] == 1) {
        tr = @"track";
    } else {
        tr = @"tracks";
    }

    return [NSString stringWithFormat:@"%@ - %d %@ - %dm", [sectionInfo name], [sectionInfo numberOfObjects], tr, idistance];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
//    STGTTrack *track = (STGTTrack *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];

    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:indexPath.section];
    STGTTrack *track = (STGTTrack *)[[sectionInfo objects] objectAtIndex:indexPath.row];


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
    
//    request.predicate = [NSPredicate predicateWithFormat:@"SELF.lts == %@ || SELF.ts > SELF.lts", nil];
//    if ([localDate compare:serverDate] == NSOrderedAscending) {
//        //                            NSLog(@"serverDate > localDate");

    UIColor *textColor;
    if ([track.ts compare:track.lts] == NSOrderedAscending) {
        textColor = [UIColor grayColor];
        cell.tag = 1;
    } else {
        textColor = [UIColor blackColor];
    }
    cell.textLabel.textColor = textColor;
    cell.detailTextLabel.textColor = textColor;

    if (trackOverallTime > 0) {
        speed = [NSNumber numberWithDouble:(3.6 * [track.overallDistance doubleValue] / trackOverallTime)];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@m %@km/h %dpoints", [distanceNumberFormatter stringFromNumber:track.overallDistance], [speedNumberFormatter stringFromNumber:speed], track.locations.count];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ — %@", [startDateFormatter stringFromDate:track.startTime], [finishDateFormatter stringFromDate:track.finishTime]];

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return UITableViewCellEditingStyleNone;
    } else {
        if (![self.settings.localAccessToSettings boolValue] && [tableView cellForRowAtIndexPath:indexPath].tag == 0) {
            return UITableViewCellEditingStyleNone;
        } else {
            return UITableViewCellEditingStyleDelete;
        }
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        STGTTrack *track = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:indexPath.section];
        STGTTrack *track = (STGTTrack *)[[sectionInfo objects] objectAtIndex:indexPath.row];
        [self deleteTrack:track];
    }

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSInteger trackNumber = 0;
    for (int i = 0; i < indexPath.section; i++) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:i];
        trackNumber = trackNumber + [sectionInfo numberOfObjects];
    }
    trackNumber = trackNumber + indexPath.row;
//    self.selectedTrackNumber = indexPath.row;
    self.selectedTrackNumber = trackNumber;
    self.locationsArray = [self locationsArrayForTrack:trackNumber];
    return indexPath;

}


#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
        
//        NSLog(@"NSFetchedResultsChangeDelete");
        
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self updateInfoLabels];

    } else if (type == NSFetchedResultsChangeInsert) {
        
//        NSLog(@"NSFetchedResultsChangeInsert");

        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];

    } else if (type == NSFetchedResultsChangeUpdate) {

//        NSLog(@"NSFetchedResultsChangeUpdate");

        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];

    }
}

@end