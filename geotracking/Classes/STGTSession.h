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
#import "STGTSessionManager.h"

@interface STGTSession : NSObject

@property (strong, nonatomic) STGTTrackerManagedDocument *document;
@property (strong, nonatomic) STGTDataSyncController *syncer;
@property (strong, nonatomic) STGTTrackingLocationController *tracker;
@property (weak, nonatomic) STGTSessionManager *manager;
@property (strong, nonatomic) NSString *uid;

- (STGTSession *)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate;
- (void)completeSession;

@end
