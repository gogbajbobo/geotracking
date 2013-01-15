//
//  MapViewController.h
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Location.h"
#import "STGTTrackingLocationController.h"
#import "Spot.h"

@interface STGTMapViewController : UIViewController
@property (nonatomic, strong) NSArray *annotations;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (strong, nonatomic) Spot *filteredSpot;

@end
