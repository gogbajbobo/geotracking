//
//  Spot.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Datum.h"

@class SpotProperty;

@interface Spot : Datum

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSSet *properties;
@end

@interface Spot (CoreDataGeneratedAccessors)

- (void)addPropertiesObject:(SpotProperty *)value;
- (void)removePropertiesObject:(SpotProperty *)value;
- (void)addProperties:(NSSet *)values;
- (void)removeProperties:(NSSet *)values;

@end
