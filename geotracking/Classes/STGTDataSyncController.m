//
//  DataSyncController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/22/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTDataSyncController.h"
#import "STGTAuthBasic.h"
#import "STGTTrackingLocationController.h"
#import "GDataXMLNode.h"
#import "STGTSettingsController.h"
#import "STGTSettings.h"
#import "STGTSpot.h"

#define DEFAULT_NAMESPACE @"https://github.com/sys-team/ASA.chest"
#define DEFAULT_SYNCSERVER @"https://system.unact.ru/utils/proxy.php?_address=https://hqvsrv58.unact.ru/rc_unact_old/chest"
#define DEFAULT_FETCHLIMIT 20

@interface STGTDataSyncController() <NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) NSManagedObject *syncObject;
@property (nonatomic, strong) STGTSettings *settings;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;

@end

@implementation STGTDataSyncController

+ (STGTDataSyncController *)sharedSyncer
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedSyncer = nil;
    dispatch_once(&pred, ^{
        _sharedSyncer = [[self alloc] init];
    });
    return _sharedSyncer;
}

- (STGTTrackingLocationController *)tracker
{
    if(!_tracker) {
        _tracker = [STGTTrackingLocationController sharedTracker];
    }
    return _tracker;
}

- (STGTSettings *)settings {
    if (!_settings) {
        _settings = self.tracker.settings;
    }
    return _settings;
}

- (void)setSyncing:(BOOL)syncing {
    if (_syncing != syncing) {
        _syncing = syncing;
        [self.tracker updateInfoLabels];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"STGTDataSyncing" object:self];
    }
}

- (NSNumber *)numberOfUnsynced {
    return [NSNumber numberWithInt:self.resultsController.fetchedObjects.count];
}

- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTDatum"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sqts" ascending:YES selector:@selector(compare:)]];
        [request setIncludesSubentities:YES];
        request.predicate = [NSPredicate predicateWithFormat:@"SELF.lts == %@ || SELF.ts > SELF.lts", nil];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.tracker.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _resultsController.delegate = self;
        NSError *error;
        if (![_resultsController performFetch:&error]) {
//            NSLog(@"sync init performFetch error %@", error.localizedDescription);
//            NSLog(@"fetchedObjects.count %d", _resultsController.fetchedObjects.count);
        } else {
//            NSLog(@"sync init performFetch");
//            NSLog(@"fetchedObjects.count %d", _resultsController.fetchedObjects.count);
//            [UIApplication sharedApplication].applicationIconBadgeNumber = _resultsController.fetchedObjects.count;
            [self.tracker updateInfoLabels];
        }
    }
    return _resultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    //    NSLog(@"controllerDidChangeContent");
//    [UIApplication sharedApplication].applicationIconBadgeNumber = controller.fetchedObjects.count;
    [self.tracker updateInfoLabels];
    if (controller.fetchedObjects.count % [self.settings.fetchLimit integerValue] == 0) {
        [self.timer fire];
    }

}

- (void)fireTimer {
    //    NSLog(@"timer fire at %@", [NSDate date]);
    [self.timer fire];
}

- (void)onTimerTick:(NSTimer *)timer {
//    NSLog(@"timer tick at %@", [NSDate date]);
    [self dataSyncing];
}

- (NSTimer *)timer {
    if (!_timer) {
//        NSLog(@"self.settings.syncInterval %@", self.settings.syncInterval);
        _timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:[self.settings.syncInterval doubleValue] target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
//        NSLog(@"_timer %@", _timer);
    }
    return _timer;
}

- (void)tokenReceived:(NSNotification *)notification {
//    NSLog(@"tokenReceived");
    [self fireTimer];
}

- (void)startSyncer {
    NSLog(@"startSyncer");
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenReceived:) name:@"tokenReceived" object:nil];
}

- (void)stopSyncer {
    NSLog(@"stopSyncer");
    [self.timer invalidate];
    self.timer = nil;
    self.resultsController = nil;
    self.settings = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"tokenReceived" object:nil];
}

- (void)dataSyncing {
    if (!self.syncing) {
        self.tracker.trackerStatus = @"SYNC";
        self.syncing = YES;
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTDatum"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"sqts" ascending:YES selector:@selector(compare:)]];
        [request setIncludesSubentities:YES];
        [request setFetchLimit:[self.settings.fetchLimit integerValue]];
        request.predicate = [NSPredicate predicateWithFormat:@"SELF.lts == %@ || SELF.ts > SELF.lts", nil];
        NSError *error;
            
        NSArray *fetchedData = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
        
    //    NSLog(@"fetchedData.count %d", fetchedData.count);
    //    NSLog(@"fetchedData %@", fetchedData);
    //    NSLog(@"fetchedObjects.count %d", self.resultsController.fetchedObjects.count);
    //    NSLog(@"self.resultsController.fetchedObjects %@", self.resultsController.fetchedObjects);
        
        if (fetchedData.count == 0) {
            NSLog(@"No data to sync");
    //        [self sendData:nil toServer:@"https://system.unact.ru/reflect/?--mirror"];
            [self sendData:nil toServer:self.settings.syncServerURI];
        } else {        
//        [self sendData:[self xmlFrom:fetchedData] toServer:@"https://system.unact.ru/reflect/?--mirror"];
            [self sendData:[self xmlFrom:fetchedData] toServer:self.settings.syncServerURI];
        }
    }
}

