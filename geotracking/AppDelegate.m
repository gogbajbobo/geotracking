//
//  AppDelegate.m
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.syncer = [[DataSyncController alloc] init];
    self.tracker = [[TrackingLocationController alloc] init];
    [self.syncer startSyncer];
//    NSLog(@"self.syncer %@", self.syncer);
//    NSLog(@"self.tracker %@", self.tracker);
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.syncer stopSyncer];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
    
    self.pushNotificatonCenter = [UDPushNotificationCenter sharedPushNotificationCenter];
    self.authCodeRetriever = [UDPushAuthCodeRetriever codeRetriever];
    
    [UDOAuthBasic sharedOAuth];
    
    // allocate a reachability object
    self.reachability = [Reachability reachabilityWithHostname:@"system.unact.ru"];
    self.reachability.reachableOnWWAN = YES;
    
    [self.reachability startNotifier];
    
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
