//
//  OptionsViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "OptionsViewController.h"

@interface OptionsViewController () <UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *desiredAccuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceFilterLabel;

@end

@implementation OptionsViewController
@synthesize desiredAccuracyLabel = _desiredAccuracyLabel;
@synthesize distanceFilterLabel = _distanceFilterLabel;
@synthesize tracker = _tracker;

- (IBAction)closeView:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismissViewControllerAnimated");
    }];
}

- (void)updateLabels {
    self.desiredAccuracyLabel.text = [NSString stringWithFormat:@"%f", self.tracker.desiredAccuracy];
    self.distanceFilterLabel.text = [NSString stringWithFormat:@"%f", self.tracker.distanceFilter];
}

- (IBAction)mostBest:(id)sender {
    self.tracker.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self updateLabels];
}
- (IBAction)best:(id)sender {
    self.tracker.desiredAccuracy = kCLLocationAccuracyBest;
    [self updateLabels];
}
- (IBAction)tenMeters:(id)sender {
    self.tracker.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    [self updateLabels];
}
- (IBAction)hundredMeters:(id)sender {
    self.tracker.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    [self updateLabels];
}
- (IBAction)kilometer:(id)sender {
    self.tracker.desiredAccuracy = kCLLocationAccuracyKilometer;
    [self updateLabels];
}
- (IBAction)threeKilometers:(id)sender {
    self.tracker.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    [self updateLabels];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self updateLabels];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [self setDesiredAccuracyLabel:nil];
    [self setDistanceFilterLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
