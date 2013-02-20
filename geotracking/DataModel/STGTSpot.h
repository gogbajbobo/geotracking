//
//  STGTSpot.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/20/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"

@class STGTInterest, STGTNetwork, STGTSpotImage;

@interface STGTSpot : STGTDatum

@property (nonatomic, retain) NSString * address;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * avatarXid;
@property (nonatomic, retain) NSSet *images;
@property (nonatomic, retain) NSSet *interests;
@property (nonatomic, retain) NSSet *networks;
@end

@interface STGTSpot (CoreDataGeneratedAccessors)

- (void)addImagesObject:(STGTSpotImage *)value;
- (void)removeImagesObject:(STGTSpotImage *)value;
- (void)addImages:(NSSet *)values;
- (void)removeImages:(NSSet *)values;

- (void)addInterestsObject:(STGTInterest *)value;
- (void)removeInterestsObject:(STGTInterest *)value;
- (void)addInterests:(NSSet *)values;
- (void)removeInterests:(NSSet *)values;

- (void)addNetworksObject:(STGTNetwork *)value;
- (void)removeNetworksObject:(STGTNetwork *)value;
- (void)addNetworks:(NSSet *)values;
- (void)removeNetworks:(NSSet *)values;

@end
