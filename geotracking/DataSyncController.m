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
#import "TrackingLocationController.h"
#import "Datum.h"


@interface DataSyncController() <NSURLConnectionDataDelegate, NSXMLParserDelegate>
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval timerInterval;
@property (nonatomic, strong) NSDictionary *eventsToSync;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic) int changesCount;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic, strong) NSString *pEntityName;
@property (nonatomic, strong) NSMutableArray *pEntityXids;

@end

@implementation DataSyncController
@synthesize changesCount = _changesCount;

- (TrackingLocationController *)tracker
{
    if(!_tracker) {
        AppDelegate *app = [[UIApplication sharedApplication] delegate];
        _tracker = app.tracker;
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
//                NSLog(@"fetchedData.count %d", fetchedData.count);
                NSPredicate *notSynced = [NSPredicate predicateWithFormat:@"SELF.synced == 0"];
                NSArray *notSyncedData = [fetchedData filteredArrayUsingPredicate:notSynced];
                NSLog(@"notSyncedData.count %d", notSyncedData.count);
                if (notSyncedData.count > 0) {
                    
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
                    NSLog(@"No data to sync");
                }
            }
        } else {
            NSLog(@"Entity %@ is Abstract", entityName);
        }
    }
    
    xmlTextWriterEndElement(xmlTextWriter); //post
    
    xmlTextWriterEndDocument(xmlTextWriter);
    xmlFreeTextWriter(xmlTextWriter);
    
    requestData = [NSData dataWithBytes:(xmlBuffer->content) length:(xmlBuffer->use)];
    xmlBufferFree(xmlBuffer);
    
//    NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);

    
    if (dataToSync) {
        self.tracker.trackerStatus = @"SYNC";
        self.tracker.syncing = YES;
        NSURL *requestURL = [NSURL URLWithString:@"https://system.unact.ru/reflect/?--mirror"];
//        NSURL *requestURL = [NSURL URLWithString:@"https://system.unact.ru/asa/?_host=oldcat&_svc=iexp/gt"];
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
                self.tracker.trackerStatus = @"SYNC FAIL";
                self.tracker.syncing = NO;
            }
    } else {
        NSLog(@"No data to sync");
        self.changesCount = 0;
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
    self.pEntityName = @"";
    self.pEntityXids = [NSMutableArray array];
    if (![responseParser parse]) {
        NSLog(@"[responseParser parserError] %@", [responseParser parserError].localizedDescription);
        self.tracker.trackerStatus = @"PARSER FAIL";
        self.tracker.syncing = NO;
    }
    responseParser.delegate = nil;
    responseParser = nil;
}

#pragma mark - NSXMLParserDelegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

    if ([elementName isEqualToString:@"set-of"]) {
        self.pEntityName = [attributeDict valueForKey:@"name"];
    }
    if ([elementName isEqualToString:@"d"] && ![[attributeDict allKeys] containsObject:@"name"]) {
//        NSLog(@"%@", self.pEntityName);
//        NSLog(@"xid %@", [attributeDict valueForKey:@"xid"]);
        [self.pEntityXids addObject:[attributeDict valueForKey:@"xid"]];
    }

}

- (void)parserDidEndDocument:(NSXMLParser *)parser {

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Datum"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"ANY SELF.xid IN %@", self.pEntityXids];
    NSError *error;
    NSArray *result = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
    NSLog(@"result.count %d", result.count);
    for (Datum *datum in result) {
        datum.synced = [NSNumber numberWithBool:YES];
        datum.lastSyncTimestamp = [NSDate date];
    }
    self.changesCount = 0;
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"setSynced UIDocumentSaveForOverwriting success");
        self.tracker.trackerStatus = @"";
        self.tracker.syncing = NO;
        self.pEntityName = @"";
        self.pEntityXids = [NSMutableArray array];
    }];

}


@end
