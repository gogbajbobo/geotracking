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
#import "STGTSession.h"
#import "STGTSessionManager.h"

#import "STGTAuthBasic.h"

@interface STGTTrackerViewController () <UIAlertViewDelegate>

//@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) STGTSession *session;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *summary;
@property (weak, nonatomic) IBOutlet UILabel *currentValues;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *syncButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *settingsButton;
@property (weak, nonatomic) IBOutlet UIView *trackerActivityView;

@end

@implementation STGTTrackerViewController
@synthesize startButton = _startButton;
//@synthesize tracker = _tracker;
@synthesize tableView = _tableView;
@synthesize summary = _summary;
@synthesize currentValues = _currentValues;

//- (STGTTrackingLocationController *)tracker
//{
//    if(!_tracker) {
//        _tracker = [STGTTrackingLocationController sharedTracker];
//        _tracker.tableView = self.tableView;
//        _tracker.summary = self.summary;
//        _tracker.currentValues = self.currentValues;
//    }
//    return _tracker;
//}

//- (void)newSessionStart:(NSNotification *)notification {
//    NSLog(@"newSessionStart");
//    self.session = (STGTSession *)notification.object;
//    [self viewInit];
//    [self.session.tracker updateInfoLabels];
//    [self.session.tracker.tableView reloadData];
//}

- (IBAction)syncButtonPressed:(id)sender {
    [self.session.syncer fireTimer];
}

- (IBAction)showOptions:(id)sender {
    [self performSegueWithIdentifier:@"showSettings" sender:self];
}

- (IBAction)clearData:(id)sender {
    UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"CLEAR DATABASE", @"") message:NSLocalizedString(@"OBJECT TO DELETE", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"") otherButtonTitles:NSLocalizedString(@"ONLY TRACKS", @""), NSLocalizedString(@"ALL DATA", @""), nil];
    clearAlert.tag = 1;
    [clearAlert show];
//    [self changeSessionTest];
}

- (void)changeSessionTest {
//    NSLog(@"changeSessionTest");
    dispatch_queue_t queue = dispatch_queue_create("queue", NULL);
    dispatch_async(queue, ^{
        [NSThread sleepForTimeInterval:1];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[STGTSessionManager sharedManager] startSessionForUID:@"2" AuthDelegate:[STGTAuthBasic sharedOAuth]];
            dispatch_async(queue, ^{
                [NSThread sleepForTimeInterval:1];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[STGTSessionManager sharedManager] setCurrentSessionUID:nil];
                    dispatch_async(queue, ^{
                        [NSThread sleepForTimeInterval:1];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[STGTSessionManager sharedManager] setCurrentSessionUID:@"1"];
                        });
                    });
                });
            });
        });
    });
//    dispatch_release(queue);
}

- (IBAction)trackerSwitchPressed:(UIBarButtonItem *)sender {
    if (self.session.tracker.locationManagerRunning) {
        UIAlertView *stopAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"STOP TRACKING", @"") message:@"?" delegate: self cancelButtonTitle:NSLocalizedString(@"NO", @"") otherButtonTitles:NSLocalizedString(@"YES", @""), nil];
        stopAlert.tag = 2;
        [stopAlert show];
    } else {
        [self.session.tracker startTrackingLocation];
        sender.title = NSLocalizedString(@"STOP", @"");
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [self.session.tracker clearLocations];
        } else if (buttonIndex == 2) {
            if ([self.session.tracker.settings.localAccessToSettings boolValue]) {
                if (!self.session.tracker.locationManagerRunning) {
                    [self.session.tracker clearAllData];
                } else {
                    UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", @"") message:NSLocalizedString(@"STOP TRACKING FOR CLEAR", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                    [clearAlert show];
                }
            } else {
                UIAlertView *clearAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"WARNING", @"") message:NSLocalizedString(@"CANT DELETE ALL DATA", @"") delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", @""), nil];
                [clearAlert show];
            }
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            [self.session.tracker stopTrackingLocation];
            [self startButton].title = NSLocalizedString(@"START", @"");
        }
    }
}

- (void)syncStatusChanged:(NSNotification *)notification {
//    NSLog(@"STGTDataSyncing");
    if ([notification.object isKindOfClass:[STGTDataSyncController class]]) {
        if ([(STGTDataSyncController *)notification.object syncing]) {
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
            self.syncButton.enabled = NO;
        } else {
            self.navigationItem.rightBarButtonItem = nil;
            self.syncButton.enabled = YES;
        }
    }
}


- (void)trackerReady:(NSNotification *)notification {
    self.startButton.enabled = ![[[(STGTTrackingLocationController *)notification.object settings] valueForKey:@"trackerAutoStart"] boolValue];
    self.syncButton.enabled = ![self.session.syncer syncing];
    self.settingsButton.enabled = YES;
}

