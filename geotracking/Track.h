//
//  Track.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/10/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Track : NSManagedObject

@property (nonatomic, retain) NSDate * finishTime;
@property (nonatomic, retain) NSNumber * overallDistance;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSString * xid;
@property (nonatomic, retain) NSSet *locations;
@end

@interface Track (CoreDataGeneratedAccessors)

- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
