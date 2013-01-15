//
//  Spot.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"

@class STGTSpotProperty;

@interface STGTSpot : STGTDatum

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSSet *properties;
@end

@interface STGTSpot (CoreDataGeneratedAccessors)

- (void)addPropertiesObject:(STGTSpotProperty *)value;
- (void)removePropertiesObject:(STGTSpotProperty *)value;
- (void)addProperties:(NSSet *)values;
- (void)removeProperties:(NSSet *)values;

@end
