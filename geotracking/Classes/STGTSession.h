//
//  STGTSession.h
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STGTTrackerManagedDocument.h"
#import "STGTTrackingLocationController.h"
#import "STGTDataSyncController.h"
#import "STGTGeoTrackable.h"

@interface STGTSession : NSObject <STGTManagedSession>

@property (strong, nonatomic) STGTTrackerManagedDocument *document;
@property (strong, nonatomic) STGTDataSyncController *syncer;
@property (strong, nonatomic) STGTTrackingLocationController *tracker;
@property (weak, nonatomic) id <STGTSessionManager> manager;
@property (strong, nonatomic) NSString *uid;
@property (nonatomic, strong) NSString *status;

- (STGTSession *)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate;
- (STGTSession *)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate settings:(NSDictionary *)settings;
- (void)completeSession;
- (void)createNewDocumentWithcompletionHandler:(void (^)(BOOL success))completionHandler;

- (void)startBatteryChecking;
- (void)stopBatteryChecking;

@end
