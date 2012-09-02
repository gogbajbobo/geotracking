//
//  OptionsViewController.h
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"

@interface SettingsViewController : UIViewController
@property (nonatomic, strong) TrackingLocationController *tracker;

@end
