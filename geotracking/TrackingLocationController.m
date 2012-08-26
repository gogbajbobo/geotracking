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

@interface TrackingLocationController() {
    
    CLLocationManager *locationManager;
    
}

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) CLLocationDistance *overalDistance;

@end

@implementation TrackingLocationController

@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize managedObjectContext, locationsArray, locationManager;

@synthesize tableView = _tableView;
@synthesize mapView = _mapView;
@synthesize locationManagerRunning = _locationManagerRunning;

@synthesize overalDistance = _overalDistance;

- (NSMutableArray *)locationsArray {
    if(!locationsArray) locationsArray = [self fetchLocationData];
    return locationsArray;
}

- (void)addLocation {
    CLLocation *currentLocation = [locationManager location];
	Location *location = (Location *)[NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:managedObjectContext];
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
    
	NSError *error;
	if (![managedObjectContext save:&error]) {
        NSLog(@"managedObjectContext save:&error %@", error.localizedDescription);
	}

    [locationsArray insertObject:location atIndex:0];
    
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:1];
    [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
	[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].textLabel.text = [NSString stringWithFormat:@"%gm, %gm/s, %g",[location.horizontalAccuracy doubleValue],[location.speed doubleValue],[location.course doubleValue]];
}

- (CLLocationAccuracy)desiredAccuracy {
    if (!_desiredAccuracy) _desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    return _desiredAccuracy;
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    _desiredAccuracy = desiredAccuracy;
    locationManager.desiredAccuracy = desiredAccuracy;
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].detailTextLabel.text = [NSString stringWithFormat:@"%gm, %gm",self.desiredAccuracy, self.distanceFilter];
;
}

- (CLLocationDistance)distanceFilter {
    if (!_distanceFilter) _distanceFilter = kCLDistanceFilterNone;
    return _distanceFilter;
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    _distanceFilter = distanceFilter;
    locationManager.distanceFilter = distanceFilter;
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]].detailTextLabel.text = [NSString stringWithFormat:@"%gm, %gm",self.desiredAccuracy, self.distanceFilter];
}

- (void)clearLocations {
    for (Location *location in locationsArray) {
        [managedObjectContext deleteObject:location];
    }
    NSError *error;
	if (![managedObjectContext save:&error]) {
        NSLog(@"managedObjectContext save:&error %@", error.localizedDescription);
	}
    locationsArray = [self fetchLocationData];
}

- (void)restartLocationManager {
    [self stopTrackingLocation];
    [self startTrackingLocation];
}

- (void)startTrackingLocation {
//    NSLog(@"startTrackingLocation");
    locationsArray = [self fetchLocationData];
    [[self locationManager] startUpdatingLocation];
    self.locationManagerRunning = YES;
}

- (void)stopTrackingLocation {
//    NSLog(@"stopTrackingLocation");
    [[self locationManager] stopUpdatingLocation];
    locationManager.delegate = nil;
    locationManager = nil;
    self.locationManagerRunning = NO;
}

- (CLLocationManager *)locationManager {
    if (!locationManager) {
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.distanceFilter = self.distanceFilter;
        locationManager.desiredAccuracy = self.desiredAccuracy;        
    }
    return locationManager;
}

- (NSMutableArray *)fetchLocationData {

    NSFetchRequest *request = [[NSFetchRequest alloc] init];
//    NSLog(@"self.managedObjectContext %@",managedObjectContext);
    NSEntityDescription *enity = [NSEntityDescription entityForName:ENTITY_NAME inManagedObjectContext:managedObjectContext];
	[request setEntity:enity];
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:SORT_DESCRIPTOR ascending:SORT_ASCEND];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
	[request setSortDescriptors:sortDescriptors];
	
	NSError *error;
	NSMutableArray *mutableFetchResults = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
	if (mutableFetchResults == nil) {
        NSLog(@"executeFetchRequest error %@", error.localizedDescription);
	}
    
    return mutableFetchResults;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {

    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0) [self addLocation];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//     Return the number of rows in the section.
        if (section == 0) {
            return 1;
        } else {
            return [self.locationsArray count];
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
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%gm, %gm",self.desiredAccuracy, self.distanceFilter];
    } else {
        Location *location = (Location *)[self.locationsArray objectAtIndex:indexPath.row];
        //	NSLog(@"location %@",location);
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@",location.timestamp];
        
        NSString *string = [NSString stringWithFormat:@"%@, %@",location.latitude,location.longitude];
        cell.detailTextLabel.text = string;
    }
    
    return cell;
}


@end
