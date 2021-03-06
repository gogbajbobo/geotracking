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
            if (tabBarItem.tag == 1) {
                spvc.typeOfProperty = @"Interest";
            } else if (tabBarItem.tag == 2) {
                spvc.typeOfProperty = @"Network";
            }
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
    self.title = NSLocalizedString(@"FILTER SPOT", @"");
    UITabBarItem *tabBarItem1 = [self.tabBar.items objectAtIndex:0];
    tabBarItem1.title = NSLocalizedString(@"INTERESTS 2", @"");
    tabBarItem1.tag = 1;
    UITabBarItem *tabBarItem2 = [self.tabBar.items objectAtIndex:1];
    tabBarItem2.title = NSLocalizedString(@"NETWORKS 2", @"");
    tabBarItem2.tag = 2;
    UITabBarItem *tabBarItem3 = [self.tabBar.items objectAtIndex:2];
    tabBarItem3.title = NSLocalizedString(@"ADDRESS SEARCH", @"");
    tabBarItem3.tag = 3;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
    }
}

@end
