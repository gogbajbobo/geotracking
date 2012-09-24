//
//  TrackingLocationController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackingLocationController.h"
#import "AppDelegate.h"
#import "Location.h"
#import "MapAnnotation.h"
#import "TrackerViewController.h"
#import <objc/runtime.h>

#define ENTITY_NAME @"Location"
#define SORT_DESCRIPTOR @"timestamp"
#define SORT_ASCEND NO
#define DB_FILE @"geoTracker.sqlite"
#define REQUIRED_ACCURACY 15.0

@interface TrackingLocationController() <NSFetchedResultsControllerDelegate,NSURLConnectionDataDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationDistance overallDistance;
@property (nonatomic) CLLocationSpeed averageSpeed;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation TrackingLocationController

@synthesize distanceFilter = _distanceFilter;
@synthesize desiredAccuracy = _desiredAccuracy;
@synthesize locationManager = _locationManager;
@synthesize locationsDatabase = _locationsDatabase;
@synthesize locationsArray = _locationsArray;
@synthesize tableView = _tableView;
@synthesize mapView = _mapView;
@synthesize locationManagerRunning = _locationManagerRunning;
@synthesize overallDistance = _overallDistance;
@synthesize averageSpeed = _averageSpeed;
@synthesize caller = _caller;
@synthesize sendAnnotationsToMap = _sendAnnotationsToMap;
@synthesize summary = _summary;
@synthesize currentValues = _currentValues;
@synthesize currentAccuracy = _currentAccuracy;
@synthesize resultsController = _resultsController;


- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SORT_DESCRIPTOR ascending:SORT_ASCEND selector:@selector(compare:)]];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:@"Locations"];
        _resultsController.delegate = self;

        [self startConnection];
    }
    return _resultsController;
}

- (NSMutableArray *)locationsArray {
    _locationsArray = [self.resultsController.fetchedObjects mutableCopy];
    return _locationsArray;
}

- (UIManagedDocument *)locationsDatabase {
    
    if (!_locationsDatabase) {
        
        UIBarButtonItem *startButton;
        TrackerViewController *caller;
        if ([self.caller isKindOfClass:[TrackerViewController class]]) {
            caller = self.caller;
        }
        startButton = caller.startButton;
        caller.startButton.enabled = NO;
        
        NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
        url = [url URLByAppendingPathComponent:DB_FILE];
        self.locationsDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        [self.locationsDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[self.locationsDatabase.fileURL path]]) {
            [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"UIDocumentSaveForCreating success");
            }];
        } else if (self.locationsDatabase.documentState == UIDocumentStateClosed) {
            [self.locationsDatabase openWithCompletionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"openWithCompletionHandler");
                NSError *error;
                if (![_resultsController performFetch:&error]) {
                    NSLog(@"performFetch error %@", error.localizedDescription);
                } else {
                    NSLog(@"[self.resultsController.fetchedObjects count] %d", [self.resultsController.fetchedObjects count]);
                    [self.tableView reloadData];
                    [self updateInfoLabels];
                }

            }];
        } else if (self.locationsDatabase.documentState == UIDocumentStateNormal) {
            caller.startButton.enabled = YES;
        }
    }
    return _locationsDatabase;
    
}

- (void)addLocation:(CLLocation *)currentLocation {

    Location *location = (Location *)[NSEntityDescription insertNewObjectForEntityForName:ENTITY_NAME inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    [location setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [location setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [location setHorizontalAccuracy:[NSNumber numberWithDouble:currentLocation.horizontalAccuracy]];
    [location setSpeed:[NSNumber numberWithDouble:currentLocation.speed]];
    [location setCourse:[NSNumber numberWithDouble:currentLocation.course]];
    [location setTimestamp:[currentLocation timestamp]];
    
    NSLog(@"currentLocation %@",currentLocation);
//    NSLog(@"horizontalAccuracy %f",currentLocation.horizontalAccuracy);
//    NSLog(@"distanceFilter %f",locationManager.distanceFilter);
//    NSLog(@"desiredAccuracy %f",locationManager.desiredAccuracy);
    
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"UIDocumentSaveForOverwriting success");
    }];

//    if (self.resultsController.fetchedObjects.count > 1) {
//        CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:[[[self.resultsController.fetchedObjects objectAtIndex:1] latitude] doubleValue] longitude:[[[self.resultsController.fetchedObjects objectAtIndex:1] longitude] doubleValue]];
//        self.overallDistance = self.overallDistance + [currentLocation distanceFromLocation:oldLocation];
//    }
//    CLLocationSpeed speed = (currentLocation.speed < 0) ? 0.0 : currentLocation.speed;
//    self.averageSpeed = (self.averageSpeed * (self.resultsController.fetchedObjects.count - 1) + speed) / self.resultsController.fetchedObjects.count;
//
//    [self updateInfoLabels];
    
    if (self.sendAnnotationsToMap) {
        [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];
    }

}

