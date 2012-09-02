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
#import "TrackerViewController.h"

#define ENTITY_NAME @"Location"
#define SORT_DESCRIPTOR @"timestamp"
#define SORT_ASCEND NO
#define DB_FILE @"geoTracker.sqlite"
#define REQUIRED_ACCURACY 15.0

@interface TrackingLocationController()

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationDistance overallDistance;
@property (nonatomic) CLLocationSpeed averageSpeed;

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
@synthesize overallDistance = _overallDistance;
@synthesize averageSpeed = _averageSpeed;
@synthesize caller = _caller;


- (void)setLocationsArray:(NSMutableArray *)locationsArray {
    if (_locationsArray != locationsArray) {
        _locationsArray = locationsArray;
        [self.tableView reloadData];
    }
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
        self.locationsDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        [self.locationsDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.locationsDatabase.fileURL path]]) {
            [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"UIDocumentSaveForCreating success");
            }];
        } else if (self.locationsDatabase.documentState == UIDocumentStateClosed) {
            [self.locationsDatabase openWithCompletionHandler:^(BOOL success) {
                self.locationsArray = [self fetchLocationData];
                caller.startButton.enabled = YES;
                NSLog(@"openWithCompletionHandler");
            }];
        } else if (self.locationsDatabase.documentState == UIDocumentStateNormal) {
            caller.startButton.enabled = YES;
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
//    NSLog(@"self.locationsArray.count %d", self.locationsArray.count);
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:2];
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].textLabel.text = [NSString stringWithFormat:@"%@m, %@m/s",[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.overallDistance]],[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.averageSpeed]]];
    
    CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:[[[self.locationsArray objectAtIndex:1] latitude] doubleValue] longitude:[[[self.locationsArray objectAtIndex:1] longitude] doubleValue]];
    self.overallDistance = self.overallDistance + [currentLocation distanceFromLocation:oldLocation];

    [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];

}

//- (CLLocationSpeed)averageSpeedCalculateWithPreviousSpeed:(CLLocationSpeed)prevSpeed {
//    CLLocationSpeed speed = 0.0;
//    if (self.locationsArray.count != 0) {
//        Location *lastLocation = [self.locationsArray objectAtIndex:0];
////        NSLog(@"lastLocation.speed %f", [lastLocation.speed doubleValue]);
////        NSLog(@"_averageSpeed %f", self.averageSpeed);
//        speed = (prevSpeed * (self.locationsArray.count - 1) + [lastLocation.speed doubleValue]) / self.locationsArray.count;
//    }
//    return speed;
//}

- (CLLocationSpeed)averageSpeed {
//    _averageSpeed = [self averageSpeedCalculateWithPreviousSpeed:_averageSpeed];
//    return _averageSpeed;
    CLLocationSpeed speed = 0.0;
    if (self.locationsArray.count != 0) {
        for (Location *location in self.locationsArray) {
            if ([location.speed doubleValue] > 0) speed = speed + [location.speed doubleValue];
        }
        speed = speed / self.locationsArray.count;
    }

    return speed;
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
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].detailTextLabel.text = [NSString stringWithFormat:@"%gm, %gm",self.desiredAccuracy, self.distanceFilter];
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

- (void)startTrackingLocation {
//    NSLog(@"startTrackingLocation");
//    self.locationsArray = [self fetchLocationData];
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
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < REQUIRED_ACCURACY) {
        [self addLocation:newLocation];
    }
}


- (NSMutableArray *)fetchLocationData {

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SORT_DESCRIPTOR ascending:SORT_ASCEND selector:@selector(localizedCaseInsensitiveCompare:)]];
    
    self.overallDistance = 0.0;
    
	NSError *error;
	NSMutableArray *mutableFetchResults = [[self.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
        NSLog(@"executeFetchRequest error %@", error.localizedDescription);
	}
    
    if (mutableFetchResults.count > 0) {
        Location *temp = [mutableFetchResults objectAtIndex:0];
        CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:[temp.latitude doubleValue] longitude:[temp.longitude doubleValue]];     
        for (Location *temp in mutableFetchResults) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[temp.latitude doubleValue] longitude:[temp.longitude doubleValue]];
            self.overallDistance = self.overallDistance + [location distanceFromLocation:oldLocation];
            oldLocation = location;
        }
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
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setMaximumFractionDigits:2];

        cell.textLabel.text = [NSString stringWithFormat:@"%@m, %@m/s          ",[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.overallDistance]],[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.averageSpeed]]];

        cell.detailTextLabel.text = [NSString stringWithFormat:@"Accuracy %gm, Distance %gm",self.desiredAccuracy, self.distanceFilter];
    } else {
        Location *location = (Location *)[self.locationsArray objectAtIndex:indexPath.row];

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        
        cell.textLabel.text = [dateFormatter stringFromDate:location.timestamp];
        
        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
        [numberFormatter setMaximumFractionDigits:3];
        
        NSString *string = [NSString stringWithFormat:@"lat%@ lon%@ %@m %@m/s %@deg", [numberFormatter stringFromNumber:location.latitude], [numberFormatter stringFromNumber:location.longitude], [numberFormatter stringFromNumber:location.horizontalAccuracy], [numberFormatter stringFromNumber:location.speed], [numberFormatter stringFromNumber:location.course]];
        cell.detailTextLabel.text = string;

    }
    
    return cell;
}


@end
