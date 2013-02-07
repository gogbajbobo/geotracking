//
//  STGTInterestImage.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/7/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTImage.h"

@class STGTInterest;

@interface STGTInterestImage : STGTImage

@property (nonatomic, retain) STGTInterest *interest;

@end
