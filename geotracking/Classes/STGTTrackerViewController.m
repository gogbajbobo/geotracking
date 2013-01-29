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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *syncButton;

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
        UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:@"Clear database" message:@"Choose objects to delete:" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Only tracks", @"All data", nil];
        [clearAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Stop tracking"]) {
        if (buttonIndex == 0) {
            [self.tracker stopTrackingLocation];
            [self startButton].title = @"Start";
        }
    } else if ([alertView.title isEqualToString:@"Clear database"]) {
//        NSLog(@"buttonIndex %d", buttonIndex);
        if (buttonIndex == 1) {
            [self.tracker clearLocations];
        } else if (buttonIndex == 2) {
            if (!self.tracker.locationManagerRunning) {
                [self.tracker clearAllData];
            } else {
                UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"You should stop locations tracking for clear procedure" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
                [clearAlert show];
            }    
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

- (void)syncStatusChanged:(NSNotification *) notification {
//    NSLog(@"STGTDataSyncing");
    if ([notification.object isKindOfClass:[STGTDataSyncController class]]) {
        if ([(STGTDataSyncController *)notification.object syncing]) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
            self.syncButton.enabled = NO;
//            NSLog(@"spinner.isAnimating %d", spinner.isAnimating);
//            NSLog(@"self.syncButton.enabled %d", self.syncButton.enabled);
        } else {
//            UILabel *numberOfUnsynced = [[UILabel alloc] init];
//            numberOfUnsynced.text = [[(STGTDataSyncController *)notification.object numberOfUnsynced] stringValue];
//            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:numberOfUnsynced];
            self.navigationItem.rightBarButtonItem = nil;
            self.syncButton.enabled = YES;
//            NSLog(@"self.syncButton.enabled %d", self.syncButton.enabled);
        }
    }
}


- (void)startButtonEnable:(NSNotification *)notification {
    self.startButton.enabled = YES;
}

- (void)startButtonDisable:(NSNotification *)notification {
    self.startButton.enabled = NO;
}

- (void)viewDidLoad
{
    [self startButtonDisable:nil];
    self.tableView.dataSource = self.tracker;
    self.tableView.delegate = self.tracker;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncStatusChanged:) name:@"STGTDataSyncing" object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncerUpdated:) name:@"STGTDataSyncUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startButtonEnable:) name:@"STGTTrackerReady" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startButtonDisable:) name:@"STGTTrackerBusy" object:nil];
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setStartButton:nil];
    [self setSummary:nil];
    [self setCurrentValues:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTDataSyncing" object:nil];
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTDataSyncUpdated" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerReady" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerBusy" object:nil];
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
