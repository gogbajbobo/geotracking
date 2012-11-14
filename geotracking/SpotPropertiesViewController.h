//
//  SpotPropertiesViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"

@interface SpotPropertiesViewController : UITableViewController
@property (nonatomic) id caller;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) NSString *typeOfProperty;

@end