- (void)trackerBusy:(NSNotification *)notification {
    self.startButton.enabled = NO;
    self.settingsButton.enabled = NO;
    self.syncButton.enabled = NO;
}

- (void)setStartButtonLabel:(NSNotification *)notification {
    if (self.session.tracker.locationManagerRunning) {
        [self startButton].title = NSLocalizedString(@"STOP", @"");
        [self startAnimationOfTrackerActivityIndicator];
    } else {
        [self startButton].title = NSLocalizedString(@"START", @"");
        [self stopAnimationOfTrackerActivityIndicator];
    }
}

- (void)startButtonAccess:(NSNotification *)notification {
    if ([notification.object isKindOfClass:[STGTTrackingLocationController class]]) {
        self.startButton.enabled = ![[[(STGTTrackingLocationController *)notification.object settings] valueForKey:@"trackerAutoStart"] boolValue];
    }
}

- (void)startAnimationOfTrackerActivityIndicator {
//    NSLog(@"startAnimationOfTrackerActivityIndicator");
    [UIView animateWithDuration:1.0 delay:0.0 options:(UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat) animations:^{
        self.trackerActivityView.alpha = 1.0;
    } completion:^(BOOL finished) {
//        NSLog(@"finished");
        [self stopAnimationOfTrackerActivityIndicator];
    }];
}

- (void)stopAnimationOfTrackerActivityIndicator {
//    NSLog(@"stopAnimationOfTrackerActivityIndicator");
    [UIView animateWithDuration:1.0 delay:0.0 options:(UIViewAnimationOptionBeginFromCurrentState) animations:^{
        self.trackerActivityView.alpha = 0.0;
    } completion:^(BOOL finished) {
//        NSLog(@"finished");
    }];
}

- (void)viewInit {
    
//    NSLog(@"viewInit");
    self.session.tracker.tableView = self.tableView;
    self.session.tracker.summary = self.summary;
    self.session.tracker.currentValues = self.currentValues;
    
    self.tableView.dataSource = self.session.tracker;
    self.tableView.delegate = self.session.tracker;
    self.startButton.enabled = ![[[self.session.tracker settings] valueForKey:@"trackerAutoStart"] boolValue];
    self.syncButton.enabled = ![self.session.syncer syncing];
    self.settingsButton.enabled = YES;
    self.deleteButton.enabled = YES;
    [self.session.tracker updateInfoLabels];
    [self.tableView reloadData];

}

- (void)viewDeinit {
    self.tableView.dataSource = nil;
    self.tableView.delegate = nil;
    self.summary.text = NSLocalizedString(@"NO ACTIVE SESSION", @"");
    self.currentValues.text = nil;
    self.startButton.enabled = NO;
    self.settingsButton.enabled = NO;
    self.deleteButton.enabled = NO;
    self.syncButton.enabled = NO;
    [self.tableView reloadData];
}

- (void)currentSessionChange:(NSNotification *)notification {
    [self.navigationController popToRootViewControllerAnimated:YES];
    self.session = nil;
    [self viewDeinit];
    self.session = (STGTSession *)notification.object;
    if (self.session) {
        [self viewInit];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
//    NSLog(@"self.trackerActivityView.alpha1 %f", self.trackerActivityView.alpha);
    if (self.session.tracker.locationManagerRunning) {
        [self startAnimationOfTrackerActivityIndicator];
//        NSLog(@"self.trackerActivityView.alpha2 %f", self.trackerActivityView.alpha);
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.startButton.enabled = NO;

    if (self.session) {
        [self viewInit];
    } else {
        [self viewDeinit];
    }
    
    self.startButton.title = NSLocalizedString(@"START", @"");
    self.settingsButton.title = NSLocalizedString(@"SETTINGS", @"");
    self.syncButton.title = NSLocalizedString(@"SYNC", @"");
    self.title = NSLocalizedString(@"TRACKER", @"");
    self.trackerActivityView.alpha = 0.0;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(syncStatusChanged:) name:@"STGTDataSyncing" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackerReady:) name:@"STGTTrackerReady" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackerBusy:) name:@"STGTTrackerBusy" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStartButtonLabel:) name:@"STGTTrackerStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setStartButtonLabel:) name:@"STGTTrackerStop" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startButtonAccess:) name:@"STGTTrackerAutoStartChanged" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSessionChange:) name:@"NewSessionStart" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSessionChange:) name:@"CurrentSessionChange" object:nil];

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
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"NewSessionStart" object:nil];
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"showSettings"]) {
        [segue.destinationViewController setTracker:self.session.tracker];
    }
    if ([segue.identifier isEqualToString:@"showMap"]) {
        if ([segue.destinationViewController isKindOfClass:[STGTMapViewController class]]) {
            STGTMapViewController *mapVC = segue.destinationViewController;
            mapVC.tracker = self.session.tracker;
//            NSLog(@"segue showMap");
        }
    }
}



@end
