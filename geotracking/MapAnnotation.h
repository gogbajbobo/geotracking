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

@interface MapAnnotation : NSObject <MKAnnotation>

+ (MapAnnotation *)createAnnotationFor:(Location *)location;
@property (nonatomic, strong) Location *location;

@end
