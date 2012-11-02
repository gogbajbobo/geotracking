//
//  SpotViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"

@interface SpotViewController : UIViewController
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) MKUserLocation *userLocation;

@end
