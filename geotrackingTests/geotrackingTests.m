//
//  geotrackingTests.m
//  geotrackingTests
//
//  Created by Maxim Grigoriev on 11/7/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "geotrackingTests.h"
#import "TrackingLocationController.h"

@implementation geotrackingTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testTLC {
    TrackingLocationController *tlc = [[TrackingLocationController alloc] init];
    [tlc startTrackingLocation];
    STAssertTrue([tlc locationManagerRunning], nil);
    [tlc stopTrackingLocation];
    STAssertFalse([tlc locationManagerRunning], nil);
}

@end
