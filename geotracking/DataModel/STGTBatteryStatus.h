//
//  STGTBatteryStatus.h
//  geotracking
//
//  Created by Maxim Grigoriev on 3/19/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"


@interface STGTBatteryStatus : STGTDatum

@property (nonatomic, retain) NSNumber * batteryLevel;
@property (nonatomic, retain) NSString * batteryState;

@end
