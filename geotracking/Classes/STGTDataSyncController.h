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

@interface STGTDataSyncController : NSObject

@property (nonatomic) NSUInteger fetchLimit;

- (void)startSyncer;
- (void)stopSyncer;
- (void)fireTimer;
- (void)changesCountPlusOne;
+ (STGTDataSyncController *)sharedSyncer;


@end
