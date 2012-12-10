//
//  FilterSpotViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 12/5/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"
#import "Spot.h"


@interface FilterSpotViewController : UITabBarController
@property (nonatomic) id caller;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) Spot *filterSpot;

@end
