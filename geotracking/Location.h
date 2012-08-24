//
//  Location.h
//  geotracking
//
//  Created by Григорьев Максим on 8/23/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * horizontalAccuracy;
@property (nonatomic, retain) NSDate * timestamp;
@property (nonatomic, retain) NSNumber * speed;
@property (nonatomic, retain) NSNumber * course;

@end
