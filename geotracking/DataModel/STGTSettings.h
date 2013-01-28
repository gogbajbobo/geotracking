//
//  STGTSettings.h
//  geotracking
//
//  Created by Maxim Grigoriev on 1/24/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTDatum.h"


@interface STGTSettings : STGTDatum

@property (nonatomic, retain) NSString * authServiceParameters; // ?
@property (nonatomic, retain) NSString * authServiceURI; // ?
@property (nonatomic, retain) NSNumber * desiredAccuracy; // !
@property (nonatomic, retain) NSNumber * distanceFilter; // !
@property (nonatomic, retain) NSNumber * fetchLimit; // *
@property (nonatomic, retain) NSNumber * mapHeading; // *
@property (nonatomic, retain) NSNumber * mapType; // *
@property (nonatomic, retain) NSNumber * requiredAccuracy; // !
@property (nonatomic, retain) NSNumber * syncInterval; //
@property (nonatomic, retain) NSString * syncServerURI; // *
@property (nonatomic, retain) NSString * tokenServerURL; // *
@property (nonatomic, retain) NSNumber * trackDetectionTime; // !
@property (nonatomic, retain) NSString * xmlNamespace; // *

@end