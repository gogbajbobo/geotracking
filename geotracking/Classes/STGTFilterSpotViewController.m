//
//  FilterSpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 12/5/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTFilterSpotViewController.h"
#import "STGTSpotPropertiesViewController.h"
#import "STGTAddressSearchViewController.h"
#import "STGTSpotViewController.h"

@interface STGTFilterSpotViewController ()

@end

@implementation STGTFilterSpotViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    for (int i = 0; i < self.viewControllers.count; i++) {
        if ([[self.viewControllers objectAtIndex:i] isKindOfClass:[STGTSpotPropertiesViewController class]]) {
            STGTSpotPropertiesViewController *spvc = (STGTSpotPropertiesViewController *)[self.viewControllers objectAtIndex:i];
            spvc.tracker = self.tracker;
            spvc.spot = self.filterSpot;
            UITabBarItem *tabBarItem = [self.tabBar.items objectAtIndex:i];
            spvc.typeOfProperty = [tabBarItem.title substringToIndex:(tabBarItem.title.length - 1)];
//            NSLog(@"spvc.typeOfProperty %@", spvc.typeOfProperty);
        } else if ([[self.viewControllers objectAtIndex:i] isKindOfClass:[STGTAddressSearchViewController class]]) {
            STGTAddressSearchViewController *asvc = (STGTAddressSearchViewController *)[self.viewControllers objectAtIndex:i];
            asvc.tracker = self.tracker;
            if ([self.caller isKindOfClass:[STGTMapViewController class]]) {
                asvc.mapVC = (STGTMapViewController *)self.caller;
            }
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
