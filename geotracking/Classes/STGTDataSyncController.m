//
//  DataSyncController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/22/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTDataSyncController.h"
#import "UDOAuthBasic.h"
#import "STGTTrackingLocationController.h"
#import "GDataXMLNode.h"

#define NAMESPACE @"http://github.com/UDTO/UD/unknown"

@interface STGTDataSyncController() <NSURLConnectionDataDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval timerInterval;
@property (nonatomic, strong) NSDictionary *eventsToSync;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) int changesCount;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic, strong) NSManagedObject *syncObject;

@end

@implementation STGTDataSyncController
@synthesize changesCount = _changesCount;

+ (STGTDataSyncController *)sharedSyncer
{
    static dispatch_once_t pred = 0;
    __strong static id _sharedSyncer = nil;
    dispatch_once(&pred, ^{
        _sharedSyncer = [[self alloc] init]; // or some other init method
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


- (int)changesCount {
    if (!_changesCount) {
        NSNumber *requiredAccuracy = [[NSUserDefaults standardUserDefaults] objectForKey:@"changesCount"];
        if (requiredAccuracy == nil) {
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            _changesCount = 0;
            [settings setObject:[NSNumber numberWithDouble:_changesCount] forKey:@"changesCount"];
            [settings synchronize];
        } else {
            _changesCount = [requiredAccuracy intValue];
        }
    }
    return _changesCount;
}

- (void)setChangesCount:(int)changesCount {
    _changesCount = changesCount;
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    [settings setObject:[NSNumber numberWithDouble:changesCount] forKey:@"changesCount"];
    [settings synchronize];
}


- (void)changesCountPlusOne {
    self.changesCount += 1;
    NSLog(@"self.changesCount %d", self.changesCount);
    if (self.changesCount >= 20) {
        [self fireTimer];
        self.changesCount = 0;
    }
}

- (void)fireTimer {
    NSLog(@"timer fire at %@", [NSDate date]);
    [self.timer fire];
}

- (void)onTimerTick:(NSTimer *)timer {
    NSLog(@"timer tick at %@", [NSDate date]);
    if (!self.tracker.syncing) {
        [self syncDataFromDocument:self.tracker.locationsDatabase];
    }
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:self.timerInterval target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
//        NSLog(@"_timer %@", _timer);
    }
    return _timer;
}

- (NSTimeInterval)timerInterval {
    _timerInterval = 1800;
    return _timerInterval;
}

- (void)startSyncer {
    NSLog(@"startSyncer");
    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
    [currentRunLoop addTimer:self.timer forMode:NSDefaultRunLoopMode];
}

- (void)stopSyncer {
    NSLog(@"stopSyncer");
    [self.timer invalidate];
    self.timer = nil;
}

- (void)syncDataFromDocument:(UIManagedDocument *)document {

//    AppDelegate *app = [[UIApplication sharedApplication] delegate];
//    NSLog(@"app.syncer %@", app.syncer);
    
    NSDictionary *allEntities = document.managedObjectModel.entitiesByName;
    NSArray *allEntityNames = [allEntities allKeys];

    BOOL dataToSync = NO;
    NSData *requestData;
    
    xmlTextWriterPtr xmlTextWriter;
    xmlBufferPtr xmlBuffer;
    
    xmlBuffer = xmlBufferCreate();
    xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
    
    xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "post");
    xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "xmlns", (xmlChar *)[NAMESPACE UTF8String]);
    
    for (NSString *entityName in allEntityNames) {
        NSEntityDescription *entityDescription = [allEntities objectForKey:entityName];
        if (![entityDescription isAbstract]) {
//            NSLog(@"%@", entityName);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO selector:@selector(compare:)]];
            NSError *error;
            NSArray *fetchedData = [document.managedObjectContext executeFetchRequest:request error:&error];
            if (!fetchedData) {
                NSLog(@"executeFetchRequest error %@", error.localizedDescription);
            } else {
//                NSLog(@"fetchedData.count %d", fetchedData.count);
                NSPredicate *notSynced = [NSPredicate predicateWithFormat:@"SELF.synced == 0"];
                NSArray *notSyncedData = [fetchedData filteredArrayUsingPredicate:notSynced];
                if (notSyncedData.count > 0) {
                    NSLog(@"notSyncedData.count %d", notSyncedData.count);
                    
                    dataToSync = YES;
                    
                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
                    xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[entityName UTF8String]);
                    
                    NSArray *entityProperties = [entityDescription.propertiesByName allKeys];
//                    NSLog(@"entityProperties %@", entityProperties);
                    for (NSManagedObject *datum in notSyncedData) {
                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[[datum valueForKey:@"xid"] UTF8String]);
                        
                        for (NSString *propertyName in entityProperties) {
                            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
                                id value = [datum valueForKey:propertyName];
                                if (value) {
                                    if ([value isKindOfClass:[NSString class]]) {
                                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "string");
                                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
                                        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[value UTF8String]);
                                        xmlTextWriterEndElement(xmlTextWriter); //string
                                    } else if ([value isKindOfClass:[NSDate class]]) {
                                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "date");
                                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
                                        NSString *date = [NSString stringWithFormat:@"%@", value];
                                        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[date UTF8String]);
                                        xmlTextWriterEndElement(xmlTextWriter); //date
                                    } else if ([value isKindOfClass:[NSNumber class]]) {
                                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "double");
                                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
                                        NSString *number = [NSString stringWithFormat:@"%@", value];
                                        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[number UTF8String]);
                                        xmlTextWriterEndElement(xmlTextWriter); //double
                                    } else if ([value isKindOfClass:[NSData class]]) {
                                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "png");
                                        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
                                        NSString *data = [NSString stringWithFormat:@"%@", value];
                                        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[data UTF8String]);
                                        xmlTextWriterEndElement(xmlTextWriter); //png
                                    } else if ([value isKindOfClass:[NSSet class]]) {
                                        for (NSManagedObject *object in value) {
                                            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
                                            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[object.entity.name UTF8String]);
                                            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[[object valueForKey:@"xid"] UTF8String]);
                                            xmlTextWriterEndElement(xmlTextWriter); //d
                                        }
                                    }
                                }
                            }
                        }
                        
                        xmlTextWriterEndElement(xmlTextWriter); //d
                    }
                    
                    xmlTextWriterEndElement(xmlTextWriter); //set-of
                    
                } else {
//                    NSLog(@"No data to sync");
                }
            }
        } else {
//            NSLog(@"Entity %@ is Abstract", entityName);
        }
    }
    
    xmlTextWriterEndElement(xmlTextWriter); //post
    
    xmlTextWriterEndDocument(xmlTextWriter);
    xmlFreeTextWriter(xmlTextWriter);
    
    requestData = [NSData dataWithBytes:(xmlBuffer->content) length:(xmlBuffer->use)];
    xmlBufferFree(xmlBuffer);
    
