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
#import "Route.h"
#import "MapAnnotation.h"
#import "TrackerViewController.h"

#define DB_FILE @"geoTracker.sqlite"
#define REQUIRED_ACCURACY 15.0

@interface TrackingLocationController() <NSFetchedResultsControllerDelegate, NSURLConnectionDataDelegate, NSXMLParserDelegate, CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) CLLocationDistance overallDistance;
@property (nonatomic) CLLocationSpeed averageSpeed;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) BOOL syncing;
@property (nonatomic, strong) Route *currentRoute;
@property (nonatomic, strong) CLLocation *lastLocation;

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
@synthesize syncing = _syncing;
@synthesize currentRoute = _currentRoute;
@synthesize lastLocation = _lastLocation;
@synthesize allLocationsArray = _allLocationsArray;


- (void)setSyncing:(BOOL)syncing {
    if (_syncing != syncing) {
        _syncing = syncing;
        [self updateInfoLabels];
    }
}

- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Route"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"startTime" ascending:NO selector:@selector(compare:)]];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _resultsController.delegate = self;
    }
    return _resultsController;
}

- (NSArray *)allLocationsArray {
    NSMutableSet *allLocations = [NSMutableSet set];
    for (Route *route in self.resultsController.fetchedObjects) {
        [allLocations unionSet:route.locations];
    }
    return [allLocations sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO selector:@selector(compare:)]]];
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
                [self startNewRoute];
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
        self.currentRoute = [self.resultsController.fetchedObjects objectAtIndex:0];
        [self.tableView reloadData];
        [self updateInfoLabels];
    }
}

- (void)startNewRoute {
    Route *route = (Route *)[NSEntityDescription insertNewObjectForEntityForName:@"Route" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    [route setXid:[self newid]];
    [route setStartTime:[NSDate date]];
    [route setOverallDistance:[NSNumber numberWithDouble:0.0]];
    self.currentRoute = route;
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newRoute UIDocumentSaveForOverwriting success");
    }];
}

- (void)addLocation:(CLLocation *)currentLocation {

    if ([currentLocation.timestamp timeIntervalSinceDate:self.lastLocation.timestamp] > 120) {
        [self startNewRoute];
    } else {
        NSNumber *overallDistance = [NSNumber numberWithDouble:[self.currentRoute.overallDistance doubleValue] + [currentLocation distanceFromLocation:self.lastLocation]];
        self.currentRoute.overallDistance = (overallDistance < 0) ? 0 : overallDistance;
    }
    
    Location *location = (Location *)[NSEntityDescription insertNewObjectForEntityForName:@"Location" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
    CLLocationCoordinate2D coordinate = [currentLocation coordinate];
    [location setLatitude:[NSNumber numberWithDouble:coordinate.latitude]];
    [location setLongitude:[NSNumber numberWithDouble:coordinate.longitude]];
    [location setHorizontalAccuracy:[NSNumber numberWithDouble:currentLocation.horizontalAccuracy]];
    [location setSpeed:[NSNumber numberWithDouble:currentLocation.speed]];
    [location setCourse:[NSNumber numberWithDouble:currentLocation.course]];
    [location setTimestamp:[currentLocation timestamp]];
    [location setXid:[self newid]];
    
    if (self.currentRoute.locations.count == 0) {
        self.currentRoute.startTime = location.timestamp;
    }
    self.currentRoute.finishTime = location.timestamp;
    [self.currentRoute addLocationsObject:location];
    
//    NSLog(@"currentLocation %@",currentLocation);


    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"addLocation UIDocumentSaveForOverwriting success");
        self.lastLocation = currentLocation;
    }];
    [self updateInfoLabels];

//    if (self.sendAnnotationsToMap) {
//        [self.mapView addAnnotation:[MapAnnotation createAnnotationFor:location]];
//    }

}

- (CLLocation *)lastLocation {
    if (!_lastLocation) {
        _lastLocation = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] objectForKey:@"lastLocation"]];
    }
    return _lastLocation;
}

- (void)setLastLocation:(CLLocation *)lastLocation {
    _lastLocation = lastLocation;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSData *lastLocationData = [NSKeyedArchiver archivedDataWithRootObject:lastLocation];
    [settings setObject:lastLocationData forKey:@"lastLocation"];
    [settings synchronize];
}


- (CLLocationDistance)overallDistance {

    CLLocationDistance overallDistance = 0.0;
    for (Route *route in self.resultsController.fetchedObjects) {
        overallDistance = overallDistance + [route.overallDistance doubleValue];
    }
    return overallDistance;

}

- (CLLocationSpeed)averageSpeed {
    
    NSTimeInterval routeOverallTime = 0;
    for (Route *route in self.resultsController.fetchedObjects) {
        routeOverallTime = routeOverallTime + [route.finishTime timeIntervalSinceDate:route.startTime];
    }
    CLLocationSpeed averageSpeed = 0.0;
    if (routeOverallTime != 0) {
        averageSpeed = 3.6 * self.overallDistance / routeOverallTime;
    }
    return averageSpeed;
    
}

- (void)updateInfoLabels {
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
    [numberFormatter setMaximumFractionDigits:1];
    NSString *syncStatus = @"";
    if (self.syncing) {
        syncStatus = @" SYNC";
    }
    self.summary.text = [NSString stringWithFormat:@"%@m, %@m/s%@",[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.overallDistance]],[numberFormatter stringFromNumber:[NSNumber numberWithDouble:self.averageSpeed]], syncStatus];
    if (self.currentAccuracy > 0) {
        self.currentValues.text = [NSString stringWithFormat:@"Accuracy %gm, Distance %gm, CurrAcc %gm",self.desiredAccuracy, self.distanceFilter, self.currentAccuracy];
    } else {
        self.currentValues.text = [NSString stringWithFormat:@"Accuracy %gm, Distance %gm",self.desiredAccuracy, self.distanceFilter];
    }
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
//    [self updateInfoLabels];
    if (locationAge < 5.0 && newLocation.horizontalAccuracy > 0 && newLocation.horizontalAccuracy < REQUIRED_ACCURACY) {
        [self addLocation:newLocation];
    }
}

