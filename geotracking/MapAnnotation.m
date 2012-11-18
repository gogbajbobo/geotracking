//
//  MapAnnotation.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

+ (MapAnnotation *)createAnnotationForLocation:(Location *)location
{
    MapAnnotation *annotation = [[MapAnnotation alloc] init];
    annotation.location = location;
    return annotation;
}

+ (MapAnnotation *)createAnnotationForSpot:(Spot *)spot
{
    MapAnnotation *annotation = [[MapAnnotation alloc] init];
    annotation.spot = spot;
    return annotation;
}

- (NSString *)title
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    if (self.location) {
        return [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self.location.timestamp]];
    } else {
        return [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self.spot.timestamp]];
    }
}

- (NSString *)subtitle
{
    CLLocationDegrees latitude;
    CLLocationDegrees longitude;
    
    if (self.location) {
        latitude = [self.location.latitude doubleValue];
        longitude = [self.location.longitude doubleValue];
    } else {
        latitude = [self.spot.latitude doubleValue];
        longitude = [self.spot.longitude doubleValue];
    }
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    return [NSString stringWithFormat:@"%@",[location description]];

}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    if (self.location) {
        coordinate.latitude = [self.location.latitude doubleValue];
        coordinate.longitude = [self.location.longitude doubleValue];
    } else {
        coordinate.latitude = [self.spot.latitude doubleValue];
        coordinate.longitude = [self.spot.longitude doubleValue];
    }
    return coordinate;
}

@end