- (NSData *)xmlFrom:(NSArray *)fetchedData {
    
    GDataXMLElement *postNode = [GDataXMLElement elementWithName:@"post"];
    [postNode addNamespace:[GDataXMLNode namespaceWithName:@"" stringValue:self.settings.xmlNamespace]];
    
    for (NSManagedObject *object in fetchedData) {
        //            NSLog(@"object %@", object);
        //            NSLog(@"object.xid %@", [object valueForKey:@"xid"]);
        //        NSLog(@"----> %@", [[object entity] name]);
        //        NSLog(@"timestamp %@", [object valueForKey:@"ts"]);
        //        NSLog(@"createTimestamp %@", [object valueForKey:@"cts"]);
        //        NSLog(@"lastSyncTimestamp %@", [object valueForKey:@"lts"]);
        //        NSLog(@"sendQueryTimestamp %@", [object valueForKey:@"sqts"]);
        
        GDataXMLElement *dNode = [GDataXMLElement elementWithName:@"d"];
        [dNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:[[object entity] name]]];
        [dNode addAttribute:[GDataXMLNode attributeWithName:@"xid" stringValue:[object valueForKey:@"xid"]]];
        
//        NSLog(@"[[object entity] name] %@", [[object entity] name]);
        
        NSEntityDescription *entityDescription = [NSEntityDescription entityForName:[[object entity] name] inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
        
        //            NSLog(@"relationshipsByName for %@: %@", [[object entity] name], entityDescription.relationshipsByName);
        
        NSArray *entityProperties = [entityDescription.propertiesByName allKeys];
        for (NSString *propertyName in entityProperties) {
            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"sqts"]||[propertyName isEqualToString:@"lts"])) {
                id value = [object valueForKey:propertyName];
                if (value) {
                    if ([value isKindOfClass:[NSString class]]) {
                        GDataXMLElement *propertyNode = [GDataXMLElement elementWithName:@"string" stringValue:value];
                        [propertyNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:propertyName]];
                        [dNode addChild:propertyNode];
                    } else if ([value isKindOfClass:[NSDate class]]) {
                        NSString *date = [NSString stringWithFormat:@"%@", value];
                        GDataXMLElement *propertyNode = [GDataXMLElement elementWithName:@"date" stringValue:date];
                        [propertyNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:propertyName]];
                        [dNode addChild:propertyNode];
                    } else if ([value isKindOfClass:[NSNumber class]]) {
                        NSString *number = [NSString stringWithFormat:@"%@", value];
                        GDataXMLElement *propertyNode = [GDataXMLElement elementWithName:@"double" stringValue:number];
                        [propertyNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:propertyName]];
                        [dNode addChild:propertyNode];
                    } else if ([value isKindOfClass:[NSData class]]) {
                        NSString *data = [NSString stringWithFormat:@"%@", value];
                        GDataXMLElement *propertyNode = [GDataXMLElement elementWithName:@"png" stringValue:data];
                        [propertyNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:propertyName]];
                        [dNode addChild:propertyNode];
                    } else if ([value isKindOfClass:[NSManagedObject class]]) {
                        if ([value valueForKey:@"xid"]) {
                            GDataXMLElement *propertyNode = [GDataXMLElement elementWithName:@"d"];
                            [propertyNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:[[value entity] name]]];
                            [propertyNode addAttribute:[GDataXMLNode attributeWithName:@"xid" stringValue:[value valueForKey:@"xid"]]];
                            [dNode addChild:propertyNode];
                        }
                    } else if ([value isKindOfClass:[NSSet class]]) {
                        //                            NSLog(@"propertyName %@", propertyName);
                        NSRelationshipDescription *inverseRelationship = [[entityDescription.relationshipsByName objectForKey:propertyName] inverseRelationship];
                        //                            NSLog(@"inverseRelationship isToMany %d", [inverseRelationship isToMany]);
                        if ([inverseRelationship isToMany]) {
                            for (NSManagedObject *object in value) {
                                GDataXMLElement *childNode = [GDataXMLElement elementWithName:@"d"];
                                [childNode addAttribute:[GDataXMLNode attributeWithName:@"name" stringValue:object.entity.name]];
                                [childNode addAttribute:[GDataXMLNode attributeWithName:@"xid" stringValue:[object valueForKey:@"xid"]]];
                                [dNode addChild:childNode];
                            }
                        }
                    }
                }
            }
        }
        [postNode addChild:dNode];
    }
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithRootElement:postNode];
//        NSLog(@"xmlDoc %@", [[NSString alloc] initWithData:[xmlDoc XMLData] encoding:NSUTF8StringEncoding]);
    return [xmlDoc XMLData];
}


