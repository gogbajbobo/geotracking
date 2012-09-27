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
@property (nonatomic, strong) NSMutableData *responseData;

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
@synthesize responseData = _responseData;


- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:SORT_DESCRIPTOR ascending:SORT_ASCEND selector:@selector(compare:)]];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:@"Locations"];
        _resultsController.delegate = self;
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
        _locationsDatabase = [[UIManagedDocument alloc] initWithFileURL:url];
        [_locationsDatabase persistentStoreTypeForFileType:NSSQLiteStoreType];
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[_locationsDatabase.fileURL path]]) {
            [_locationsDatabase saveToURL:_locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"UIDocumentSaveForCreating success");
                [self performFetch];
            }];
        } else if (_locationsDatabase.documentState == UIDocumentStateClosed) {
            [_locationsDatabase openWithCompletionHandler:^(BOOL success) {
                caller.startButton.enabled = YES;
                NSLog(@"openWithCompletionHandler success");
                [self performFetch];
            }];
        } else if (_locationsDatabase.documentState == UIDocumentStateNormal) {
            caller.startButton.enabled = YES;
        }
    }
    return _locationsDatabase;
    
}

- (void)performFetch {
    NSError *error;
    if (![_resultsController performFetch:&error]) {
        NSLog(@"performFetch error %@", error.localizedDescription);
    } else {
        [self.tableView reloadData];
        [self recalculateOverallDistance];
        [self recalculateAverageSpeed];
        [self updateInfoLabels];
        [self startConnection];
    }
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
//    NSLog(@"latitude %f",[location.latitude doubleValue]);
//    NSLog(@"longitude %f",[location.longitude doubleValue]);
    
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"addLocation UIDocumentSaveForOverwriting success");
    }];

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
    [numberFormatter setMaximumFractionDigits:0];
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
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:DB_FILE];
    [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
    self.locationsDatabase = nil;
    self.resultsController = nil;
    [self.tableView reloadData];
}


- (void)startTrackingLocation {
    [[self locationManager] startUpdatingLocation];
    self.locationManagerRunning = YES;
}

- (void)stopTrackingLocation {
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
    NSData *requestData = [self requestData];
    [request setHTTPBody:requestData];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
//    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//    if (!connection) NSLog(@"connection error");
}

- (NSString *)newid
{
    NSString *uuidString = nil;
    CFUUIDRef uuid = CFUUIDCreate(nil);
    if (uuid) {
        uuidString = (__bridge_transfer NSString *)CFUUIDCreateString(nil, uuid);
        CFRelease(uuid);
    }
    
    return uuidString;
}

- (NSData *)requestData {
        
    xmlTextWriterPtr xmlTextWriter;
    xmlBufferPtr xmlBuffer;

    xmlBuffer = xmlBufferCreate();
    xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
    
    xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
    
        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "post");
        
            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[ENTITY_NAME UTF8String]);

                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "fields");
                    NSArray *entityAttributes = [self.resultsController.fetchRequest.entity.attributesByName allKeys];
                    for (NSString *attributeName in entityAttributes) {
                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "field");
                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[attributeName UTF8String]);
                        xmlTextWriterEndElement(xmlTextWriter); //field
                    }
                xmlTextWriterEndElement(xmlTextWriter); //fields

                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
                    for (Location *location in self.resultsController.fetchedObjects) {
                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
                            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[[self newid] UTF8String]);
                            NSMutableString *locationValues = [NSMutableString string];
                            for (NSString *attributeName in entityAttributes) {
                                [locationValues appendFormat:@"%@,",[location valueForKey:attributeName]];
                            }
                            if (locationValues.length > 0) [locationValues deleteCharactersInRange:NSMakeRange([locationValues length] - 1, 1)];
                            xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[locationValues UTF8String]);
                        xmlTextWriterEndElement(xmlTextWriter); //d
                    }
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

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.resultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
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
            
    NSMutableString *detailTextString = [NSMutableString stringWithFormat:@"%@/%@ %@m %@m/s %@deg", [numberFormatter stringFromNumber:location.latitude], [numberFormatter stringFromNumber:location.longitude], [numberFormatter stringFromNumber:location.horizontalAccuracy], [numberFormatter stringFromNumber:location.speed], [numberFormatter stringFromNumber:location.course]];
    if (![location.synced boolValue]) {
        detailTextString = [NSMutableString stringWithFormat:@"! %@",detailTextString];
    }
    cell.detailTextLabel.text = detailTextString;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSManagedObject *location = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
		[self.locationsDatabase.managedObjectContext deleteObject:location];
        [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"UIDocumentSaveForOverwriting success");
        }];
    }   
}

#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    NSLog(@"controllerDidChangeContent");
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