//
//  STGTNetworkImage.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/7/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTImage.h"

@class STGTNetwork;

@interface STGTNetworkImage : STGTImage

@property (nonatomic, retain) STGTNetwork *network;

@end
