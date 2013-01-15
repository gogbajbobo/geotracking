//
//  SpotPropertiesViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"
#import "STGTSpotViewController.h"
#import "Spot.h"

@interface STGTSpotPropertiesViewController : UITableViewController
@property (nonatomic) STGTSpotViewController *caller;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) NSString *typeOfProperty;
@property (nonatomic, strong) Spot *spot;
@property (nonatomic, strong) Spot *filterSpot;

@end
