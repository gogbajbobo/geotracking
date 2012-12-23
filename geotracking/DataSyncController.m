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
    
    NSLog(@"requestData %@", [[NSString alloc] initWithData:requestData encoding:NSUTF8StringEncoding]);

}


@end
