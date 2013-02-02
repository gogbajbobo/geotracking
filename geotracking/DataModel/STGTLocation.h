//
//  STGTLocation.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/2/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"

@class STGTTrack;

@interface STGTLocation : STGTDatum

@property (nonatomic, retain) NSNumber * course;
@property (nonatomic, retain) NSNumber * horizontalAccuracy;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) STGTTrack *track;

@end
