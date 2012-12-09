//
//  SpotPropertiesViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"
#import "SpotViewController.h"
#import "Spot.h"

@interface SpotPropertiesViewController : UITableViewController
@property (nonatomic) SpotViewController *caller;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) NSString *typeOfProperty;
@property (nonatomic, strong) Spot *spot;

@end
