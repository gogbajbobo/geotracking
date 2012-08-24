//
//  MapAnnotation.m
//  geotracking
//
//  Created by Григорьев Максим on 8/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation
@synthesize location = _location;

+ (MapAnnotation *)createAnnotationFor:(Location *)location
{
    MapAnnotation *annotation = [[MapAnnotation alloc] init];
    annotation.location = location;
    return annotation;
}

- (NSString *)title
{
    return [NSString stringWithFormat:@"%@",self.location.timestamp];
}

- (NSString *)subtitle
{
	return [NSString stringWithFormat:@"%@, %@",self.location.latitude,self.location.longitude];
}

- (CLLocationCoordinate2D)coordinate
{
    CLLocationCoordinate2D coordinate;
    coordinate.latitude = [self.location.latitude doubleValue];
    coordinate.longitude = [self.location.longitude doubleValue];
    return coordinate;
}

@end
