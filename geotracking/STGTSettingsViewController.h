//
//  SettingsViewController.h
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STGTTrackingLocationController.h"

@interface STGTSettingsViewController : UIViewController
@property (nonatomic, strong) STGTTrackingLocationController *tracker;

@end
