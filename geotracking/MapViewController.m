//
//  MapViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "MapViewController.h"
#import "MapAnnotation.h"

@interface MapViewController () <MKMapViewDelegate>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) MKCoordinateSpan span;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *headingModeSwitch;

@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize mapSwitch = _mapSwitch;
@synthesize headingModeSwitch = _headingModeSwitch;
@synthesize center = _center;
@synthesize span = _span;
@synthesize annotations = _annotations;
@synthesize tracker = _tracker;
@synthesize showPins = _showPins;


- (IBAction)headingModeSwitchSwitched:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        UISwitch *headingMode = sender;
        if (headingMode.on) {
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
        } else {
            [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
        }
        [settings setObject:[NSNumber numberWithBool:headingMode.on] forKey:@"headingMode"];
        [settings synchronize];
    }
}

- (IBAction)showPinsSwitchSwitched:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        UISwitch *showPins = sender;
        if (showPins.on) {
            [self annotationsCreate];
            self.tracker.sendAnnotationsToMap = self.showPins.on;
        } else {
            [self.mapView removeAnnotations:self.mapView.annotations];
            self.tracker.sendAnnotationsToMap = self.showPins.on;
        }
        [settings setObject:[NSNumber numberWithBool:self.showPins.on] forKey:@"showPins"];
        [settings synchronize];
    }
}


- (IBAction)mapSwitchPressed:(id)sender {
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    UISegmentedControl *mapSwitch;
    if ([sender isKindOfClass:[UISegmentedControl class]]) {
        mapSwitch = sender;
    }
    if (mapSwitch.selectedSegmentIndex == 0) {
        self.mapView.mapType = MKMapTypeStandard;
    } else if (mapSwitch.selectedSegmentIndex == 1) {
        self.mapView.mapType = MKMapTypeSatellite;        
    } else if (mapSwitch.selectedSegmentIndex == 2) {
        self.mapView.mapType = MKMapTypeHybrid;
    }
    [settings setObject:[NSNumber numberWithInteger:self.mapView.mapType] forKey:@"mapType"];
    [settings synchronize];
}


- (void)updateMapView
{
    if (self.mapView.annotations) [self.mapView removeAnnotations:self.mapView.annotations];
    [self annotationsCreate];
    self.mapView.region = MKCoordinateRegionMake(self.center, self.span);
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    self.tracker.mapView = self.mapView;
    [self updateMapView];
}

- (void)annotationsCreate
{
    NSArray *locationsArray = self.tracker.locationsArray;

    if (locationsArray.count > 0) {
        Location *location = (Location *)[locationsArray objectAtIndex:0];
        
        double maxLon = [location.longitude doubleValue];
        double minLon = [location.longitude doubleValue];
        double maxLat = [location.latitude doubleValue];
        double minLat = [location.latitude doubleValue];
        
        for (Location *location in locationsArray) {
            if ([location.longitude doubleValue] > maxLon) maxLon = [location.longitude doubleValue];
            if ([location.longitude doubleValue] < minLon) minLon = [location.longitude doubleValue];
            if ([location.latitude doubleValue] > maxLat) maxLat = [location.latitude doubleValue];
            if ([location.latitude doubleValue] < minLat) minLat = [location.latitude doubleValue];
            //        NSLog(@"maxLon %f minLon %f maxLat %f minLat %f", maxLon, minLon, maxLat, minLat);
            if (self.showPins.on) {
                [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];
            }
        }
        
//        NSLog(@"annotations.count %d",self.mapView.annotations.count);
        
//        NSLog(@"maxLon %f minLon %f maxLat %f minLat %f", maxLon, minLon, maxLat, minLat);
        CLLocationCoordinate2D center;
        center.longitude = (maxLon + minLon)/2;
        center.latitude = (maxLat + minLat)/2;
        self.center = center;
        //    NSLog(@"center %f %f",center.longitude, center.latitude);
        MKCoordinateSpan span;
        span.longitudeDelta = maxLon - minLon;
        span.latitudeDelta = maxLat - minLat;
        self.span = span;
        //    NSLog(@"span %f %f",span.longitudeDelta, span.latitudeDelta);        
    } else {
        self.center = self.mapView.userLocation.location.coordinate;
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MapPinAnnotation"];
    if (annotation == mapView.userLocation){
        return nil;
    } else {
        if (!pinView) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapPinAnnotation"];
            pinView.pinColor = MKPinAnnotationColorPurple;
            pinView.canShowCallout = YES;
//            pinView.animatesDrop = YES;
        }
        pinView.annotation = annotation;
        return pinView;
    }
}

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
//    NSLog(@"viewForOverlay");
    
    MKPolylineView *pathView = [[MKPolylineView alloc] initWithPolyline:overlay];
    pathView.strokeColor = [UIColor blueColor];
    pathView.lineWidth = 5.0;

    return pathView;
}

- (MKPolyline *)pathLine {
    
    NSArray *locationsArray = self.tracker.locationsArray;
    int numberOfLocations = locationsArray.count;
    CLLocationCoordinate2D annotationsCoordinates[numberOfLocations];
    if (numberOfLocations > 0) {
        int i = 0;
        for (Location *location in locationsArray) {
            CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([location.latitude doubleValue], [location.longitude doubleValue]);
            annotationsCoordinates[i] = coordinate;
            i++;
        }
    }
    return [MKPolyline polylineWithCoordinates:annotationsCoordinates count:numberOfLocations];
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
    self.mapView.showsUserLocation = YES;
    self.mapView.delegate = self;
	// Do any additional setup after loading the view.
}


- (void)viewWillAppear:(BOOL)animated {
    
    NSNumber *showPins = [[NSUserDefaults standardUserDefaults] objectForKey:@"showPins"];
    if (!showPins) {
        showPins = [NSNumber numberWithBool:YES];
    }
    [self.showPins setOn:[showPins boolValue] animated:NO];
    if (self.showPins.on) {
        [self annotationsCreate];
    }
    self.tracker.sendAnnotationsToMap = self.showPins.on;

    BOOL headingMode = [[[NSUserDefaults standardUserDefaults] objectForKey:@"headingMode"] boolValue];
    if (!headingMode) {
        headingMode = NO;
        [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
    } else {
        [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
    }
    [self.headingModeSwitch setOn:headingMode animated:NO];


    NSNumber *mapType = [[NSUserDefaults standardUserDefaults] objectForKey:@"mapType"];
    if (!mapType) {
        self.mapView.mapType = MKMapTypeStandard;
    }
    self.mapView.mapType = [mapType integerValue];
    if ([mapType integerValue] == MKMapTypeStandard) {
        self.mapSwitch.selectedSegmentIndex = 0;
    } else if ([mapType integerValue] == MKMapTypeSatellite) {
        self.mapSwitch.selectedSegmentIndex = 1;
    } else if ([mapType integerValue] == MKMapTypeHybrid) {
        self.mapSwitch.selectedSegmentIndex = 2;
    }
    
    [self.mapView addOverlay:(id<MKOverlay>)[self pathLine]];
}

- (void)viewWillDisappear:(BOOL)animated {
    self.mapView.delegate = nil;
}

- (void)viewDidUnload
{
    [self setMapSwitch:nil];
    [self setShowPins:nil];
    [self setHeadingModeSwitch:nil];
    self.mapView.delegate = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
