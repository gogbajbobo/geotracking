//
//  STGTSpotImage.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/6/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTImage.h"

@class STGTSpot;

@interface STGTSpotImage : STGTImage

@property (nonatomic, retain) STGTSpot *spot;

@end
