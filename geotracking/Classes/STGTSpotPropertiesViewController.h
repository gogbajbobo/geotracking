//
//  SpotPropertiesViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STGTTrackingLocationController.h"
#import "STGTSpotViewController.h"
#import "STGTSpot.h"

@interface STGTSpotPropertiesViewController : UITableViewController
@property (nonatomic) STGTSpotViewController *caller;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) NSString *typeOfProperty;
@property (nonatomic, strong) STGTSpot *spot;
@property (nonatomic, strong) STGTSpot *filterSpot;

@end