//    NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);

//    [self sendData:requestData toServer:@"https://system.unact.ru/reflect/?--mirror"];
    
    if (dataToSync) {
        [self sendData:requestData toServer:@"https://system.unact.ru/reflect/?--mirror"];
    } else {
        NSLog(@"No data to sync");
        self.changesCount = 0;
    }

}

- (void)sendData:(NSData *)requestData toServer:(NSString *)serverUrlString {
    self.tracker.trackerStatus = @"SYNC";
    self.tracker.syncing = YES;
    NSURL *requestURL = [NSURL URLWithString:serverUrlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:requestData];
    [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
//    NSLog(@"request %@", request);
    [[UDOAuthBasic sharedOAuth] checkToken];
    request = [[[UDOAuthBasic sharedOAuth] authenticateRequest:(NSURLRequest *) request] mutableCopy];
    NSLog(@"[request valueForHTTPHeaderField:Authorization] %@", [request valueForHTTPHeaderField:@"Authorization"]);
    if ([request valueForHTTPHeaderField:@"Authorization"]) {
        NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
        if (!connection) {
            NSLog(@"connection error");
            self.tracker.trackerStatus = @"SYNC FAIL";
            self.tracker.syncing = NO;
        }
    } else {
        NSLog(@"No Authorization header");
        self.tracker.trackerStatus = @"NO TOKEN";
        self.tracker.syncing = NO;
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
    
//    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"xml"];
//    self.responseData = [NSData dataWithContentsOfFile:dataPath];
    
//    NSLog(@"self.responseData %@", [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);
    
    NSError *error;
    GDataXMLDocument *xmlDoc = [[GDataXMLDocument alloc] initWithData:self.responseData options:0 error:&error];
    NSDictionary *namespaces = [[NSDictionary alloc] initWithObjectsAndKeys:NAMESPACE, @"ns", nil];

    if (!xmlDoc) {
        NSLog(@"%@", error.description);
    }
    NSArray *entityNodes = [xmlDoc nodesForXPath:@"//ns:set-of" namespaces:namespaces error:nil];

    for (GDataXMLElement *entityNode in entityNodes) {
        NSString *entityName = [[[entityNode nodesForXPath:@"@name" error:nil] lastObject] stringValue];
//        NSLog(@"entityName %@", entityName);
        NSArray *entityItems = [entityNode nodesForXPath:@"./ns:d" namespaces:namespaces error:nil];

        for (GDataXMLElement *entityItem in entityItems) {
            NSString *entityXid = [[[entityItem nodesForXPath:@"./@xid" error:nil] lastObject] stringValue];
//            NSLog(@"entityXid.stringValue %@", entityXid);
            
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
            request.predicate = [NSPredicate predicateWithFormat:@"SELF.xid == %@", entityXid];
            NSArray *result = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];

            if ([result lastObject]) {
                self.syncObject = [result lastObject];
//                NSLog(@"result lastObject");
            } else {
                self.syncObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
                [self.syncObject setValue:entityXid forKey:@"xid"];
                [self.syncObject setValue:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lastSyncTimestamp"];
//                NSLog(@"insertNewObjectForEntity");
            }
            
            if ([entityName isEqualToString:@"STGTSpot"]) {
                NSArray *itemProperties = [entityItem nodesForXPath:@"./ns:d" namespaces:namespaces error:nil];
                NSMutableSet *propertiesSet = [NSMutableSet set];
                
                for (GDataXMLElement *itemProperty in itemProperties) {
//                    NSLog(@"itemProperty %@", itemProperty);
                    NSString *propertyName = [[[itemProperty nodesForXPath:@"./@name" error:nil] lastObject] stringValue];
                    NSString *propertyXid = [[[itemProperty nodesForXPath:@"./@xid" error:nil] lastObject] stringValue];
                    
                    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:propertyName];
                    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
                    request.predicate = [NSPredicate predicateWithFormat:@"SELF.xid == %@", propertyXid];
                    NSArray *result = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
                    NSManagedObject *property;
                    
                    if ([result lastObject]) {
                        property = [result lastObject];
//                        NSLog(@"result lastObject");
                    } else {
                        property = [NSEntityDescription insertNewObjectForEntityForName:propertyName inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
                        [property setValue:propertyXid forKey:@"xid"];
                        [property setValue:[NSDate dateWithTimeIntervalSince1970:0] forKey:@"lastSyncTimestamp"];
//                        NSLog(@"insertNewObjectForEntity");
                    }
                    [propertiesSet addObject:property];
                }
                [self.syncObject setValue:[propertiesSet copy] forKey:@"properties"];
            }
            
            
            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
            NSString *timestamp = [[[entityItem nodesForXPath:@"./ns:date[@name='timestamp']" namespaces:namespaces error:nil] lastObject] stringValue];

            NSDate *serverDate = [dateFormatter dateFromString:timestamp];
            NSDate *localDate = [self.syncObject valueForKey:@"lastSyncTimestamp"];
            
//            NSLog(@"serverDate %@", serverDate);
//            NSLog(@"localDate %@", localDate);
            
            if ([localDate compare:serverDate] == NSOrderedAscending) {
//                NSLog(@"serverDate > localDate");
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
                [self.syncObject setValue:serverDate forKey:@"timestamp"];

            } else {
//                NSLog(@"serverDate <= localDate");
            }
            
            [self.syncObject setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
            [self.syncObject setValue:[NSDate date] forKey:@"lastSyncTimestamp"];

            
//            NSLog(@"self.syncObject %@", self.syncObject);
            
        }
    }
    
//    GDataXMLElement *spotEntity = [[xmlDoc nodesForXPath:@"//set-of[@name='Spot']" error:nil] lastObject];
//    NSArray *spotItems = [spotEntity nodesForXPath:@"./d" error:nil];
//    
//    for (GDataXMLElement *spotItem in spotItems) {
//        NSArray *spotProperties = [spotItem nodesForXPath:@"./d" error:nil];
//        
//        for (GDataXMLElement *spotProperty in spotProperties) {
//            
//        }
//
//    }
    
    self.changesCount = 0;
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"setSynced UIDocumentSaveForOverwriting success");
        self.tracker.trackerStatus = @"";
        self.tracker.syncing = NO;
    }];

}


@end