- (void)sendData:(NSData *)requestData toServer:(NSString *)serverUrlString {
    NSURL *requestURL = [NSURL URLWithString:serverUrlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    if (!requestData) {
        [request setHTTPMethod:@"GET"];
//        NSLog(@"GET");
    } else {
//        NSLog(@"POST");
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestData];
        [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
    }
    
    [[STGTAuthBasic sharedOAuth] checkToken];
    request = [[self.authDelegate authenticateRequest:(NSURLRequest *) request] mutableCopy];
    NSLog(@"[request valueForHTTPHeaderField:Authorization] %@", [request valueForHTTPHeaderField:@"Authorization"]);
    NSLog(@"request %@", request);
    if ([request valueForHTTPHeaderField:@"Authorization"]) {
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (!connection) {
            NSLog(@"connection error");
            self.tracker.trackerStatus = @"NO CONNECTION";
            self.syncing = NO;
        }
    } else {
        NSLog(@"No Authorization header");
        self.tracker.trackerStatus = @"NO TOKEN";
        self.syncing = NO;
    }
    
//    NSLog(@"request %@", request);
//    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
//    if (!connection) {
//        NSLog(@"connection error");
//        self.tracker.trackerStatus = @"SYNC FAIL";
//        self.syncing = NO;
//    }

}


#pragma mark - NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    self.tracker.trackerStatus = @"SYNC FAIL";
    self.syncing = NO;
    NSLog(@"connection didFailWithError: %@", error);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.responseData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
//    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
//    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
    
//    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"STGTtest" ofType:@"xml"];
//    self.responseData = [NSData dataWithContentsOfFile:dataPath];
    
//    NSLog(@"self.responseData %@", [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
    
    NSError *error;
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:self.responseData options:0 error:&error];
    NSDictionary *namespaces = [[NSDictionary alloc] initWithObjectsAndKeys:self.settings.xmlNamespace, @"ns", nil];

    if (!xmlDoc) {
        NSLog(@"%@", error.description);
        self.tracker.trackerStatus = @"RESPONSE ERROR";
        self.syncing = NO;
    } else {
        NSArray *errorNodes = [xmlDoc nodesForXPath:@"//ns:error" namespaces:namespaces error:nil];
        if (errorNodes.count > 0) {
            for (GDataXMLElement *errorNode in errorNodes) {
                NSLog(@"error: %@", [errorNode attributeForName:@"code"].stringValue);
            }
            self.tracker.trackerStatus = @"SYNC ERROR";
            self.syncing = NO;
        } else {
            NSArray *entityNodes = [xmlDoc nodesForXPath:@"//ns:response" namespaces:namespaces error:nil];
//            NSArray *entityNodes = [xmlDoc nodesForXPath:@"//ns:post" namespaces:namespaces error:nil];
            
            for (GDataXMLElement *entityNode in entityNodes) {
                //        NSString *entityName = [[[entityNode nodesForXPath:@"@name" error:nil] lastObject] stringValue];
                //        NSLog(@"entityName %@", entityName);
                NSArray *entityItems = [entityNode nodesForXPath:@"./ns:d" namespaces:namespaces error:nil];
                
                for (GDataXMLElement *entityItem in entityItems) {
                    NSString *entityName = [[[entityItem nodesForXPath:@"@name" error:nil] lastObject] stringValue];
//                    NSLog(@"entityName %@", entityName);
                    NSString *entityXid = [[[entityItem nodesForXPath:@"./@xid" error:nil] lastObject] stringValue];
//                    NSLog(@"entityXid.stringValue %@", entityXid);
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
                    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
                    request.predicate = [NSPredicate predicateWithFormat:@"SELF.xid == %@", entityXid];
                    NSArray *result = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
                    
                    if ([result lastObject]) {
                        self.syncObject = [result lastObject];
//                        NSLog(@"result lastObject");
                    } else {
                        self.syncObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
                        [self.syncObject setValue:entityXid forKey:@"xid"];
                        [self.syncObject setValue:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lts"];
//                        NSLog(@"insertNewObjectForEntity");
                    }
                    
                    if ([entityName isEqualToString:@"STGTSpot"]) {
                        STGTSpot *spot = (STGTSpot *)self.syncObject;
                        NSArray *itemProperties = [entityItem nodesForXPath:@"./ns:d" namespaces:namespaces error:nil];
                        
                        for (GDataXMLElement *itemProperty in itemProperties) {
                            //                    NSLog(@"itemProperty %@", itemProperty);
                            NSString *propertyName = [[[itemProperty nodesForXPath:@"./@name" error:nil] lastObject] stringValue];
                            NSString *propertyXid = [[[itemProperty nodesForXPath:@"./@xid" error:nil] lastObject] stringValue];
                            
                            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:propertyName];
                            request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
                            request.predicate = [NSPredicate predicateWithFormat:@"SELF.xid == %@", propertyXid];
                            NSArray *result = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
                            NSManagedObject *property;
                            
                            if ([result lastObject]) {
                                property = [result lastObject];
                                //                        NSLog(@"result lastObject");
                            } else {
                                property = [NSEntityDescription insertNewObjectForEntityForName:propertyName inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
                                [property setValue:propertyXid forKey:@"xid"];
                                [property setValue:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lts"];
                                //                        NSLog(@"insertNewObjectForEntity");
                            }
                            
                            if ([propertyName isEqualToString:@"STGTInterest"]) {
                                [spot addInterestsObject:(STGTInterest *)property];
                            } else if ([propertyName isEqualToString:@"STGTNetwork"]) {
                                [spot addNetworksObject:(STGTNetwork *)property];
                            }

                        }
                    }
                    
                    
                    NSString *timestamp = [[[entityItem nodesForXPath:@"./ns:date[@name='ts']" namespaces:namespaces error:nil] lastObject] stringValue];
                    
                    if (timestamp) {
                        //                    NSLog(@"timestamp %@", timestamp);
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
                        NSDate *serverDate = [dateFormatter dateFromString:timestamp];
                        NSDate *localDate = [self.syncObject valueForKey:@"lts"];
                        
                        //            NSLog(@"serverDate %@", serverDate);
                        //            NSLog(@"localDate %@", localDate);
                        
                        if ([localDate compare:serverDate] == NSOrderedAscending) {
//                            NSLog(@"serverDate > localDate");
                            NSArray *entityItemProperties = [entityItem nodesForXPath:@"./ns:*" namespaces:namespaces error:nil];
                            for (GDataXMLElement *entityItemProperty in entityItemProperties) {
                                //                    NSLog(@"entityItemProperty %@", [entityItemProperty name]);
                                
                                NSString *type = [entityItemProperty name];
                                NSString *name = [[[entityItemProperty nodesForXPath:@"./@name" error:nil] lastObject] stringValue];
                                NSString *value = entityItemProperty.stringValue;
                                
                                if ([type isEqualToString:@"string"]) {
                                    [self.syncObject setValue:value forKey:name];
                                } else if ([type isEqualToString:@"double"]) {
                                    NSNumber *number = [[[NSNumberFormatter alloc] init] numberFromString:value];
                                    [self.syncObject setValue:number forKey:name];
                                } else if ([type isEqualToString:@"png"] && ![value isEqualToString:@"text too large"]) {
                                    NSCharacterSet *charsToRemove = [NSCharacterSet characterSetWithCharactersInString:@"< >"];
                                    NSString *dataString = [[value stringByTrimmingCharactersInSet:charsToRemove] stringByReplacingOccurrencesOfString:@" " withString:@""];
                                    //                        NSLog(@"dataString %@", dataString);
                                    NSMutableData *data = [NSMutableData data];
                                    int i;
                                    for (i = 0; i+2 <= dataString.length; i+=2) {
                                        NSRange range = NSMakeRange(i, 2);
                                        NSString* hexString = [dataString substringWithRange:range];
                                        NSScanner* scanner = [NSScanner scannerWithString:hexString];
                                        unsigned int intValue;
                                        [scanner scanHexInt:&intValue];
                                        [data appendBytes:&intValue length:1];
                                    }
                                    [self.syncObject setValue:data forKey:name];
                                }
                                
                            }
                            [self.syncObject setValue:serverDate forKey:@"ts"];
                            
                        } else {
//                            NSLog(@"serverDate <= localDate");
                        }
                        
                    }
                    
                    
                    [self.syncObject setValue:[NSDate date] forKey:@"lts"];
                    
                    
                    //            NSLog(@"self.syncObject %@", self.syncObject);
                    
                }
            }
            
            [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                NSLog(@"setSynced UIDocumentSaveForOverwriting success");
                self.tracker.trackerStatus = @"";
                self.syncing = NO;
                if (self.resultsController.fetchedObjects.count > 0) {
                    [self dataSyncing];
                }
            }];
            
        }

    }
    
    

}


@end
