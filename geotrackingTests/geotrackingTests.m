//
//  geotrackingTests.m
//  geotrackingTests
//
//  Created by Maxim Grigoriev on 11/7/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "geotrackingTests.h"
#import "STGTTrackingLocationController.h"

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
    STGTTrackingLocationController *tlc = [[STGTTrackingLocationController alloc] init];
    [tlc startTrackingLocation];
    STAssertTrue([tlc locationManagerRunning], nil);
    [tlc stopTrackingLocation];
    STAssertFalse([tlc locationManagerRunning], nil);
}

@end