- (void)startConnection {
    NSURL *requestURL = [NSURL URLWithString:@"https://system.unact.ru/asa/?_host=oldcat&_svc=iexp/gt"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
    NSData *requestData = [self requestData];
    if (requestData) {
        [request setHTTPBody:requestData];
        [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (!connection) NSLog(@"connection error");
    }
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
    
    NSPredicate *notSynced = [NSPredicate predicateWithFormat:@"SELF.synced == 0"];
    NSArray *notSyncedObjects = [self.allLocationsArray filteredArrayUsingPredicate:notSynced];
    NSLog(@"notSyncedObjects.count %d",notSyncedObjects.count);
    if (notSyncedObjects.count > 0) {
        
        self.syncing = YES;
    
        xmlTextWriterPtr xmlTextWriter;
        xmlBufferPtr xmlBuffer;

        xmlBuffer = xmlBufferCreate();
        xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
        
        xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
        
            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "post");
            
                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[@"Location" UTF8String]);

                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "fields");
                        NSEntityDescription *locationEntity = [NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
                        NSArray *entityProperties = [locationEntity.propertiesByName allKeys];
                        for (NSString *propertyName in entityProperties) {
                            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
                                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "field");
                                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
                                xmlTextWriterEndElement(xmlTextWriter); //field
                            }
                        }
                    xmlTextWriterEndElement(xmlTextWriter); //fields

                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
                        for (Location *location in notSyncedObjects) {
                            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
                                if (!location.xid) {
                                    [location setXid:[self newid]];
                                    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                                        NSLog(@"setXid UIDocumentSaveForOverwriting success");
                                    }];
                                }
                                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[location.xid UTF8String]);
                                NSMutableString *locationValues = [NSMutableString string];
                                for (NSString *propertyName in entityProperties) {
                                    if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
                                        if ([propertyName isEqualToString:@"route"]) {
                                            [locationValues appendFormat:@"%@,",location.route.xid];
                                        } else {
                                            [locationValues appendFormat:@"%@,",[location valueForKey:propertyName]];
                                        }
                                    }
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
        
//        NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
        
        return requestData;
    } else {
        return nil;
    }
}

#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
//    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
//    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
    NSXMLParser *responseParser = [[NSXMLParser alloc] initWithData:self.responseData];
    responseParser.delegate = self;
    if (![responseParser parse]) {
        NSLog(@"[responseParser parserError] %@", [responseParser parserError].localizedDescription);
    }
    responseParser = nil;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if ([elementName isEqualToString:@"ok"]) {
        NSPredicate *matchedXid = [NSPredicate predicateWithFormat:@"SELF.xid == %@",[attributeDict valueForKey:@"xid"]];
        NSArray *matchedObjects = [self.allLocationsArray filteredArrayUsingPredicate:matchedXid];
        Location *location = [matchedObjects lastObject];
        location.synced = [NSNumber numberWithBool:YES];
//        NSLog(@"%@", [matchedObjects lastObject]);
    }

}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"setSynced UIDocumentSaveForOverwriting success");
        self.syncing = NO;
    }];

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
    return @"Routes";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    Route *route = (Route *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];

    NSDateFormatter *startDateFormatter = [[NSDateFormatter alloc] init];
    [startDateFormatter setDateStyle:NSDateFormatterShortStyle];
    [startDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSDateFormatter *finishDateFormatter = [[NSDateFormatter alloc] init];
    [finishDateFormatter setDateStyle:NSDateFormatterNoStyle];
    [finishDateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    
    NSNumberFormatter *distanceNumberFormatter = [[NSNumberFormatter alloc] init];
    [distanceNumberFormatter setMaximumFractionDigits:0];
    
    NSNumberFormatter *speedNumberFormatter = [[NSNumberFormatter alloc] init];
    [speedNumberFormatter setMaximumFractionDigits:1];
    
    NSTimeInterval routeOverallTime = [route.finishTime timeIntervalSinceDate:route.startTime];
    NSNumber *speed = [NSNumber numberWithDouble:0.0];
    
    if (routeOverallTime != 0) {
        speed = [NSNumber numberWithDouble:(3.6 * [route.overallDistance doubleValue] / routeOverallTime)];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%d %@m %@km/h", route.locations.count, [distanceNumberFormatter stringFromNumber:route.overallDistance], [speedNumberFormatter stringFromNumber:speed]];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ — %@", [startDateFormatter stringFromDate:route.startTime], [finishDateFormatter stringFromDate:route.finishTime]];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		Route *route = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        for (Location *location in route.locations) {
            NSLog(@"location to delete %@", location);
            [self.locationsDatabase.managedObjectContext deleteObject:location];
        }
        NSLog(@"route to delete %@", route);
        [self.locationsDatabase.managedObjectContext deleteObject:route];
        [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"UIDocumentSaveForOverwriting success");
        }];
    }   

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    Route *route = (Route *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    self.locationsArray = [route.locations sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO selector:@selector(compare:)]]];
    return indexPath;

}


#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
                
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        [self updateInfoLabels];

    } else if (type == NSFetchedResultsChangeInsert) {
        
//        NSLog(@"NSFetchedResultsChangeInsert");

        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];

    } else if (type == NSFetchedResultsChangeUpdate) {

//        NSLog(@"NSFetchedResultsChangeUpdate");

        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];

    }
}

@end