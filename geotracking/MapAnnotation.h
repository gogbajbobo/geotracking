//
//  MapAnnotation.h
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Location.h"
#import "Spot.h"

@interface MapAnnotation : NSObject <MKAnnotation>

+ (MapAnnotation *)createAnnotationForLocation:(Location *)location;
+ (MapAnnotation *)createAnnotationForSpot:(Spot *)spot;
+ (MapAnnotation *)createAnnotationForCoordinate:(CLLocationCoordinate2D)coordinate;
@property (nonatomic, strong) Location *location;
@property (nonatomic, strong) Spot *spot;

@end
