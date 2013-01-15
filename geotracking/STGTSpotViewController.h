//
//  SpotViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STGTTrackingLocationController.h"
#import "Spot.h"

@interface STGTSpotViewController : UIViewController
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic) CLLocationCoordinate2D coordinate;
@property (nonatomic) BOOL newSpotMode;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) Spot *spot;
@property (nonatomic, strong) Spot *filterSpot;


@end
