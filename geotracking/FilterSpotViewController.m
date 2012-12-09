//
//  FilterSpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 12/5/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "FilterSpotViewController.h"
#import "SpotPropertiesViewController.h"
#import "SpotViewController.h"
#import "Spot.h"
#import "SpotProperty.h"

@interface FilterSpotViewController ()

@end

@implementation FilterSpotViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    NSEntityDescription *spotEntity = [NSEntityDescription entityForName:@"Spot" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    Spot *filterSpot = (Spot *)[[NSManagedObject alloc] initWithEntity:spotEntity insertIntoManagedObjectContext:nil];
//    NSEntityDescription *spotPropertyEntity = [NSEntityDescription entityForName:@"SpotProperty" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    [filterSpot addProperties:[self allSpotProperties]];
    filterSpot.label = @"filterSpot";
    NSLog(@"filterSpot %@", filterSpot);
    for (int i = 0; i < self.viewControllers.count; i++) {
        if ([[self.viewControllers objectAtIndex:i] isKindOfClass:[SpotPropertiesViewController class]]) {
            SpotPropertiesViewController *spvc = (SpotPropertiesViewController *)[self.viewControllers objectAtIndex:i];
            spvc.tracker = self.tracker;
            spvc.spot = filterSpot;
            UITabBarItem *tabBarItem = [self.tabBar.items objectAtIndex:i];
            spvc.typeOfProperty = [tabBarItem.title substringToIndex:(tabBarItem.title.length - 1)];
//            NSLog(@"spvc.typeOfProperty %@", spvc.typeOfProperty);
        }
    }
}

- (NSSet *)allSpotProperties {
    NSSet *allSpotProperties;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SpotProperty"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
//    request.predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", self.typeOfProperty];
    NSError *error;
    allSpotProperties = [NSSet setWithArray:[self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error]];
    if (error) {
        NSLog(@"error %@", error.localizedDescription);
    }
    return allSpotProperties;
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
