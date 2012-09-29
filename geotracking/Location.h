//
//  Location.h
//  geotracking
//
//  Created by Maxim Grigoriev on 9/29/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Route;

@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * course;
@property (nonatomic, retain) NSNumber * horizontalAccuracy;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSNumber * synced;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSString * xid;
@property (nonatomic, retain) Route *route;

@end
