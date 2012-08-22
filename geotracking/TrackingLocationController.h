//
//  TrackingLocationController.h
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface TrackingLocationController : NSObject <CLLocationManagerDelegate>

@property (nonatomic) CLLocationDistance distanceFilter;
@property (nonatomic) CLLocationAccuracy desiredAccuracy;

- (void)startTrackingLocation;
- (void)stopTrackingLocation;
- (CLLocation *)getCurrentLocation;

@end
