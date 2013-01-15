//
//  AddressSearchViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 12/15/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"
#import "STGTMapViewController.h"

@interface STGTAddressSearchViewController : UITableViewController
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) STGTMapViewController *mapVC;

@end
