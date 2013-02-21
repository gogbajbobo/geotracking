//
//  MapAnnotation.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTMapAnnotation.h"

@interface STGTMapAnnotation ()
@property (nonatomic) BOOL addNewSpot;
@property (nonatomic) CLLocationCoordinate2D newSpotCoordinate;

@end

@implementation STGTMapAnnotation

+ (STGTMapAnnotation *)createAnnotationForCoordinate:(CLLocationCoordinate2D)coordinate{
    STGTMapAnnotation *annotation = [[STGTMapAnnotation alloc] init];
    annotation.newSpotCoordinate = coordinate;
    annotation.addNewSpot = YES;
//    NSLog(@"createAnnotationForCoordinate %@", annotation);
    return annotation;
}


+ (STGTMapAnnotation *)createAnnotationForLocation:(STGTLocation *)location
{
    STGTMapAnnotation *annotation = [[STGTMapAnnotation alloc] init];
    annotation.location = location;
//    NSLog(@"createAnnotationForLocation %@", annotation);
    return annotation;
}

+ (STGTMapAnnotation *)createAnnotationForSpot:(STGTSpot *)spot
{
    STGTMapAnnotation *annotation = [[STGTMapAnnotation alloc] init];
    annotation.spot = spot;
//    NSLog(@"createAnnotationForSpot %@", annotation);
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
            return NSLocalizedString(@"UNTITLED", @"");
        } else {
            return self.spot.label;
        }
    } else if (self.addNewSpot) {
        return NSLocalizedString(@"ADD NEW SPOT", @"");
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
        return [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:self.location.ts]];
    } else if (self.spot) {
        return [NSString stringWithFormat:@"%@",self.spot.address];
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
