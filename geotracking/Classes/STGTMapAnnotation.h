//
//  MapAnnotation.h
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "STGTLocation.h"
#import "STGTSpot.h"

@interface STGTMapAnnotation : NSObject <MKAnnotation>

+ (STGTMapAnnotation *)createAnnotationForLocation:(STGTLocation *)location;
+ (STGTMapAnnotation *)createAnnotationForSpot:(STGTSpot *)spot;
+ (STGTMapAnnotation *)createAnnotationForCoordinate:(CLLocationCoordinate2D)coordinate;
@property (nonatomic, strong) STGTLocation *location;
@property (nonatomic, strong) STGTSpot *spot;

@end
