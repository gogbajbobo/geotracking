//
//  MapViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "MapViewController.h"
#import "MapAnnotation.h"

@interface MapViewController ()
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) MKCoordinateSpan span;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize center = _center;
@synthesize span = _span;
@synthesize annotations = _annotations;
@synthesize tracker = _tracker;


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
            [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];
        }
        
        NSLog(@"annotations.count %d",self.mapView.annotations.count);
        
        //    //    NSLog(@"maxLon %f minLon %f maxLat %f minLat %f", maxLon, minLon, maxLat, minLat);
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
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
