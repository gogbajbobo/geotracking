//
//  AppDelegate.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTAppDelegate.h"
#import "STGTSessionManager.h"

@implementation STGTAppDelegate

@synthesize window = _window;


- (void)applicationWillTerminate:(UIApplication *)application {

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

//    [[STGTTrackingLocationController sharedTracker] initDatabase:^(BOOL success) {
//        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
//        
//        [[STGTDataSyncController sharedSyncer] setAuthDelegate:[STGTAuthBasic sharedOAuth]];
//        [[STGTAuthBasic sharedOAuth] checkToken];
//        
//        self.pushNotificatonCenter = [UDPushNotificationCenter sharedPushNotificationCenter];
//        self.authCodeRetriever = (UDPushAuthCodeRetriever *)[(UDAuthTokenRetriever *)[[STGTAuthBasic sharedOAuth] tokenRetriever] codeDelegate];
//        self.reachability = [Reachability reachabilityWithHostname:[[STGTAuthBasic sharedOAuth] reachabilityServer]];
//        self.reachability.reachableOnWWAN = YES;
//        [self.reachability startNotifier]; 
//    }];
    
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    [[STGTAuthBasic sharedOAuth] checkToken];

    self.pushNotificatonCenter = [UDPushNotificationCenter sharedPushNotificationCenter];
    self.authCodeRetriever = (UDPushAuthCodeRetriever *)[(UDAuthTokenRetriever *)[[STGTAuthBasic sharedOAuth] tokenRetriever] codeDelegate];
    self.reachability = [Reachability reachabilityWithHostname:[[STGTAuthBasic sharedOAuth] reachabilityServer]];
    self.reachability.reachableOnWWAN = YES;
    [self.reachability startNotifier];

    [[STGTSessionManager sharedManager] startSessionForUID:@"1" AuthDelegate:[STGTAuthBasic sharedOAuth]];

//    [[STGTSessionManager sharedManager] startSessionForUID:@"2" AuthDelegate:[STGTAuthBasic sharedOAuth]];

    
    return YES;

}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
#if DEBUG
    NSLog(@"Device token: %@", deviceToken);
#endif
    [self.authCodeRetriever registerDeviceWithPushToken:deviceToken];
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
#if DEBUG
    NSLog(@"Failed to get token, error: %@", error);
#endif
    
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [self.pushNotificatonCenter processPushNotification:userInfo];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    
}

@end
