//
//  AppDelegate.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTAppDelegate.h"
#import "STGTSessionManager.h"

#define PUSH_REGISTER_RETRY_TIMEOUT 10

@implementation STGTAppDelegate

@synthesize window = _window;


- (void)applicationWillTerminate:(UIApplication *)application {

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self registerFotPushNotifications];
    [[STGTAuthBasic sharedOAuth] checkToken];

    self.pushNotificatonCenter = [UDPushNotificationCenter sharedPushNotificationCenter];
    self.authCodeRetriever = (UDPushAuthCodeRetriever *)[(UDAuthTokenRetriever *)[[STGTAuthBasic sharedOAuth] tokenRetriever] codeDelegate];
    self.reachability = [Reachability reachabilityWithHostname:[[STGTAuthBasic sharedOAuth] reachabilityServer]];
    self.reachability.reachableOnWWAN = YES;
    [self.reachability startNotifier];

    NSDictionary *startSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:120.0], @"timeFilter", nil];
    [[STGTSessionManager sharedManager] startSessionForUID:@"1" AuthDelegate:[STGTAuthBasic sharedOAuth] settings:startSettings];
    
    return YES;

}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    if ([[UIApplication sharedApplication] enabledRemoteNotificationTypes] != UIRemoteNotificationTypeNone) {
#if DEBUG
        NSLog(@"Device token: %@", deviceToken);
#endif
        [self.authCodeRetriever registerDeviceWithPushToken:deviceToken];
    }
    else{
        [self failedToRegisterForPushNotifications];
    }
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
#if DEBUG
    NSLog(@"Failed to get token, error: %@", error);
#endif
    [self failedToRegisterForPushNotifications];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    NSLog(@"Token %@",userInfo);
    [self.pushNotificatonCenter processPushNotification:userInfo];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
//    NSLog(@"applicationDidReceiveMemoryWarning");
    [[STGTSessionManager sharedManager] cleanCompleteSessions];
}

- (void) registerFotPushNotifications{
    NSLog(@"Trying to register for push");
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
}

- (void) failedToRegisterForPushNotifications{
    NSLog(@"Failed to register for push");
    [self performSelector:@selector(registerFotPushNotifications) withObject:self afterDelay:PUSH_REGISTER_RETRY_TIMEOUT];
}

@end
