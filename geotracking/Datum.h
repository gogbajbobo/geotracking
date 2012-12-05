//
//  Datum.h
//  geotracking
//
//  Created by Maxim Grigoriev on 12/5/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Datum : NSManagedObject

@property (nonatomic, retain) NSDate * lastSyncTimestamp;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * xid;

@end