- (void)recalculateAverageSpeed {
    if (self.resultsController.fetchedObjects.count > 0) {
        self.averageSpeed = 0.0;
        CLLocationSpeed integralSpeed = 0.0;
        for (Location *location in self.resultsController.fetchedObjects) {
            double speed = (location.speed < 0) ? 0.0 : [location.speed doubleValue];
            integralSpeed = integralSpeed + speed;
        }
        self.averageSpeed = integralSpeed / self.resultsController.fetchedObjects.count;
    } else {
        self.averageSpeed = 0.0;
    }
}

- (void)recalculateOverallDistance {
    if (self.resultsController.fetchedObjects.count > 0) {
        self.overallDistance = 0.0;
        Location *temp = [self.resultsController.fetchedObjects objectAtIndex:0];
        CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:[temp.latitude doubleValue] longitude:[temp.longitude doubleValue]];     
        for (Location *temp in self.resultsController.fetchedObjects) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[temp.latitude doubleValue] longitude:[temp.longitude doubleValue]];
            self.overallDistance = self.overallDistance + [location distanceFromLocation:oldLocation];
            oldLocation = location;
        }
    } else {
        self.overallDistance = 0.0;
    }
}

- (void)updateInfoLabels {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:2];
    self.summary.text = [NSString stringWithFormat:@"%@m, %@m/s",[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.overallDistance]],[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.averageSpeed]]];
    self.currentValues.text = [NSString stringWithFormat:@"Accuracy %gm, Distance %gm, CurrAcc %gm",self.desiredAccuracy, self.distanceFilter, self.currentAccuracy];
}

- (CLLocationAccuracy)desiredAccuracy {
    if (!_desiredAccuracy) {
        NSNumber *desiredAccuracy = [[NSUserDefaults standardUserDefaults] objectForKey:@"desiredAccuracy"];
        if (desiredAccuracy == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
                _desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
            [settings setObject:[NSNumber numberWithDouble:_desiredAccuracy] forKey:@"desiredAccuracy"];
            [settings synchronize];
        } else {
            _desiredAccuracy = [desiredAccuracy doubleValue];
        }
    }
    return _desiredAccuracy;
}

- (void)setDesiredAccuracy:(CLLocationAccuracy)desiredAccuracy {
    _desiredAccuracy = desiredAccuracy;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:desiredAccuracy] forKey:@"desiredAccuracy"];
    [settings synchronize];
    self.locationManager.desiredAccuracy = desiredAccuracy;
    [self updateInfoLabels];
}

- (CLLocationDistance)distanceFilter {
    if (!_distanceFilter) {
        NSNumber *distanceFilter = [[NSUserDefaults standardUserDefaults] objectForKey:@"distanceFilter"];
        if (distanceFilter == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            _distanceFilter = 50.0;
            [settings setObject:[NSNumber numberWithDouble:_distanceFilter] forKey:@"distanceFilter"];
            [settings synchronize];
        } else {
            _distanceFilter = [distanceFilter doubleValue];
        }
    }
    return _distanceFilter;
}

- (void)setDistanceFilter:(CLLocationDistance)distanceFilter {
    _distanceFilter = distanceFilter;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:distanceFilter] forKey:@"distanceFilter"];
    [settings synchronize];
    self.locationManager.distanceFilter = distanceFilter;
    [self updateInfoLabels];
}

- (void)clearLocations {
    for (Location *location in self.resultsController.fetchedObjects) {
        [self.locationsDatabase.managedObjectContext deleteObject:location];
    }
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"UIDocumentSaveForOverwriting success");
    }];
}

- (void)startTrackingLocation {
//    NSLog(@"startTrackingLocation");
    [[self locationManager] startUpdatingLocation];
    self.locationManagerRunning = YES;
}

- (void)stopTrackingLocation {
//    NSLog(@"stopTrackingLocation");
    [[self locationManager] stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager = nil;
    self.locationManagerRunning = NO;
}

- (CLLocationManager *)locationManager {
    if (!_locationManager) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = self.distanceFilter;
        _locationManager.desiredAccuracy = self.desiredAccuracy;        
    }
    return _locationManager;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    self.currentAccuracy = newLocation.horizontalAccuracy;
    [self updateInfoLabels];
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < REQUIRED_ACCURACY) {
        [self addLocation:newLocation];
    }
}

