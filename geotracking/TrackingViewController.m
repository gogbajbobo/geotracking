//
//  TrackingViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackingViewController.h"
#import "TrackingLocationController.h"

@interface TrackingViewController ()

@property (weak, nonatomic) IBOutlet UILabel *location;
@property (nonatomic, strong) TrackingLocationController *tracker;

@end

@implementation TrackingViewController

@synthesize location = _location;
@synthesize tracker = _tracker;

- (TrackingLocationController *)tracker
{
    if(!_tracker) _tracker = [[TrackingLocationController alloc] init];
    return _tracker;
}

- (IBAction)startTracking:(id)sender {
    self.location.text = [NSString stringWithFormat:@"%@",[self.tracker getCurrentLocation]];
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
