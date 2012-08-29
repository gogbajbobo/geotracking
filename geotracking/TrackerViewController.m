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
@property (nonatomic, strong) UIManagedDocument *locationDatabase;


@end

@implementation TrackerViewController
@synthesize tracker = _tracker;
@synthesize tableView = _tableView;
@synthesize mapViewController = _mapViewController;
@synthesize locationDatabase = _locationDatabase;

- (TrackingLocationController *)tracker
{
    if(!_tracker) {
        _tracker = [[TrackingLocationController alloc] init];
        [_tracker setLocationDatabase:self.locationDatabase];
        _tracker.tableView = self.tableView;
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

- (void)initLocationDatabase {
    
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"geoTracker.sqlite"];
    self.locationDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
    [self.locationDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self.locationDatabase.fileURL path]]) {
        [self.locationDatabase saveToURL:self.locationDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {NSLog(@"UIDocumentSaveForCreating success");}];
    } else if (self.locationDatabase.documentState == UIDocumentStateClosed) {
        [self.locationDatabase openWithCompletionHandler:^(BOOL success) {NSLog(@"openWithCompletionHandler");}];
    } else if (self.locationDatabase.documentState == UIDocumentStateNormal) {
    }
//    NSLog(@"TVC self.locationDatabase %@", self.locationDatabase);
}

- (void)viewWillAppear:(BOOL)animated {
    [self initLocationDatabase];
    self.tableView.dataSource = self.tracker;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
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
        self.mapViewController = segue.destinationViewController;
        self.tracker.mapView = self.mapViewController.mapView;
    }
}



@end
