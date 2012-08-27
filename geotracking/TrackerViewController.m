//
//  TrackerViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackerViewController.h"
#import "TrackingLocationController.h"
#import "CoreDataController.h"
#import "Location.h"

@interface TrackerViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) CoreDataController *coreData;
@property (nonatomic, strong) IBOutlet UITableView *tableView;


@end

@implementation TrackerViewController
@synthesize tracker = _tracker;
@synthesize coreData = _coreData;
@synthesize tableView = _tableView;
@synthesize mapViewController = _mapViewController;

- (TrackingLocationController *)tracker
{
    if(!_tracker) {
        _tracker = [[TrackingLocationController alloc] init];
        [_tracker setManagedObjectContext:self.coreData.managedObjectContext];
        _tracker.tableView = self.tableView;
    }
    return _tracker;
}

- (CoreDataController *)coreData {
    if(!_coreData) _coreData = [[CoreDataController alloc] init];
    return _coreData;
}

- (IBAction)showOptions:(id)sender {
    [self performSegueWithIdentifier:@"showOptions" sender:self];
}

- (IBAction)clearData:(id)sender {
    
    UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle: @"Clear Locations" message: @"Delete?" delegate: self cancelButtonTitle: @"YES"  otherButtonTitles:@"NO",nil];
    
    [clearAlert show];
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex==0)
    {
        [self.tracker clearLocations];
        [self.tableView reloadData];
    }
}

- (IBAction)trackerSwitchPressed:(UIBarButtonItem *)sender {
    if (self.tracker.locationManagerRunning) {
        [self.tracker stopTrackingLocation];
        sender.title = @"Start";
    } else {
        [self.tracker startTrackingLocation];
        sender.title = @"Stop";
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.dataSource = self.tracker;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showOptions"]) {
        [segue.destinationViewController setTracker:self.tracker];
    }
    if ([segue.identifier isEqualToString:@"showMap"]) {
        self.mapViewController = segue.destinationViewController;
        self.tracker.mapView = self.mapViewController.mapView;
    }
}



@end
