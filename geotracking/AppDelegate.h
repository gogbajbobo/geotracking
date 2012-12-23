//
//  AppDelegate.h
//  geotracking
//
//  Created by Григорьев Максим on 8/21/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataSyncController.h"
#import "TrackingLocationController.h"
#import "UDPushNotificationCenter.h"
#import "UDPushAuthCodeRetriever.h"
#import "UDAuthTokenRetriever.h"
#import "UDOAuthBasic.h"
#import "Reachability.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, strong) DataSyncController *syncer;
@property (nonatomic, strong) TrackingLocationController *tracker;
@property (strong, nonatomic) UDPushNotificationCenter *pushNotificatonCenter;
@property (strong, nonatomic) UDPushAuthCodeRetriever *authCodeRetriever;
@property (strong, nonatomic) Reachability *reachability;
@end
