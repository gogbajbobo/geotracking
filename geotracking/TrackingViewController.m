//
//  TrackingViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackingViewController.h"
#import "TrackingLocationController.h"
#import "CoreDataController.h"


@interface TrackingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *location;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) CoreDataController *coreData;

@end

@implementation TrackingViewController

@synthesize location = _location;
@synthesize tracker = _tracker;
@synthesize coreData = _coreData;

- (TrackingLocationController *)tracker
{
    if(!_tracker) _tracker = [[TrackingLocationController alloc] init];
    return _tracker;
}

- (CoreDataController *)coreData {
    if(!_coreData) _coreData = [[CoreDataController alloc] init];
    return _coreData;
}

- (IBAction)startTracking:(id)sender {
    [self.tracker setManagedObjectContext:self.coreData.managedObjectContext];
    [self.tracker startTrackingLocation];
    self.location.text = [NSString stringWithFormat:@"%@",[[self.tracker locationsArray] objectAtIndex:0]];
}

- (IBAction)stopTracking:(id)sender {
    [self.tracker stopTrackingLocation];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setLocation:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
