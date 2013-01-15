//
//  SettingsViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSettingsViewController.h"

@interface STGTSettingsViewController () <UIPickerViewDelegate>
@property (weak, nonatomic) IBOutlet UILabel *desiredAccuracyLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceFilterLabel;
@property (weak, nonatomic) IBOutlet UISlider *distanceFilterSlider;
@property (weak, nonatomic) IBOutlet UISlider *trackDetectionTimeIntervalSlider;
@property (weak, nonatomic) IBOutlet UILabel *trackDetectionTimeIntervalLabel;
@property (weak, nonatomic) IBOutlet UISlider *requiredAccuracySlider;
@property (weak, nonatomic) IBOutlet UILabel *requiredAccuracyLabel;

@end

@implementation STGTSettingsViewController
@synthesize desiredAccuracyLabel = _desiredAccuracyLabel;
@synthesize distanceFilterLabel = _distanceFilterLabel;
@synthesize distanceFilterSlider = _distanceFilterSlider;
@synthesize tracker = _tracker;

- (IBAction)requiredAccuracyChangeValue:(id)sender {
    [self.requiredAccuracySlider setValue:floor(self.requiredAccuracySlider.value/10)*10];
    self.tracker.requiredAccuracy = self.requiredAccuracySlider.value;
    [self updateLabels];
}

- (void)requiredAccuracySliderSetup {
    self.requiredAccuracySlider.maximumValue = 500.0;
    self.requiredAccuracySlider.minimumValue = 5.0;
    [self.requiredAccuracySlider setValue:self.tracker.requiredAccuracy animated:YES];
}


- (IBAction)trackDetectionTimeIntervalChangeValue:(id)sender {
    [self.trackDetectionTimeIntervalSlider setValue:floor(self.trackDetectionTimeIntervalSlider.value/30)*30];
    self.tracker.trackDetectionTimeInterval = self.trackDetectionTimeIntervalSlider.value;
    [self updateLabels];
}

- (void)trackDetectionTimeIntervalSliderSetup {
    self.trackDetectionTimeIntervalSlider.maximumValue = 600.0;
    self.trackDetectionTimeIntervalSlider.minimumValue = 0.0;
    [self.trackDetectionTimeIntervalSlider setValue:self.tracker.trackDetectionTimeInterval animated:YES];
}

- (IBAction)distanceFilterChangeValue:(id)sender {
    [self.distanceFilterSlider setValue:floor(self.distanceFilterSlider.value/10)*10];
    self.tracker.distanceFilter = self.distanceFilterSlider.value;
    [self updateLabels];
}

- (void)distanceFilterSliderSetup {
//    self.distanceFilterSlider.continuous = NO;
    self.distanceFilterSlider.maximumValue = 200.0;
    self.distanceFilterSlider.minimumValue = -1.0;
    [self.distanceFilterSlider setValue:self.tracker.distanceFilter animated:YES];    
}


- (void)updateLabels {
    self.desiredAccuracyLabel.text = [NSString stringWithFormat:@"%f", self.tracker.desiredAccuracy];
    self.requiredAccuracyLabel.text = [NSString stringWithFormat:@"%f", self.tracker.requiredAccuracy];
    self.distanceFilterLabel.text = [NSString stringWithFormat:@"%f", self.tracker.distanceFilter];
    self.trackDetectionTimeIntervalLabel.text = [NSString stringWithFormat:@"%f", self.tracker.trackDetectionTimeInterval];
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
    [self distanceFilterSliderSetup];
    [self trackDetectionTimeIntervalSliderSetup];
    [self requiredAccuracySliderSetup];
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
    [self setDistanceFilterSlider:nil];
    [self setTrackDetectionTimeIntervalSlider:nil];
    [self setTrackDetectionTimeIntervalLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