- (void)startConnection {
    NSURL *requestURL = [NSURL URLWithString:@"https://system.unact.ru/asa/?_host=oldcat&_svc=iexp/gt"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
//    NSString *requestString = @"<?xml version=\"1.0\" encoding=\"utf-8\"?><post><set-of name=\"animal\"><fields><field name=\"id\"/><field name=\"name\"/></fields><csv><d xid=\"d5d01b28-9e66-4194-bdf2-1b2925f12419\">1,Cat</d><d xid=\"edfbb824-0527-4ee8-a74f-5f66c545f55b\">2,Dog,23</d></csv></set-of></post>";
//    NSData *requestData = [requestString dataUsingEncoding:NSUTF8StringEncoding];
    NSData *requestData = [self requestData];
    [request setHTTPBody:requestData];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    if (!connection) NSLog(@"connection error");
}

- (NSData *)requestData {
    
    xmlTextWriterPtr xmlTextWriter;
    xmlBufferPtr xmlBuffer;

    xmlBuffer = xmlBufferCreate();
    xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
    
    xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
    
        xmlTextWriterStartElement(xmlTextWriter, BAD_CAST "post");
        
            xmlTextWriterStartElement(xmlTextWriter, BAD_CAST "set-of");
            xmlTextWriterWriteAttribute(xmlTextWriter, BAD_CAST "name", (xmlChar *)[ENTITY_NAME UTF8String]);

                xmlTextWriterStartElement(xmlTextWriter, BAD_CAST "fields");
                    unsigned int propertyCount = 0;
                    objc_property_t * properties = class_copyPropertyList([Location class], &propertyCount);
                    for (unsigned int i = 0; i < propertyCount; ++i) {
                        xmlTextWriterStartElement(xmlTextWriter, BAD_CAST "field");
                        xmlTextWriterWriteAttribute(xmlTextWriter, BAD_CAST "name", (xmlChar *)property_getName(properties[i]));
                        xmlTextWriterEndElement(xmlTextWriter); //field
                    }
                xmlTextWriterEndElement(xmlTextWriter); //fields

                xmlTextWriterStartElement(xmlTextWriter, BAD_CAST "cvs");
                xmlTextWriterEndElement(xmlTextWriter); //cvs
    
            xmlTextWriterEndElement(xmlTextWriter); //set-of
    
        xmlTextWriterEndElement(xmlTextWriter); //post
        
    xmlTextWriterEndDocument(xmlTextWriter);
    xmlFreeTextWriter(xmlTextWriter);
        
    NSData *requestData = [NSData dataWithBytes:(xmlBuffer->content) length:(xmlBuffer->use)];
    xmlBufferFree(xmlBuffer);
    
    NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
    
    return requestData;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
//    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
//    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSLog(@"section %d [sectionInfo numberOfObjects] %d", section, [sectionInfo numberOfObjects]);
    return [sectionInfo numberOfObjects];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Locations";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Location";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Location *location = (Location *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    cell.textLabel.text = [dateFormatter stringFromDate:location.timestamp];
    
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:3];
            
    NSString *string = [NSString stringWithFormat:@"lat%@ lon%@ %@m %@m/s %@deg", [numberFormatter stringFromNumber:location.latitude], [numberFormatter stringFromNumber:location.longitude], [numberFormatter stringFromNumber:location.horizontalAccuracy], [numberFormatter stringFromNumber:location.speed], [numberFormatter stringFromNumber:location.course]];
    cell.detailTextLabel.text = string;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSManagedObject *location = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
		[self.locationsDatabase.managedObjectContext deleteObject:location];
        [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"UIDocumentSaveForOverwriting success");
        }];
//        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
//        [self recalculateOverallDistance];
//        [self recalculateAverageSpeed];
//        [self updateInfoLabels];
        
    }   
}

#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    [self.tableView reloadData];
//    NSLog(@"controllerDidChangeContent");
//    NSLog(@"[self.resultsController.fetchedObjects count] %d", [self.resultsController.fetchedObjects count]);
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    if (type == NSFetchedResultsChangeDelete) {
                
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [self recalculateOverallDistance];
        [self recalculateAverageSpeed];
        [self updateInfoLabels];

    } else if (type == NSFetchedResultsChangeInsert) {
                
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
        if (self.resultsController.fetchedObjects.count > 1) {
            CLLocation *currentLocation = [[CLLocation alloc] initWithLatitude:[[[self.resultsController.fetchedObjects objectAtIndex:0] latitude] doubleValue] longitude:[[[self.resultsController.fetchedObjects objectAtIndex:0] longitude] doubleValue]];
            CLLocation *oldLocation = [[CLLocation alloc] initWithLatitude:[[[self.resultsController.fetchedObjects objectAtIndex:1] latitude] doubleValue] longitude:[[[self.resultsController.fetchedObjects objectAtIndex:1] longitude] doubleValue]];
            self.overallDistance = self.overallDistance + [currentLocation distanceFromLocation:oldLocation];
        }
        Location *location = (Location *)[self.resultsController.fetchedObjects objectAtIndex:0];
        CLLocationSpeed speed = [location.speed doubleValue];
        speed = (speed < 0) ? 0.0 : speed;
        self.averageSpeed = (self.averageSpeed * (self.resultsController.fetchedObjects.count - 1) + speed) / self.resultsController.fetchedObjects.count;
        
        [self updateInfoLabels];

    }
}

@end