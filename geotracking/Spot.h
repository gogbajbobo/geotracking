//
//  Spot.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Datum.h"

@class Interest, Network;

@interface Spot : Datum

@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSData * image;
@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSSet *interests;
@property (nonatomic, retain) NSSet *networks;
@end

@interface Spot (CoreDataGeneratedAccessors)

- (void)addInterestsObject:(Interest *)value;
- (void)removeInterestsObject:(Interest *)value;
- (void)addInterests:(NSSet *)values;
- (void)removeInterests:(NSSet *)values;

- (void)addNetworksObject:(Network *)value;
- (void)removeNetworksObject:(Network *)value;
- (void)addNetworks:(NSSet *)values;
- (void)removeNetworks:(NSSet *)values;

@end
