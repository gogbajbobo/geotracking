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

#define ENTITY_NAME @"Location"
#define SORT_DESCRIPTOR @"timestamp"
#define SORT_ASCEND NO

@interface TrackingLocationController() {
    
    CLLocationManager *locationManager;
    
}

@property (nonatomic) CLLocationManager *locationManager;

@end

@implementation TrackingLocationController

@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize managedObjectContext, locationsArray, locationManager;

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
    
	NSError *error;
	if (![managedObjectContext save:&error]) {
        NSLog(@"managedObjectContext save:&error %@", error.localizedDescription);
	}

    [locationsArray insertObject:location atIndex:0];
}

- (CLLocationAccuracy)desiredAccuracy {
    if (!_desiredAccuracy) _desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    return _desiredAccuracy;
}

- (CLLocationDistance)distanceFilter {
    if (!_distanceFilter) _distanceFilter = kCLDistanceFilterNone;
    return _distanceFilter;
}

- (void)startTrackingLocation {
//    NSLog(@"startTrackingLocation");
    locationsArray = [self fetchLocationData];
    [[self locationManager] startUpdatingLocation];
}

- (void)stopTrackingLocation {
//    NSLog(@"stopTrackingLocation");
    [[self locationManager] stopUpdatingLocation];
    locationManager.delegate = nil;
    locationManager = nil;
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
    NSLog(@"self.managedObjectContext %@",managedObjectContext);
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


@end
