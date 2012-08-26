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

- (TrackingLocationController *)tracker
{
    if(!_tracker) _tracker = [[TrackingLocationController alloc] init];
    [_tracker setManagedObjectContext:self.coreData.managedObjectContext];
    _tracker.tableView = self.tableView;
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

- (IBAction)startTracker:(id)sender {
//    [self.tracker setManagedObjectContext:self.coreData.managedObjectContext];
    NSLog(@"startTracker");
    [self.tracker startTrackingLocation];
}

- (IBAction)stopTracker:(id)sender {
    [self.tracker stopTrackingLocation];
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

- (void)viewWillAppear:(BOOL)animated {
//    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
//    [self.tracker stopTrackingLocation];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showOptions"]) {
        [segue.destinationViewController setTracker:self.tracker];
    }
}



@end
