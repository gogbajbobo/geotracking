//
//  Track.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"

@class STGTLocation;

@interface STGTTrack : STGTDatum

@property (nonatomic, retain) NSDate * finishTime;
@property (nonatomic, retain) NSNumber * overallDistance;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSSet *locations;
@end

@interface STGTTrack (CoreDataGeneratedAccessors)

- (void)addLocationsObject:(STGTLocation *)value;
- (void)removeLocationsObject:(STGTLocation *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
