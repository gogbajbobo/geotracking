//
//  TrackerViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackerViewController.h"
#import "TrackingLocationController.h"
#import "Location.h"

@interface TrackerViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@end

@implementation TrackerViewController
@synthesize startButton = _startButton;
@synthesize tracker = _tracker;
@synthesize tableView = _tableView;

- (TrackingLocationController *)tracker
{
    if(!_tracker) {
        _tracker = [[TrackingLocationController alloc] init];
        _tracker.tableView = self.tableView;
        _tracker.caller = self;
    }
    return _tracker;
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

- (void)viewWillAppear:(BOOL)animated {
    self.tableView.dataSource = self.tracker;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setStartButton:nil];
    [super viewDidUnload];
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
        if ([segue.destinationViewController isKindOfClass:[MapViewController class]]) {
            MapViewController *mapVC = segue.destinationViewController;
            mapVC.tracker = self.tracker;
        }
    }
}



@end
