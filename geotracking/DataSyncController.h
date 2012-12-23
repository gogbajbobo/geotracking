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

@interface DataSyncController : NSObject

- (void)addEventToSyncer:(NSDictionary *)event;
- (void)startSyncer;
- (void)stopSyncer;
- (void)fireTimer;


@end
