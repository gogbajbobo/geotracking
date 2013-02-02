//
//  AppDelegate.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTAppDelegate.h"

@implementation STGTAppDelegate

@synthesize window = _window;


- (void)applicationWillTerminate:(UIApplication *)application {

}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];

    [STGTTrackingLocationController sharedTracker];
    
    self.pushNotificatonCenter = [UDPushNotificationCenter sharedPushNotificationCenter];
    self.authCodeRetriever = (UDPushAuthCodeRetriever *)[(UDAuthTokenRetriever *)[[STGTAuthBasic sharedOAuth] tokenRetriever] codeDelegate];
    self.reachability = [Reachability reachabilityWithHostname:[[STGTAuthBasic sharedOAuth] reachabilityServer]];
    self.reachability.reachableOnWWAN = YES;
    [self.reachability startNotifier];

//    [[STGTDataSyncController sharedSyncer] setAuthDelegate:[STGTAuthBasic sharedOAuth]];
    
    
//    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
//    
//    self.pushNotificatonCenter = [UDPushNotificationCenter sharedPushNotificationCenter];
//    self.authCodeRetriever = [UDPushAuthCodeRetriever codeRetriever];
//    
//    [STGTAuthBasic sharedOAuth];
//    
//    [STGTTrackingLocationController sharedTracker];
//
//    // allocate a reachability object
//    self.reachability = [Reachability reachabilityWithHostname:@"system.unact.ru"];
//    self.reachability.reachableOnWWAN = YES;
//    
//    [self.reachability startNotifier];
    
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


@end
