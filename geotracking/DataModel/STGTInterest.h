//
//  STGTInterest.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/7/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"

@class STGTInterestImage, STGTSpot;

@interface STGTInterest : STGTDatum

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) STGTInterestImage *image;
@property (nonatomic, retain) NSSet *spots;
@end

@interface STGTInterest (CoreDataGeneratedAccessors)

- (void)addSpotsObject:(STGTSpot *)value;
- (void)removeSpotsObject:(STGTSpot *)value;
- (void)addSpots:(NSSet *)values;
- (void)removeSpots:(NSSet *)values;

@end
