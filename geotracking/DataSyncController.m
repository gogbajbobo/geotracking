//
//  DataSyncController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/22/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "DataSyncController.h"
#import "AppDelegate.h"

@interface DataSyncController()
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic) NSTimeInterval timerInterval;
@property (nonatomic, strong) NSDictionary *eventsToSync;

@end

@implementation DataSyncController


- (void)addEventToSyncer:(NSDictionary *)event {
    
}

- (void)fireTimer {
    [self.timer fire];
}

- (void)onTimerTick:(NSTimer *)timer {
    NSLog(@"timer tick at %@", [NSDate date]);
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

+ (void)syncDataFromDocument:(UIManagedDocument *)document {

    AppDelegate *app = [[UIApplication sharedApplication] delegate];
    NSLog(@"app.syncer %@", app.syncer);
    
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
                    
                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "fields");
                            NSArray *entityProperties = [entityDescription.propertiesByName allKeys];
                            for (NSString *propertyName in entityProperties) {
                                if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
                                    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "field");
                                    xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
                                    xmlTextWriterEndElement(xmlTextWriter); //field
                                }
                            }
                        xmlTextWriterEndElement(xmlTextWriter); //fields
                    
                        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
                            for (NSManagedObject *datum in notSyncedData) {
                                for (NSString *propertyName in entityProperties) {
                                    NSLog(@"datum valueForKey:%@ %@", propertyName, [datum valueForKey:propertyName]);
                                }
//                                xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
//                                xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[location.xid UTF8String]);
//                                NSMutableString *locationValues = [NSMutableString string];
//                                for (NSString *propertyName in entityProperties) {
//                                    if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
//                                        if ([propertyName isEqualToString:@"track"]) {
//                                            [locationValues appendFormat:@"%@,",location.track.xid];
//                                        } else {
//                                            [locationValues appendFormat:@"%@,",[location valueForKey:propertyName]];
//                                        }
//                                    }
//                                }
//                                if (locationValues.length > 0) [locationValues deleteCharactersInRange:NSMakeRange([locationValues length] - 1, 1)];
//                                xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[locationValues UTF8String]);
//                                xmlTextWriterEndElement(xmlTextWriter); //d
                            }

//                        NSLog(@"notSyncedData %@", notSyncedData);
                    
                        xmlTextWriterEndElement(xmlTextWriter); //cvs

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
    
    NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);

}

- (NSData *)requestData {
            
    xmlTextWriterPtr xmlTextWriter;
    xmlBufferPtr xmlBuffer;
    
    xmlBuffer = xmlBufferCreate();
    xmlTextWriter = xmlNewTextWriterMemory(xmlBuffer, 0);
    
    xmlTextWriterStartDocument(xmlTextWriter, "1.0", "UTF-8", NULL);
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "post");
    
    // Locations
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
    xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[@"Location" UTF8String]);
        
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
//    for (Location *location in notSyncedLocations) {
//        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
//        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[location.xid UTF8String]);
//        NSMutableString *locationValues = [NSMutableString string];
//        for (NSString *propertyName in entityProperties) {
//            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"])) {
//                if ([propertyName isEqualToString:@"track"]) {
//                    [locationValues appendFormat:@"%@,",location.track.xid];
//                } else {
//                    [locationValues appendFormat:@"%@,",[location valueForKey:propertyName]];
//                }
//            }
//        }
//        if (locationValues.length > 0) [locationValues deleteCharactersInRange:NSMakeRange([locationValues length] - 1, 1)];
//        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[locationValues UTF8String]);
//        xmlTextWriterEndElement(xmlTextWriter); //d
//    }
    xmlTextWriterEndElement(xmlTextWriter); //cvs
    
    xmlTextWriterEndElement(xmlTextWriter); //set-of
    
    // Tracks
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "set-of");
    xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *) "name", (xmlChar *)[@"Track" UTF8String]);
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "fields");
//    NSEntityDescription *trackEntity = [NSEntityDescription entityForName:@"Track" inManagedObjectContext:self.locationsDatabase.managedObjectContext];
//    entityProperties = [trackEntity.propertiesByName allKeys];
//    for (NSString *propertyName in entityProperties) {
//        if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"]||[propertyName isEqualToString:@"locations"])) {
//            xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "field");
//            xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"name", (xmlChar *)[propertyName UTF8String]);
//            xmlTextWriterEndElement(xmlTextWriter); //field
//        }
//    }
    xmlTextWriterEndElement(xmlTextWriter); //fields
    
    xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "csv");
//    for (Track *track in notSyncedTracks) {
//        xmlTextWriterStartElement(xmlTextWriter, (xmlChar *) "d");
//        xmlTextWriterWriteAttribute(xmlTextWriter, (xmlChar *)"xid", (xmlChar *)[track.xid UTF8String]);
//        NSMutableString *trackValues = [NSMutableString string];
//        for (NSString *propertyName in entityProperties) {
//            if (!([propertyName isEqualToString:@"xid"]||[propertyName isEqualToString:@"synced"]||[propertyName isEqualToString:@"locations"])) {
//                [trackValues appendFormat:@"%@,",[track valueForKey:propertyName]];
//            }
//        }
//        if (trackValues.length > 0) [trackValues deleteCharactersInRange:NSMakeRange([trackValues length] - 1, 1)];
//        xmlTextWriterWriteString(xmlTextWriter, (xmlChar *)[trackValues UTF8String]);
//        xmlTextWriterEndElement(xmlTextWriter); //d
//    }
    xmlTextWriterEndElement(xmlTextWriter); //cvs
    //
    xmlTextWriterEndElement(xmlTextWriter); //set-of
    
    
    xmlTextWriterEndElement(xmlTextWriter); //post
    
    xmlTextWriterEndDocument(xmlTextWriter);
    xmlFreeTextWriter(xmlTextWriter);
    
    NSData *requestData = [NSData dataWithBytes:(xmlBuffer->content) length:(xmlBuffer->use)];
    xmlBufferFree(xmlBuffer);
    
    //        NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);
    
    return requestData;
}


@end
