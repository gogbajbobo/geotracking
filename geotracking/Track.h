//
//  Track.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Datum.h"

@class Location;

@interface Track : Datum

@property (nonatomic, retain) NSDate * finishTime;
@property (nonatomic, retain) NSNumber * overallDistance;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSSet *locations;
@end

@interface Track (CoreDataGeneratedAccessors)

- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
