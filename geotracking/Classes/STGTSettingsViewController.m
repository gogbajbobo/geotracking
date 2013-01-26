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
    self.tracker.settings.requiredAccuracy = [NSNumber numberWithDouble:self.requiredAccuracySlider.value];
    [self updateLabels];
}

- (void)requiredAccuracySliderSetup {
    self.requiredAccuracySlider.maximumValue = 100.0;
    self.requiredAccuracySlider.minimumValue = 5.0;
    [self.requiredAccuracySlider setValue:[self.tracker.settings.requiredAccuracy doubleValue] animated:YES];
}


- (IBAction)trackDetectionTimeIntervalChangeValue:(id)sender {
    [self.trackDetectionTimeIntervalSlider setValue:floor(self.trackDetectionTimeIntervalSlider.value/30)*30];
    self.tracker.settings.trackDetectionTime = [NSNumber numberWithDouble:self.trackDetectionTimeIntervalSlider.value];
    [self updateLabels];
}

- (void)trackDetectionTimeIntervalSliderSetup {
    self.trackDetectionTimeIntervalSlider.maximumValue = 600.0;
    self.trackDetectionTimeIntervalSlider.minimumValue = 0.0;
    [self.trackDetectionTimeIntervalSlider setValue:[self.tracker.settings.trackDetectionTime doubleValue] animated:YES];
}

- (IBAction)distanceFilterChangeValue:(id)sender {
    [self.distanceFilterSlider setValue:floor(self.distanceFilterSlider.value/10)*10];
    self.tracker.settings.distanceFilter = [NSNumber numberWithDouble:self.distanceFilterSlider.value];
    [self updateLabels];
}

- (void)distanceFilterSliderSetup {
//    self.distanceFilterSlider.continuous = NO;
    self.distanceFilterSlider.maximumValue = 200.0;
    self.distanceFilterSlider.minimumValue = -1.0;
    [self.distanceFilterSlider setValue:[self.tracker.settings.distanceFilter doubleValue] animated:YES];
}


- (void)updateLabels {
    self.desiredAccuracyLabel.text = [NSString stringWithFormat:@"%@", self.tracker.settings.desiredAccuracy];
    self.requiredAccuracyLabel.text = [NSString stringWithFormat:@"%@", self.tracker.settings.requiredAccuracy];
    self.distanceFilterLabel.text = [NSString stringWithFormat:@"%@", self.tracker.settings.distanceFilter];
    self.trackDetectionTimeIntervalLabel.text = [NSString stringWithFormat:@"%@", self.tracker.settings.trackDetectionTime];
}

- (IBAction)mostBest:(id)sender {
    self.tracker.settings.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation];
    [self updateLabels];
}
- (IBAction)best:(id)sender {
    self.tracker.settings.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyBest];
    [self updateLabels];
}
- (IBAction)tenMeters:(id)sender {
    self.tracker.settings.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters];
    [self updateLabels];
}
- (IBAction)hundredMeters:(id)sender {
    self.tracker.settings.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters];
    [self updateLabels];
}
- (IBAction)kilometer:(id)sender {
    self.tracker.settings.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyKilometer];
    [self updateLabels];
}
- (IBAction)threeKilometers:(id)sender {
    self.tracker.settings.desiredAccuracy = [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers];
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
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"settingViewWillDisappear UIDocumentSaveForOverwriting success");
    }];
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
