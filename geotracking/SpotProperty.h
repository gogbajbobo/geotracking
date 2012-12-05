//
//  SpotProperty.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Datum.h"

@class Spot;

@interface SpotProperty : Datum

@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSSet *points;
@end

@interface SpotProperty (CoreDataGeneratedAccessors)

- (void)addPointsObject:(Spot *)value;
- (void)removePointsObject:(Spot *)value;
- (void)addPoints:(NSSet *)values;
- (void)removePoints:(NSSet *)values;

@end
