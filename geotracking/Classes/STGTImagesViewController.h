//
//  STGTImagesViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/18/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STGTSpot.h"

@interface STGTImagesViewController : UIPageViewController
@property (nonatomic, strong) STGTSpot *spot;

@end
