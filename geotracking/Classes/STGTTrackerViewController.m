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
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;

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
        UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CLEAR DATABASE", @"CLEAR DATABASE") message:NSLocalizedString(@"CHOOSE OBJECTS TO DELETE", @"CHOOSE OBJECTS TO DELETE") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"CANCEL") otherButtonTitles:NSLocalizedString(@"ONLY TRACKS", @"ONLY TRACKS"), NSLocalizedString(@"ALL DATA", @"ALL DATA"), nil];
    
        [clearAlert setTag:1];
        [clearAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag ==2) {
        if (buttonIndex == 0) {
            [self.tracker stopTrackingLocation];
            [self startButton].title = NSLocalizedString(@"START", @"START");
        }
    } else if (alertView.tag == 1) {
//        NSLog(@"buttonIndex %d", buttonIndex);
        if (buttonIndex == 1) {
            [self.tracker clearLocations];
        } else if (buttonIndex == 2) {
            if ([self.tracker.settings.localAccessToSettings boolValue]) {
                if (!self.tracker.locationManagerRunning) {
                    [self.tracker clearAllData];
                } else {
                    UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", @"WARNING") message:NSLocalizedString(@"STOP TRACKING FOR CLEAR", @"STOP TRACKING FOR CLEAR") delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @"OK"), nil];
                    [clearAlert show];
                }
            } else {
                UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", @"WARNING") message:NSLocalizedString(@"CANT DELETE ALL DATA", @"CANT DELETE ALL DATA") delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @"OK"), nil];
                [clearAlert show];                
            }
        }
    }
}

- (IBAction)trackerSwitchPressed:(UIBarButtonItem *)sender {
    if (self.tracker.locationManagerRunning) {
        UIAlertView *stopAlert = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"STOP TRACKING", @"STOP TRACKING") message: NSLocalizedString(@"STOP?", @"STOP?") delegate: self cancelButtonTitle: NSLocalizedString(@"YES", @"YES")  otherButtonTitles:NSLocalizedString(@"NO", @"NO"),nil];
        [stopAlert setTag:2];
        [stopAlert show];
    } else {
        [self.tracker startTrackingLocation];
        sender.title = NSLocalizedString(@"STOP", @"STOP");
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
            self.navigationItem.rightBarButtonItem = nil;
            self.syncButton.enabled = YES;
//            NSLog(@"self.syncButton.enabled %d", self.syncButton.enabled);
        }
    }
}


- (void)trackerReady:(NSNotification *)notification {
    self.startButton.enabled = ![[[(STGTTrackingLocationController *)notification.object settings] valueForKey:@"trackerAutoStart"] boolValue];
    self.syncButton.enabled = ![[STGTDataSyncController sharedSyncer] syncing];
    self.settingsButton.enabled = YES;
}

- (void)trackerBusy:(NSNotification *)notification {
    self.startButton.enabled = NO;
    self.settingsButton.enabled = NO;
    self.syncButton.enabled = NO;
}

- (void)setStartButtonLabel:(NSNotification *)notification {
    if (self.tracker.locationManagerRunning) {
        [self startButton].title = NSLocalizedString(@"STOP", @"STOP");
    } else {
        [self startButton].title = NSLocalizedString(@"START", @"START");
    }
}

- (void)startButtonAccess:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[STGTTrackingLocationController class]]) {
        self.startButton.enabled = ![[[(STGTTrackingLocationController *)notification.object settings] valueForKey:@"trackerAutoStart"] boolValue];
    }
}


- (void)viewDidLoad
{
    self.startButton.enabled = NO;
    self.tableView.dataSource = self.tracker;
    self.tableView.delegate = self.tracker;
    
    self.startButton.title = NSLocalizedString(@"START", @"START");
    self.settingsButton.title = NSLocalizedString(@"SETTINGS", @"SETTINGS");
    self.syncButton.title = NSLocalizedString(@"SYNC", @"SYNC");
    self.title = NSLocalizedString(@"TRACKER", @"TRACKER");
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncStatusChanged:) name:@"STGTDataSyncing" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackerReady:) name:@"STGTTrackerReady" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackerBusy:) name:@"STGTTrackerBusy" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStartButtonLabel:) name:@"STGTTrackerStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStartButtonLabel:) name:@"STGTTrackerStop" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startButtonAccess:) name:@"STGTTrackerAutoStartChanged" object:nil];
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [self setStartButton:nil];
    [self setSummary:nil];
    [self setCurrentValues:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTDataSyncing" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerReady" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerBusy" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerStart" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerStop" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"STGTTrackerAutoStartChanged" object:nil];
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
