//
//  Network.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Datum.h"

@class Spot;

@interface Network : Datum

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSSet *points;
@end

@interface Network (CoreDataGeneratedAccessors)

- (void)addPointsObject:(Spot *)value;
- (void)removePointsObject:(Spot *)value;
- (void)addPoints:(NSSet *)values;
- (void)removePoints:(NSSet *)values;

@end
