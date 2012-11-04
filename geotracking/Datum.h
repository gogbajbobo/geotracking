//
//  Datum.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Datum : NSManagedObject

@property (nonatomic, retain) NSDate * lastSyncTimestamp;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * xid;

@end
