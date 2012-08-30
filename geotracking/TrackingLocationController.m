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
#import "MapAnnotation.h"

#define ENTITY_NAME @"Location"
#define SORT_DESCRIPTOR @"timestamp"
#define SORT_ASCEND NO
#define DB_FILE @"geoTracker.sqlite"

@interface TrackingLocationController()

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation TrackingLocationController

@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize locationManager = _locationManager;
@synthesize locationsDatabase = _locationsDatabase;
@synthesize locationsArray = _locationsArray;
@synthesize tableView = _tableView;
@synthesize mapView = _mapView;
@synthesize locationManagerRunning = _locationManagerRunning;


- (void)setLocationsArray:(NSMutableArray *)locationsArray {
    if (_locationsArray != locationsArray) {
        _locationsArray = locationsArray;
        [self.tableView reloadData];
    }
}

- (UIManagedDocument *)locationsDatabase {
    
    if (!_locationsDatabase) {
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:DB_FILE];
        self.locationsDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        [self.locationsDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.locationsDatabase.fileURL path]]) {
            [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                NSLog(@"UIDocumentSaveForCreating success");
            }];
        } else if (self.locationsDatabase.documentState == UIDocumentStateClosed) {
            [self.locationsDatabase openWithCompletionHandler:^(BOOL success) {
                self.locationsArray = [self fetchLocationData];
                NSLog(@"openWithCompletionHandler");
            }];
        } else if (self.locationsDatabase.documentState == UIDocumentStateNormal) {
        }
    }
    return _locationsDatabase;
    
}

- (void)addLocation:(CLLocation *)currentLocation {

    Location *location = (Location *)[NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    [location setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [location setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [location setHorizontalAccuracy:[NSNumber numberWithDouble:currentLocation.horizontalAccuracy]];
    [location setSpeed:[NSNumber numberWithDouble:currentLocation.speed]];
    [location setCourse:[NSNumber numberWithDouble:currentLocation.course]];
    [location setTimestamp:[currentLocation timestamp]];
    
    NSLog(@"currentLocation %@",currentLocation);
//    NSLog(@"horizontalAccuracy %f",currentLocation.horizontalAccuracy);
//    NSLog(@"distanceFilter %f",locationManager.distanceFilter);
//    NSLog(@"desiredAccuracy %f",locationManager.desiredAccuracy);
    
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"UIDocumentSaveForOverwriting success");
    }];

    [self.locationsArray insertObject:location atIndex:0];
    NSLog(@"self.locationsArray.count %d", self.locationsArray.count);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].textLabel.text = [NSString stringWithFormat:@"%gm, %gm/s, %g",[location.horizontalAccuracy doubleValue],[location.speed doubleValue],[location.course doubleValue]];
    
    [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];

}

- (CLLocationAccuracy)desiredAccuracy {
    if (!_desiredAccuracy) _desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    return _desiredAccuracy;
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    _desiredAccuracy = desiredAccuracy;
    self.locationManager.desiredAccuracy = desiredAccuracy;
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].detailTextLabel.text = [NSString stringWithFormat:@"%gm, %gm",self.desiredAccuracy, self.distanceFilter];
;
}

- (CLLocationDistance)distanceFilter {
    if (!_distanceFilter) _distanceFilter = kCLDistanceFilterNone;
    return _distanceFilter;
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    _distanceFilter = distanceFilter;
    self.locationManager.distanceFilter = distanceFilter;
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].detailTextLabel.text = [NSString stringWithFormat:@"%gm, %gm",self.desiredAccuracy, self.distanceFilter];
}

- (void)clearLocations {
    for (Location *location in self.locationsArray) {
        [self.locationsDatabase.managedObjectContext deleteObject:location];
    }
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"UIDocumentSaveForOverwriting success");
    }];
    self.locationsArray = [self fetchLocationData];
}

//- (void)restartLocationManager {
//    [self stopTrackingLocation];
//    [self startTrackingLocation];
//}

- (void)startTrackingLocation {
//    NSLog(@"startTrackingLocation");
    self.locationsArray = [self fetchLocationData];
    [[self locationManager] startUpdatingLocation];
    self.locationManagerRunning = YES;
}

- (void)stopTrackingLocation {
//    NSLog(@"stopTrackingLocation");
    [[self locationManager] stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
    self.locationManagerRunning = NO;
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = self.distanceFilter;
        _locationManager.desiredAccuracy = self.desiredAccuracy;        
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0) [self addLocation:newLocation];
}


- (NSMutableArray *)fetchLocationData {

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SORT_DESCRIPTOR ascending:SORT_ASCEND selector:@selector(localizedCaseInsensitiveCompare:)]];
    
	NSError *error;
	NSMutableArray *mutableFetchResults = [[self.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
        NSLog(@"executeFetchRequest error %@", error.localizedDescription);
	}
    return mutableFetchResults;

}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        if (section == 0) {
            return 1;
        } else {
            return self.locationsDatabase.managedObjectContext.registeredObjects.count;
        }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return @"Summary";
    } else {
        return @"Locations";
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Location";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (indexPath.section == 0) {
        Location *location = (Location *)[self.locationsArray lastObject];
        cell.textLabel.text = [NSString stringWithFormat:@"%gm, %gm/s, %g",[location.horizontalAccuracy doubleValue],[location.speed doubleValue],[location.course doubleValue]];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Accuracy %gm, Distance %gm",self.desiredAccuracy, self.distanceFilter];
    } else {
        Location *location = (Location *)[self.locationsArray objectAtIndex:indexPath.row];        
        cell.textLabel.text = [NSString stringWithFormat:@"%@",location.timestamp];
        NSString *string = [NSString stringWithFormat:@"%@, %@",location.latitude,location.longitude];
        cell.detailTextLabel.text = string;
    }
    
    return cell;
}


@end
