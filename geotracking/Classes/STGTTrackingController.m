//
//  STGTTrackingController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 2/25/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTTrackingController.h"
#import "STGTTrackerManagedDocument.h"
#import "STGTDataSyncController.h"

@interface STGTTrackingController()

@property (nonatomic, strong) NSMutableDictionary *documents;
@property (nonatomic, strong) NSMutableDictionary *trackers;
@property (nonatomic, strong) NSMutableDictionary *syncers;

@end

@implementation STGTTrackingController

+ (STGTTrackingController *)sharedTrackingController {
    static dispatch_once_t pred = 0;
    __strong static id _sharedTrackingController = nil;
    dispatch_once(&pred, ^{
        _sharedTrackingController = [[self alloc] init];
    });
    return _sharedTrackingController;
}

- (void)startTrackingWithId:(NSNumber *)trackingId completionHandler:(void (^)(BOOL success))completionHandler {
    
    [self databaseWithId:trackingId completionHandler:^(BOOL success) {
        if (success) {
            STGTTrackerManagedDocument *document = [self.documents objectForKey:[trackingId stringValue]];
            STGTTrackingLocationController *tracker = [self trackerInitWithDocument:document];
            STGTDataSyncController *syncer = [self syncerInitWithDocument:document];
            [self.trackers setValue:tracker forKey:[trackingId stringValue]];
            [self.syncers setValue:syncer forKey:[trackingId stringValue]];
            self.trackerOnFront = tracker;
            completionHandler(YES);
        } else {
            NSLog(@"databaseWithId:%@ fail", trackingId);
            completionHandler(NO);
        }
    }];
    
}

- (void)stopTrackingWithId:(NSNumber *)trackingId {
    
}

- (void)databaseWithId:(NSNumber *)trackingId completionHandler:(void (^)(BOOL success))completionHandler {
    
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"STGT%@.%@", [trackingId stringValue], @"sqlite"]];
    
    STGTTrackerManagedDocument *document = [[STGTTrackerManagedDocument alloc] initWithFileURL:url];
    document.persistentStoreOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    [document persistentStoreTypeForFileType:NSSQLiteStoreType];
        
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [document closeWithCompletionHandler:^(BOOL success) {
                [document openWithCompletionHandler:^(BOOL success) {
                    NSLog(@"document UIDocumentSaveForCreating success %d", success);
                    [self.documents setValue:document forKey:[trackingId stringValue]];
                    completionHandler(YES);
                }];
            }];
        }];
    } else if (document.documentState == UIDocumentStateClosed) {
        [document openWithCompletionHandler:^(BOOL success) {
            NSLog(@"document openWithCompletionHandler success");
            [self.documents setValue:document forKey:[trackingId stringValue]];
            completionHandler(YES);
        }];
    } else if (document.documentState == UIDocumentStateNormal) {
        [self.documents setValue:document forKey:[trackingId stringValue]];
        completionHandler(YES);
    }

}

- (STGTTrackingLocationController *)trackerInitWithDocument:(STGTTrackerManagedDocument *)document {
    return [[STGTTrackingLocationController alloc] init];
}

- (STGTDataSyncController *)syncerInitWithDocument:(STGTTrackerManagedDocument *)document {
    return [[STGTDataSyncController alloc] init];
}

@end

