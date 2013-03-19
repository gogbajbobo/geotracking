//
//  STGTSession.m
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSession.h"

@interface STGTSession()

@property (nonatomic, strong) NSTimer *batteryTimer;

@end

@implementation STGTSession

- (STGTSession *)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate {
    return [self initWithUID:uid AuthDelegate:authDelegate settings:nil];
}

- (STGTSession *)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate settings:(NSDictionary *)settings {
    STGTSession *session = [[STGTSession alloc] init];
    session.uid = uid;
    [session documentWithUID:uid completionHandler:^(BOOL success) {
        if (success) {
            session.syncer = [[STGTDataSyncController alloc] init];
            session.tracker = [[STGTTrackingLocationController alloc] init];
            session.syncer.document = session.document;
            session.tracker.document = session.document;
            session.tracker.session = session;
            session.tracker.startSettings = settings;
            session.syncer.session = session;
            session.syncer.authDelegate = authDelegate;
            [session.tracker trackerInit];
            //            NSLog(@"session1 %@", session);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NewSessionStart" object:session];
        } else {
            //            NSLog(@"not success");
        }
    }];
    return session;
}

- (void)completeSession {
    [self.tracker stopTrackingLocation];
}

- (void)documentWithUID:(NSString *)uid  completionHandler:(void (^)(BOOL success))completionHandler {
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"STGT%@.%@", uid, @"sqlite"]];
//    NSLog(@"url %@", [url standardizedURL]);
    STGTTrackerManagedDocument *document = [[STGTTrackerManagedDocument alloc] initWithFileURL:url];
    document.persistentStoreOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    [document persistentStoreTypeForFileType:NSSQLiteStoreType];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [document closeWithCompletionHandler:^(BOOL success) {
                [document openWithCompletionHandler:^(BOOL success) {
                    if (success) {
                        NSLog(@"document UIDocumentSaveForCreating success");
                        self.document = document;
                        completionHandler(YES);
                    }
                }];
            }];
        }];
    } else if (document.documentState == UIDocumentStateClosed) {
        [document openWithCompletionHandler:^(BOOL success) {
            NSLog(@"document openWithCompletionHandler success");
            self.document = document;
            completionHandler(YES);
        }];
    } else if (document.documentState == UIDocumentStateNormal) {
        self.document = document;
        completionHandler(YES);
    }

}

- (void)createNewDocumentWithcompletionHandler:(void (^)(BOOL success))completionHandler{

//    NSError *error;
//    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
//    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"STGT%@.%@", [(STGTSession *)self.session uid], @"sqlite"]];
//    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];

    NSError *error;
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"STGT%@.%@", self.uid, @"sqlite"]];
    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];

    [self documentWithUID:self.uid completionHandler:^(BOOL success) {
        if (success) {
            NSLog(@"self.document %@", self.document);
            self.tracker.document = self.document;
            self.syncer.document = self.document;
            completionHandler(YES);
        }
    }];
}

- (void)startBatteryChecking {
    
}

- (void)stopBatteryChecking {
    
}

- (NSTimer *)batteryTimer {
    if (!_batteryTimer) {
        _batteryTimer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:[self.tracker.settings.syncInterval doubleValue] target:self selector:@selector(onTimerTick:) userInfo:nil repeats:NO];;
    }
    return _batteryTimer;
}


@end
