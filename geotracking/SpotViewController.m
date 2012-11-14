//
//  SpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "SpotViewController.h"
#import "SpotPropertiesViewController.h"
#import "Spot.h"
#import "SpotProperty.h"
#import "Track.h"

@interface SpotViewController ()
@property (nonatomic, strong) NSString *typeOfProperty;
@property (weak, nonatomic) IBOutlet UILabel *spotInfo;
@property (weak, nonatomic) IBOutlet UITextField *spotLabel;


@end

@implementation SpotViewController


- (IBAction)editInterests:(id)sender {
    self.typeOfProperty = @"Interest";
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (IBAction)editNetworks:(id)sender {
    self.typeOfProperty = @"Network";
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (void)showSpotInfo {
    CLLocationDegrees longitude = self.userLocation.location.coordinate.longitude;
    CLLocationDegrees latitude = self.userLocation.location.coordinate.latitude;
    self.spotInfo.text = [NSString stringWithFormat:@"lon/lat %.2f/%.2f", longitude, latitude];
}

- (void)showSpotLabel {
    self.spotLabel.font = [UIFont boldSystemFontOfSize:20];
    self.spotLabel.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.spotLabel.returnKeyType = UIReturnKeyDone;
    self.spotLabel.tag = 1;
//    self.spotLabel.delegate = self;
    self.spotLabel.placeholder = @"Spot label";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[SpotPropertiesViewController class]]) {
        SpotPropertiesViewController *spotPropertiesVC = segue.destinationViewController;        
        if ([segue.identifier isEqualToString:@"showProperties"]) {
            spotPropertiesVC.caller = self;
            spotPropertiesVC.tracker = self.tracker;
            spotPropertiesVC.typeOfProperty = self.typeOfProperty;
        }
    }
    
}


#pragma mark - view lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [self showSpotInfo];
    [self showSpotLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSpotInfo:nil];
    [self setSpotLabel:nil];
    [super viewDidUnload];
}

@end
