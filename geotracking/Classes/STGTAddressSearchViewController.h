//
//  AddressSearchViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 12/15/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STGTTrackingLocationController.h"
#import "STGTMapViewController.h"

@interface STGTAddressSearchViewController : UITableViewController
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) STGTMapViewController *mapVC;

@end
