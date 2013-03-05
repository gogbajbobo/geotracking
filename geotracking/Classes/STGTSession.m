//
//  STGTSession.m
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSession.h"

@implementation STGTSession

- (STGTSession *)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate {
    STGTSession *session = [[STGTSession alloc] init];
    session.uid = uid;
    [session documentWithUID:uid completionHandler:^(BOOL success) {
        if (success) {
            session.syncer = [[STGTDataSyncController alloc] init];
            session.tracker = [[STGTTrackingLocationController alloc] init];
            session.syncer.document = session.document;
            session.tracker.document = session.document;
            session.tracker.session = session;
            session.syncer.session = session;
            session.syncer.authDelegate = authDelegate;
            [session.tracker trackerInit];
            NSLog(@"session %@", session);
            [[NSNotificationCenter defaultCenter] postNotificationName:@"newSessionStart" object:session];
        }
    }];
    return session;
}

- (void)completeSession {
    
}

- (void)documentWithUID:(NSString *)uid  completionHandler:(void (^)(BOOL success))completionHandler {
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"STGT%@.%@", uid, @"sqlite"]];
    NSLog(@"url %@", [url standardizedURL]);
    STGTTrackerManagedDocument *document = [[STGTTrackerManagedDocument alloc] initWithFileURL:url];
    document.persistentStoreOptions = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    [document persistentStoreTypeForFileType:NSSQLiteStoreType];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[document.fileURL path]]) {
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
            [document closeWithCompletionHandler:^(BOOL success) {
                [document openWithCompletionHandler:^(BOOL success) {
                    NSLog(@"document UIDocumentSaveForCreating success");
                    self.document = document;
                    completionHandler(YES);
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
//    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"STGT%@.%@", self.uid, @"sqlite"]];
//    [[NSFileManager defaultManager] removeItemAtURL:url error:&error];

    [self documentWithUID:self.uid completionHandler:^(BOOL success) {
        if (success) {
            NSLog(@"self.document %@", self.document);
            self.tracker.document = self.document;
            self.syncer.document = self.document;
            completionHandler(YES);
        }
    }];
}

@end
