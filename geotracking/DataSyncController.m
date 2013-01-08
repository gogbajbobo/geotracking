//
//  DataSyncController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/22/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "DataSyncController.h"
#import "AppDelegate.h"
#import "UDOAuthBasic.h"


@interface DataSyncController() <NSURLConnectionDataDelegate, NSXMLParserDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval timerInterval;
@property (nonatomic, strong) NSDictionary *eventsToSync;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) int changesCount;

@end

@implementation DataSyncController
@synthesize changesCount = _changesCount;

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
    self.changesCount = self.changesCount + 1;
    NSLog(@"self.changesCount %d", self.changesCount);
    if (self.changesCount == 20) {
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
    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    [self syncDataFromDocument:app.tracker.locationsDatabase];
}

- (NSTimer *)timer {
    if (!_timer) {
        _timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:self.timerInterval target:self selector:@selector(onTimerTick:) userInfo:nil repeats:YES];
        NSLog(@"_timer %@", _timer);
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
    
    xmlTextWriterPtr xmlTextWriter;
    xmlBufferPtr xmlBuffer;
    
    xmlBuffer = xmlBufferCreate();
    xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
    
    xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "post");

    
    for (NSString *entityName in allEntityNames) {
        NSEntityDescription *entityDescription = [allEntities objectForKey:entityName];
        if (![entityDescription isAbstract]) {
            NSLog(@"%@", entityName);
            NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
            request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO selector:@selector(compare:)]];
            NSError *error;
            NSArray *fetchedData = [document.managedObjectContext executeFetchRequest:request error:&error];
            if (!fetchedData) {
                NSLog(@"executeFetchRequest error %@", error.localizedDescription);
            } else {
                NSLog(@"fetchedData.count %d", fetchedData.count);
                NSPredicate *notSynced = [NSPredicate predicateWithFormat:@"SELF.synced == 0"];
                NSArray *notSyncedData = [fetchedData filteredArrayUsingPredicate:notSynced];
                NSLog(@"notSyncedData.count %d", notSyncedData.count);
                if (notSyncedData.count > 0) {
                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
                    xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[entityName UTF8String]);
                    
                    NSArray *entityProperties = [entityDescription.propertiesByName allKeys];
                    NSLog(@"entityProperties %@", entityProperties);
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
                }
            }
        } else {
            NSLog(@"Entity %@ is Abstract", entityName);
        }
    }
    
    xmlTextWriterEndElement(xmlTextWriter); //post
    
    xmlTextWriterEndDocument(xmlTextWriter);
    xmlFreeTextWriter(xmlTextWriter);
    
    NSData *requestData = [NSData dataWithBytes:(xmlBuffer->content) length:(xmlBuffer->use)];
    xmlBufferFree(xmlBuffer);
    
//    NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
    
    
    
    if (requestData) {
        NSURL *requestURL = [NSURL URLWithString:@"https://system.unact.ru/asa/?_host=oldcat&_svc=iexp/gt"];
//        NSURL *requestURL = [NSURL URLWithString:@"http://lamac.local/~sasha/ud/?--show-headers"];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
        [request setHTTPMethod:@"POST"];
        [request setHTTPBody:requestData];
        [request setValue:@"text/xml" forHTTPHeaderField:@"Content-type"];
        NSLog(@"request %@", request);
        [[UDOAuthBasic sharedOAuth] checkToken];
//        NSLog(@"[UDOAuthBasic sharedOAuth] checkToken %@", [[UDOAuthBasic sharedOAuth] checkToken]);
//        NSLog(@"authenticateRequest %@", [[UDOAuthBasic sharedOAuth] authenticateRequest:(NSURLRequest *) request]);
        request = [[[UDOAuthBasic sharedOAuth] authenticateRequest:(NSURLRequest *) request] mutableCopy];
        NSLog(@"[request allHTTPHeaderFields] %@", [request allHTTPHeaderFields]);
            NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
            if (!connection) {
                NSLog(@"connection error");
//                self.trackerStatus = @"SYNC FAIL";
//                [self updateInfoLabels];
//                self.syncing = NO;
            }
    } else {
        NSLog(@"No data to sync");
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
    
    NSString *responseString = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    NSLog(@"connectionDidFinishLoading responseData %@", responseString);
//    NSXMLParser *responseParser = [[NSXMLParser alloc] initWithData:self.responseData];
//    responseParser.delegate = self;
//    if (![responseParser parse]) {
//        NSLog(@"[responseParser parserError] %@", [responseParser parserError].localizedDescription);
//        self.trackerStatus = @"PARSER FAIL";
//        [self updateInfoLabels];
//        self.syncing = NO;
//    }
//    responseParser = nil;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

//    if ([elementName isEqualToString:@"ok"]) {
//        NSPredicate *matchedXid = [NSPredicate predicateWithFormat:@"SELF.xid == %@",[attributeDict valueForKey:@"xid"]];
//        NSArray *matchedObjects = [self.allLocationsArray filteredArrayUsingPredicate:matchedXid];
//        if (matchedObjects.count > 0) {
//            Location *location = [matchedObjects lastObject];
//            location.synced = [NSNumber numberWithBool:YES];
//            location.lastSyncTimestamp = [NSDate date];
//        } else {
//            matchedObjects = [self.resultsController.fetchedObjects filteredArrayUsingPredicate:matchedXid];
//            if (matchedObjects.count > 0) {
//                Track *track = [matchedObjects lastObject];
////                if (![track.xid isEqualToString:self.currentTrack.xid]) {
//                    track.synced = [NSNumber numberWithBool:YES];
////                }
//                track.lastSyncTimestamp = [NSDate date];
//            }
//        }
////        NSLog(@"%@", [matchedObjects lastObject]);
//    }

}

- (void)parserDidEndDocument:(NSXMLParser *)parser {

//    [self.locationsDatabase saveToURL:self.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
//        NSLog(@"setSynced UIDocumentSaveForOverwriting success");
//        self.trackerStatus = @"";
//        [self updateInfoLabels];
//        self.syncing = NO;
//        if (!self.locationManagerRunning) {
//            [self startConnection];
//        }
//    }];

}


@end
