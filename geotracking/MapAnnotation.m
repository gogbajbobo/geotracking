//
//  MapAnnotation.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "MapAnnotation.h"

@interface MapAnnotation ()
@property (nonatomic) BOOL addNewSpot;
@property (nonatomic) CLLocationCoordinate2D newSpotCoordinate;

@end

@implementation MapAnnotation

+ (MapAnnotation *)createAnnotationForCoordinate:(CLLocationCoordinate2D)coordinate{
    MapAnnotation *annotation = [[MapAnnotation alloc] init];
    annotation.newSpotCoordinate = coordinate;
    annotation.addNewSpot = YES;
    return annotation;
}


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
    if (self.location) {
        CLLocationDegrees latitude = [self.location.latitude doubleValue];
        CLLocationDegrees longitude = [self.location.longitude doubleValue];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        return [NSString stringWithFormat:@"%@",[location description]];
    } else if (self.spot) {
        if (!self.spot.label) {
            return @"untitled";
        } else {
            return self.spot.label;
        }
    } else if (self.addNewSpot) {
        return @"Add new spot…";
    } else {
        return @"";
    }
    
}

- (NSString *)subtitle
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
    [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    if (self.location) {
        return [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self.location.timestamp]];
    } else if (self.spot) {
        return [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self.spot.timestamp]];
    } else {
        return nil;
    }
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    if (self.location) {
        coordinate.latitude = [self.location.latitude doubleValue];
        coordinate.longitude = [self.location.longitude doubleValue];
    } else if (self.spot) {
        coordinate.latitude = [self.spot.latitude doubleValue];
        coordinate.longitude = [self.spot.longitude doubleValue];
    } else if (self.addNewSpot) {
        coordinate = self.newSpotCoordinate;
    }
    return coordinate;
}

@end
