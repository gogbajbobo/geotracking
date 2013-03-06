//
//  geotrackingTests.m
//  geotrackingTests
//
//  Created by Maxim Grigoriev on 11/7/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "geotrackingTests.h"

#import <UIKit/UIKit.h>
#import "STGTDataSyncController.h"
#import "STGTTrackingLocationController.h"
#import "UDPushNotificationCenter.h"
#import "UDPushAuthCodeRetriever.h"
#import "UDAuthTokenRetriever.h"
#import "STGTAuthBasic.h"
#import "Reachability.h"
#import "STGTSessionManager.h"

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

//- (void)testTLC {
//    STGTTrackingLocationController *tlc = [[STGTTrackingLocationController alloc] init];
//    [tlc startTrackingLocation];
//    STAssertTrue([tlc locationManagerRunning], nil);
//    [tlc stopTrackingLocation];
//    STAssertFalse([tlc locationManagerRunning], nil);
//}

- (void)testSession {

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSessionChange:) name:@"CurrentSessionChange" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSessionStart:) name:@"NewSessionStart" object:nil];
    
    [[STGTAuthBasic sharedOAuth] checkToken];
    
    
    [[STGTSessionManager sharedManager] startSessionForUID:@"1" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    NSUInteger count = [[[STGTSessionManager sharedManager] sessions] count];
    NSUInteger testCount = 1;
    STAssertEquals(count, testCount, @"Wrong count");
    STAssertEquals([STGTSessionManager sharedManager].currentSessionUID, @"1", @"Wrong count");
    
    [[STGTSessionManager sharedManager] startSessionForUID:@"2" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");
    STAssertEquals([STGTSessionManager sharedManager].currentSessionUID, @"2", @"Wrong count");

    [[STGTSessionManager sharedManager] startSessionForUID:@"1" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");
    STAssertEquals([STGTSessionManager sharedManager].currentSessionUID, @"1", @"Wrong count");
    
    [STGTSessionManager sharedManager].currentSessionUID = @"3";
    STAssertEquals([STGTSessionManager sharedManager].currentSessionUID, @"1", @"Wrong count");
    
    [STGTSessionManager sharedManager].currentSessionUID = @"2";
    STAssertEquals([STGTSessionManager sharedManager].currentSessionUID, @"2", @"Wrong count");
    
    [[STGTSessionManager sharedManager] sessionCompletionFinished:[[[STGTSessionManager sharedManager] sessions] objectForKey:@"2"]];
    
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");
    STAssertNil([STGTSessionManager sharedManager].currentSessionUID, @"currentSessionUID not nil");

    [[STGTSessionManager sharedManager] sessionCompletionFinished:[[[STGTSessionManager sharedManager] sessions] objectForKey:@"1"]];
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");
    
}

- (void)testSessionCompletion {
    [[STGTAuthBasic sharedOAuth] checkToken];
    
    [[STGTSessionManager sharedManager] startSessionForUID:@"1" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    [[STGTSessionManager sharedManager] stopSessionForUID:@"1"];
    STAssertEquals([[[STGTSessionManager sharedManager].sessions objectForKey:@"1"] status], @"finishing", @"Wrong count");
    STAssertNil([STGTSessionManager sharedManager].currentSessionUID, @"currentSessionUID not nil");
    [[STGTSessionManager sharedManager] sessionCompletionFinished:[[[STGTSessionManager sharedManager] sessions] objectForKey:@"1"]];
    STAssertEquals([[[STGTSessionManager sharedManager].sessions objectForKey:@"1"] status], @"completed", @"Wrong count");
    
    [[STGTSessionManager sharedManager] startSessionForUID:@"2" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    NSUInteger count = [[[STGTSessionManager sharedManager] sessions] count];
    NSUInteger testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");
    
    [[STGTSessionManager sharedManager] cleanCompleteSessions];
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 1;
    STAssertEquals(count, testCount, @"Wrong count");

    [[STGTSessionManager sharedManager] startSessionForUID:@"3" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");
    [[STGTSessionManager sharedManager] sessionCompletionFinished:[[[STGTSessionManager sharedManager] sessions] objectForKey:@"3"]];
    [[STGTSessionManager sharedManager] startSessionForUID:@"3" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    [[STGTSessionManager sharedManager] cleanCompleteSessions];
    count = [[[STGTSessionManager sharedManager] sessions] count];
    testCount = 2;
    STAssertEquals(count, testCount, @"Wrong count");

    
}

- (void)testSessionStatus {
    [[STGTAuthBasic sharedOAuth] checkToken];
    
    [[STGTSessionManager sharedManager] startSessionForUID:@"1" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    [[STGTSessionManager sharedManager] startSessionForUID:@"2" AuthDelegate:[STGTAuthBasic sharedOAuth]];
    [[STGTSessionManager sharedManager] stopSessionForUID:@"1"];
    
    STGTSession *session1 = [[STGTSessionManager sharedManager].sessions objectForKey:@"1"];
    STGTSession *session2 = [[STGTSessionManager sharedManager].sessions objectForKey:@"2"];
    
    STAssertEquals([session1 status], @"finishing", @"Wrong count");
    STAssertEquals([session2 status], @"running", @"Wrong count");
        
    [[STGTSessionManager sharedManager] sessionCompletionFinished:session1];
    STAssertEquals([session1 status], @"completed", @"Wrong count");

}


- (void)currentSessionChange:(NSNotification *)notification {
    STAssertNotNil(notification, @"notification is nil");
}

- (void)newSessionStart:(NSNotification *)notification {
    STAssertNotNil(notification.object, @"notification.object is nil");
}


@end
