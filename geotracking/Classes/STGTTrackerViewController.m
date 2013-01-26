//
//  TrackerViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTTrackerViewController.h"
#import "STGTTrackingLocationController.h"
#import "STGTLocation.h"
#import "STGTDataSyncController.h"

@interface STGTTrackerViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *summary;
@property (weak, nonatomic) IBOutlet UILabel *currentValues;

@end

@implementation STGTTrackerViewController
@synthesize startButton = _startButton;
@synthesize tracker = _tracker;
@synthesize tableView = _tableView;
@synthesize summary = _summary;
@synthesize currentValues = _currentValues;

- (STGTTrackingLocationController *)tracker
{
    if(!_tracker) {
        _tracker = [STGTTrackingLocationController sharedTracker];
        _tracker.tableView = self.tableView;
        _tracker.summary = self.summary;
        _tracker.currentValues = self.currentValues;
        _tracker.caller = self;
//        NSLog(@"_tracker %@", _tracker);
    }
    return _tracker;
}

- (IBAction)syncButtonPressed:(id)sender {
    [[STGTDataSyncController sharedSyncer] fireTimer];
}

- (IBAction)showOptions:(id)sender {
    [self performSegueWithIdentifier:@"showSettings" sender:self];
}

- (IBAction)clearData:(id)sender {
    if (!self.tracker.locationManagerRunning) {
        UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:@"Clear locations" message:@"Delete?" delegate:self cancelButtonTitle:@"YES"  otherButtonTitles:@"NO",nil];
        [clearAlert show];
    } else {
        UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"You should stop locations tracking for clear procedure" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [clearAlert show];
    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Stop tracking"]) {
        if (buttonIndex == 0) {
            [self.tracker stopTrackingLocation];
            [self startButton].title = @"Start";
        }
    } else if ([alertView.title isEqualToString:@"Clear locations"]) {
        if (buttonIndex == 0) {
            [self.tracker clearLocations];
        }        
    }
}

- (IBAction)trackerSwitchPressed:(UIBarButtonItem *)sender {
    if (self.tracker.locationManagerRunning) {
        UIAlertView *stopAlert = [[UIAlertView alloc] initWithTitle: @"Stop tracking" message: @"Stop?" delegate: self cancelButtonTitle: @"YES"  otherButtonTitles:@"NO",nil];
        [stopAlert show];
    } else {
        [self.tracker startTrackingLocation];
        sender.title = @"Stop";
    }
}

- (void)viewWillAppear:(BOOL)animated {
}

- (void)viewDidLoad
{
    self.tableView.dataSource = self.tracker;
    self.tableView.delegate = self.tracker;
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setStartButton:nil];
    [self setSummary:nil];
    [self setCurrentValues:nil];
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        [segue.destinationViewController setTracker:self.tracker];
    }
    if ([segue.identifier isEqualToString:@"showMap"]) {
        if ([segue.destinationViewController isKindOfClass:[STGTMapViewController class]]) {
            STGTMapViewController *mapVC = segue.destinationViewController;
            mapVC.tracker = self.tracker;
//            NSLog(@"segue showMap");
        }
    }
}



@end
