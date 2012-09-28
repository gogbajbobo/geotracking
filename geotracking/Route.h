//
//  Route.h
//  geotracking
//
//  Created by Maxim Grigoriev on 9/28/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Location;

@interface Route : NSManagedObject

@property (nonatomic, retain) NSDate * finishTime;
@property (nonatomic, retain) NSNumber * overalDistance;
@property (nonatomic, retain) NSString * xid;
@property (nonatomic, retain) NSDate * startTime;
@property (nonatomic, retain) NSSet *locations;
@end

@interface Route (CoreDataGeneratedAccessors)

- (void)addLocationsObject:(Location *)value;
- (void)removeLocationsObject:(Location *)value;
- (void)addLocations:(NSSet *)values;
- (void)removeLocations:(NSSet *)values;

@end
