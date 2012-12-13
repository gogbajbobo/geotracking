//
//  MapViewController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "MapViewController.h"
#import "MapAnnotation.h"
#import "SpotViewController.h"
#import "Spot.h"
#import "FilterSpotViewController.h"

@interface MapViewController () <MKMapViewDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic) CLLocationCoordinate2D center;
@property (nonatomic) CLLocationCoordinate2D newSpotCoordinate;
@property (nonatomic) MKCoordinateSpan span;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mapSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *headingModeSwitch;
@property (weak, nonatomic) IBOutlet UILabel *trackNumberLabel;
@property (weak, nonatomic) IBOutlet UIStepper *trackNumberSelector;
@property (strong, nonatomic) NSFetchedResultsController *resultsController;
@property (strong, nonatomic) Spot *selectedSpot;
@property (strong, nonatomic) Spot *filterSpot;
@property (strong, nonatomic) NSMutableDictionary *annotationsDictionary;

@end

@implementation MapViewController
@synthesize mapView = _mapView;
@synthesize mapSwitch = _mapSwitch;
@synthesize headingModeSwitch = _headingModeSwitch;
@synthesize center = _center;
@synthesize span = _span;
@synthesize annotations = _annotations;
@synthesize tracker = _tracker;


- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Spot"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = [NSPredicate predicateWithFormat:@"SELF.label == %@", @"@filter"];
        NSError *error;
        self.filterSpot = [[self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error] lastObject];
        if (!self.filterSpot) {
            [self createFilterSpot];
        }
        request.predicate = nil;
        request.predicate = [NSPredicate predicateWithFormat:@"ANY SELF.properties IN %@ || SELF.properties.@count == 0", self.filterSpot.properties];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.tracker.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _resultsController.delegate = self;
    }
    
    return _resultsController;
}

- (void)performFetch {
    if (self.resultsController) {
        self.resultsController.delegate = nil;
        self.resultsController = nil;
    }
    NSError *error;
    if (![self.resultsController performFetch:&error]) {
        NSLog(@"performFetch error %@", error.localizedDescription);
    } else {
        if (self.resultsController.fetchedObjects.count > 0) {
//            [self annotationsCreateForSpots:[NSSet setWithArray:self.resultsController.fetchedObjects]];
            [self refreshAnnotations];
        } else {
        }
    }
}

- (void)createFilterSpot {
    Spot *filterSpot = (Spot *)[NSEntityDescription insertNewObjectForEntityForName:@"Spot" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    [filterSpot setXid:[self.tracker newid]];
    filterSpot.timestamp = [NSDate date];
    filterSpot.label = @"@filter";
//    filterSpot.synced = [NSNumber numberWithBool:YES];
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SpotProperty"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    NSError *error;
    NSArray *allProperties = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
    NSLog(@"allProperties %@", allProperties);
    [filterSpot addProperties:[NSSet setWithArray:allProperties]];
    self.filterSpot = filterSpot;
    NSLog(@"filterSpot %@", filterSpot);
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newSpot UIDocumentSaveForOverwriting success");
    }];
}

- (IBAction)filterSpotButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"filterSpots" sender:sender];
}

- (IBAction)addNewSpotButtonPressed:(UIButton *)sender {
    self.newSpotCoordinate = self.mapView.userLocation.coordinate;
    [self performSegueWithIdentifier:@"showSpot" sender:sender];
}

