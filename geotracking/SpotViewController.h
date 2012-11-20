//
//  SpotViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TrackingLocationController.h"
#import "Spot.h"

@interface SpotViewController : UIViewController
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL newSpotMode;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) Spot *spot;


@end
