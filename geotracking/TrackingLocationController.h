//
//  TrackingLocationController.h
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface TrackingLocationController : NSObject <CLLocationManagerDelegate> {
    
    NSMutableArray *locationsArray;
	NSManagedObjectContext *managedObjectContext;
    
}

@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;

- (void)startTrackingLocation;
- (void)stopTrackingLocation;
//- (CLLocation *)getCurrentLocation;


@property (nonatomic) NSMutableArray *locationsArray;
@property (nonatomic) NSManagedObjectContext *managedObjectContext;	    

- (void)addLocation;


@end
