//
//  FilterSpotViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 12/5/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STGTTrackingLocationController.h"
#import "STGTSpot.h"


@interface STGTFilterSpotViewController : UITabBarController
@property (nonatomic) id caller;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) STGTSpot *filterSpot;

@end