- (void)showSpot:(UIButton *)sender {
    [self performSegueWithIdentifier:@"showSpot" sender:sender];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(UIButton *)sender {
    if ([segue.identifier isEqualToString:@"showSpot"]) {
//        NSLog(@"prepareForSegue showSpot");
        if ([segue.destinationViewController isKindOfClass:[SpotViewController class]]) {
            SpotViewController *spotVC = segue.destinationViewController;
            spotVC.tracker = self.tracker;
            spotVC.filterSpot = self.filterSpot;
            if (sender.buttonType == UIButtonTypeContactAdd) {
//                NSLog(@"UIButtonTypeContactAdd");
                spotVC.coordinate = self.newSpotCoordinate;
                spotVC.newSpotMode = YES;
            } else if (sender.buttonType == UIButtonTypeDetailDisclosure) {
//                NSLog(@"UIButtonTypeDetailDisclosure");
                spotVC.spot = self.selectedSpot;
                spotVC.newSpotMode = NO;
            }
        }
    } else if ([segue.identifier isEqualToString:@"filterSpots"]) {
        if ([segue.destinationViewController isKindOfClass:[FilterSpotViewController class]]) {
            FilterSpotViewController *filterVC = segue.destinationViewController;
            filterVC.tracker = self.tracker;
            filterVC.filterSpot = self.filterSpot;
        }
    }
}

- (IBAction)trackNumberChange:(id)sender {
    self.tracker.selectedTrackNumber = self.tracker.numberOfTracks - self.trackNumberSelector.value;
    self.trackNumberLabel.text = [NSString stringWithFormat:@"%d", (self.tracker.numberOfTracks - self.tracker.selectedTrackNumber)];
    [self redrawPathLine];
    [self updateMapView];
}

- (void)trackNumberSelectorSetup {
    self.trackNumberSelector.wraps = NO;
    self.trackNumberSelector.stepValue = 1.0;
    self.trackNumberSelector.minimumValue = 1.0;
    self.trackNumberSelector.maximumValue = self.tracker.numberOfTracks;
    self.trackNumberSelector.value = self.tracker.numberOfTracks - self.tracker.selectedTrackNumber;
}

- (void)redrawPathLine {
    [self.mapView removeOverlays:[self.mapView overlays]];
    [self.mapView addOverlay:(id<MKOverlay>)self.allPathLine];
    [self.mapView addOverlay:(id<MKOverlay>)self.pathLine];
//    [self.mapView removeAnnotations:self.mapView.annotations];
//    [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:[self.tracker.locationsArray objectAtIndex:0]]];
//    [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:[self.tracker.locationsArray lastObject]]];
}

- (IBAction)headingModeSwitchSwitched:(id)sender {
    if ([sender isKindOfClass:[UISwitch class]]) {
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        UISwitch *headingMode = sender;
        if (headingMode.on) {
            [self.mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
//            self.mapView.showsUserLocation = YES;
        } else {
            [self.mapView setUserTrackingMode:MKUserTrackingModeNone];
//            self.mapView.showsUserLocation = NO;
        }
        [settings setObject:[NSNumber numberWithBool:headingMode.on] forKey:@"headingMode"];
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
    [self mapScaleCenterSet];
    [self.mapView setRegion:MKCoordinateRegionMake(self.center, self.span) animated:YES];
}

- (void)setMapView:(MKMapView *)mapView
{
    _mapView = mapView;
    _mapView.delegate = self;
}

-(void)mapScaleCenterSet {
//    NSLog(@"mapScaleCenterSet");
    NSArray *locationsArray = [self.tracker locationsArrayForTrack:self.tracker.selectedTrackNumber];
    if (locationsArray.count > 0) {
//        NSLog(@"locationsArray.count > 0");
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
        }
        
        CLLocationCoordinate2D center;
        center.longitude = (maxLon + minLon)/2;
        center.latitude = (maxLat + minLat)/2;
        self.center = center;
//        NSLog(@"self.center %f %f", self.center.longitude, self.center.latitude);
        int zoomScale = 4;
        MKCoordinateSpan span;
        span.longitudeDelta = zoomScale * (maxLon - minLon);
        span.latitudeDelta = zoomScale * (maxLat - minLat);
        if (span.longitudeDelta == 0) {
            span.longitudeDelta = 0.01;
        }
        if (span.latitudeDelta == 0) {
            span.latitudeDelta = 0.01;
        }
        self.span = span;
    } else {
        self.center = self.mapView.userLocation.location.coordinate;
        MKCoordinateSpan span;
        span.longitudeDelta = 0.01;
        span.latitudeDelta = 0.01;
        self.span = span;
    }

}

- (void)annotationsCreateForSpots:(NSSet *)spots {
    for (Spot *spot in spots) {
        if (![[spot.label substringToIndex:1] isEqualToString:@"@"]) {
            MapAnnotation *annotation = [MapAnnotation createAnnotationForSpot:spot];
            [self.mapView addAnnotation:annotation];
            [self.annotationsDictionary setObject:annotation forKey:spot.xid];
            //        NSLog(@"spot %@", spot);
            //        NSLog(@"annotation %@", annotation);
        }
    }
}

- (void)annotationsDeleteForSpotXids:(NSSet *)spotXids {
    for (NSString *spotXid in spotXids) {
        MapAnnotation *annotation = [self.annotationsDictionary objectForKey:spotXid];
        [self.annotationsDictionary removeObjectForKey:spotXid];
        [self.mapView removeAnnotation:annotation];
    }
}

- (void)refreshAnnotations {
    NSSet *oldAnnotations = [NSSet setWithArray:[self.annotationsDictionary allKeys]];
    NSMutableSet *newAnnotations = [NSMutableSet set];
    for (Spot *spot in self.resultsController.fetchedObjects) {
        [newAnnotations addObject:spot.xid];
    }
    
//    NSLog(@"oldAnnotations,newAnnotations %@ %@",oldAnnotations,newAnnotations);
    
    NSMutableSet *oldAnnotationsCopy = [oldAnnotations mutableCopy];
    [oldAnnotationsCopy minusSet:newAnnotations];
    [self annotationsDeleteForSpotXids:oldAnnotationsCopy];
    
    [newAnnotations minusSet:oldAnnotations];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.xid IN %@", newAnnotations];
    NSSet *annotationsToAdd = [NSSet setWithArray:[self.resultsController.fetchedObjects filteredArrayUsingPredicate:predicate]];
    [self annotationsCreateForSpots:annotationsToAdd];
}

- (MKPolyline *)pathLine {
    
    NSArray *locationsArray = [self.tracker locationsArrayForTrack:self.tracker.selectedTrackNumber];
//    NSLog(@"locationsArray %@", locationsArray);
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
    MKPolyline *pathLine = [MKPolyline polylineWithCoordinates:annotationsCoordinates count:numberOfLocations];
    pathLine.title = @"currentTrack";
    return pathLine;
}

- (MKPolyline *)allPathLine {
    
    NSArray *locationsArray = self.tracker.allLocationsArray;
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
    MKPolyline *pathLine = [MKPolyline polylineWithCoordinates:annotationsCoordinates count:numberOfLocations];
    pathLine.title = @"allTracks";
    return pathLine;
}

- (void)longTap:(UILongPressGestureRecognizer *)gesture {
//    NSLog(@"UILongPressGestureRecognizer");
    if (gesture.state == UIGestureRecognizerStateBegan) {
//        NSLog(@"UIGestureRecognizerStateBegan");
        CGPoint longTapPoint = [gesture locationInView:self.mapView];
        CLLocationCoordinate2D longTapCoordinate = [self.mapView convertPoint:longTapPoint toCoordinateFromView:self.mapView];
//        NSLog(@"coordinate %f %f", longTapCoordinate.latitude, longTapCoordinate.longitude);
        self.newSpotCoordinate = longTapCoordinate;
        [self.mapView addAnnotation:[MapAnnotation createAnnotationForCoordinate:longTapCoordinate]];
    }
}


#pragma mark - MKMapViewDelegate


- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
    NSArray *locationsArray = [self.tracker locationsArrayForTrack:self.tracker.selectedTrackNumber];
    if (locationsArray.count == 0) {
        [self updateMapView];
    }
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    
    if (annotation == mapView.userLocation){
        return nil;
    } else {
        MKPinAnnotationView *pinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"MapPinAnnotation"];
        if (!pinView) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"MapPinAnnotation"];
            pinView.animatesDrop = YES;
            pinView.pinColor = MKPinAnnotationColorPurple;
            pinView.canShowCallout = YES;
        }
        pinView.annotation = annotation;
        UIButton *detailDisclosureButton;
        if ([[pinView.annotation title] isEqualToString:@"Add new spot…"]) {
            detailDisclosureButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        } else {
            detailDisclosureButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        }
        pinView.rightCalloutAccessoryView = detailDisclosureButton;

        MapAnnotation *mapAnnotation = annotation;
        UIImage *spotImage = [UIImage imageWithData:mapAnnotation.spot.image];
        if (spotImage) {
            CGFloat width = 32 * spotImage.size.width / spotImage.size.height;
            UIImageView *spotImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, width, 32)];
            spotImageView.image = spotImage;
            pinView.leftCalloutAccessoryView = spotImageView;
        }
        return pinView;
    }
}


- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineView *pathView = [[MKPolylineView alloc] initWithPolyline:overlay];
    if (overlay.title == @"currentTrack") {
        pathView.strokeColor = [UIColor blueColor];
        pathView.lineWidth = 4.0;
    } else if (overlay.title == @"allTracks") {
        pathView.strokeColor = [UIColor grayColor];
        pathView.lineWidth = 2.0;
    }
    return pathView;
    
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    if ([view.annotation isKindOfClass:[MapAnnotation class]]) {
        MapAnnotation *mapAnnotation = view.annotation;
        self.selectedSpot = mapAnnotation.spot;
    }
    if ([control isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)control;
        if (button.buttonType == UIButtonTypeContactAdd) {
            [self.mapView removeAnnotation:view.annotation];
        }
        [self showSpot:button];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
//    NSLog(@"didSelectAnnotationView");
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view {
    if ([[view.annotation title] isEqualToString:@"Add new spot…"]) {
        [mapView removeAnnotation:view.annotation];
    }
    self.selectedSpot = nil;
}

#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"controllerDidChangeContent UIDocumentSaveForOverwriting success");
//    }];
//    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
        
//        NSLog(@"NSFetchedResultsChangeDelete");
        
        if ([anObject isKindOfClass:[Spot class]]) {
            Spot *spot = (Spot *)anObject;
            if (![[spot.label substringToIndex:1] isEqualToString:@"@"]) {
                MapAnnotation *annotation = [self.annotationsDictionary objectForKey:spot.xid];
                [self.annotationsDictionary removeObjectForKey:spot.xid];
                [self.mapView removeAnnotation:annotation];
            }
        }

    } else if (type == NSFetchedResultsChangeInsert) {
        
//        NSLog(@"NSFetchedResultsChangeInsert");
        if ([anObject isKindOfClass:[Spot class]]) {
            Spot *spot = (Spot *)anObject;
            if (![[spot.label substringToIndex:1] isEqualToString:@"@"]) {
                MapAnnotation *annotation = [MapAnnotation createAnnotationForSpot:spot];
                [self.annotationsDictionary setObject:annotation forKey:spot.xid];
                [self.mapView addAnnotation:annotation];
                [self.mapView selectAnnotation:annotation animated:NO];
            }
        }
        
    } else if (type == NSFetchedResultsChangeUpdate || type == NSFetchedResultsChangeMove) {
        
//        NSLog(@"NSFetchedResultsChangeUpdate or Move");
        if ([anObject isKindOfClass:[Spot class]]) {
            Spot *spot = (Spot *)anObject;
            if (![[spot.label substringToIndex:1] isEqualToString:@"@"]) {
                MapAnnotation *annotation = [self.annotationsDictionary objectForKey:spot.xid];
                [self.mapView removeAnnotation:annotation];
                annotation = [MapAnnotation createAnnotationForSpot:spot];
                [self.mapView addAnnotation:annotation];
                [self.mapView selectAnnotation:annotation animated:NO];
            }
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

- (void)viewDidLoad
{
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
    
    self.trackNumberLabel.text = [NSString stringWithFormat:@"%d", (self.tracker.numberOfTracks - self.tracker.selectedTrackNumber)];
    [self.mapView addOverlay:(id<MKOverlay>)self.allPathLine];
    [self.mapView addOverlay:(id<MKOverlay>)self.pathLine];
    [self trackNumberSelectorSetup];
    self.mapView.showsUserLocation = YES;
    self.annotationsDictionary = [NSMutableDictionary dictionary];
//    [self performFetch];
    [self updateMapView];

    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTap:)];
    [self.mapView addGestureRecognizer:longTap];

    [super viewDidLoad];


	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    NSLog(@"viewWillAppear");
    [self performFetch];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidUnload
{
    NSLog(@"viewDidUnload");
    self.mapView.delegate = nil;
    [self setMapSwitch:nil];
    [self setHeadingModeSwitch:nil];
    [self setTrackNumberLabel:nil];
    [self setTrackNumberSelector:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
