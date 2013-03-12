//
//  DataSyncController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/22/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <libxml/encoding.h>
#import <libxml/xmlwriter.h>
#import "STGTRequestAuthenticatable.h"
//#import "STGTTrackingLocationController.h"
#import "STGTGeoTrackable.h"
#import "STGTTrackerManagedDocument.h"

@interface STGTDataSyncController : NSObject

@property (nonatomic, strong) id <STGTRequestAuthenticatable> authDelegate;
//@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic) BOOL syncing;
@property (nonatomic, strong) NSNumber *numberOfUnsynced;
@property (nonatomic, strong) id <STGTSession> session;
@property (nonatomic, strong) STGTTrackerManagedDocument *document;



- (void)startSyncer;
- (void)stopSyncer;
- (void)fireTimer;
//+ (STGTDataSyncController *)sharedSyncer;


@end
