//
//  STGTTrackingController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/25/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STGTTrackingLocationController.h"

@interface STGTTrackingController : NSObject

@property (nonatomic, strong) STGTTrackingLocationController *trackerOnFront;

+ (STGTTrackingController *)sharedTrackingController;

- (void)startTrackingWithId:(NSNumber *)userId completionHandler:(void (^)(BOOL success))completionHandler;
- (void)stopTrackingWithId:(NSNumber *)userId;


@end
