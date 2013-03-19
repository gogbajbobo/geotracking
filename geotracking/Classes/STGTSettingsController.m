//
//  STGTSettingsController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 1/24/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSettingsController.h"
#import "STGTTrackingLocationController.h"

//#define STGT_TOKEN_SERVER_URL @"system.unact.ru"
//#define STGT_AUTH_SERVICE_URI @"https://system.unact.ru/asa"
//#define STGT_AUTH_SERVICE_PARAMETERS @"_host=hqvsrv73&app_id=geotracking-dev&_svc=a/UPushAuth/"

#define STGT_DESIRED_ACCURACY kCLLocationAccuracyNearestTenMeters
#define STGT_REQUIRED_ACCURACY 10.0
#define STGT_DISTANCE_FILTER 50.0
#define STGT_TIME_FILTER 10.0
#define STGT_TRACK_DETECTION_TIME 300.0
#define STGT_TRACKER_AUTOSTART NO
#define STGT_TRACKER_STARTTIME 9.0
#define STGT_TRACKER_FINISHTIME 18.0

#define STGT_MAP_HEADING MKUserTrackingModeNone
#define STGT_MAP_TYPE MKMapTypeStandard
#define STGT_TRACK_SCALE 2.0

#define STGT_FETCH_LIMIT 20
#define STGT_SYNC_INTERVAL 1800.0
#define STGT_SYNC_SERVER_URI @"https://oldcat.unact.ru/rc_unact_old/chest"
#define STGT_XML_NAMESPACE @"https://github.com/sys-team/ASA.chest"

#define STGT_BATTERY_CHECKING NO

#define STGT_LOCAL_ACCESS_TO_SETTINGS YES


@interface STGTSettingsController()

@end

@implementation STGTSettingsController


+ (NSDictionary *)defaultSettings {

    NSMutableDictionary *settings = [NSMutableDictionary dictionary];
//    [settings setValue:STGT_TOKEN_SERVER_URL forKey:@"tokenServerURL"];
//    [settings setValue:STGT_AUTH_SERVICE_URI forKey:@"authServiceURI"];
//    [settings setValue:STGT_AUTH_SERVICE_PARAMETERS forKey:@"authServiceParameters"];
    
    [settings setValue:[NSNumber numberWithDouble:STGT_DESIRED_ACCURACY] forKey:@"desiredAccuracy"];
    [settings setValue:[NSNumber numberWithDouble:STGT_REQUIRED_ACCURACY] forKey:@"requiredAccuracy"];
    [settings setValue:[NSNumber numberWithDouble:STGT_DISTANCE_FILTER] forKey:@"distanceFilter"];
    [settings setValue:[NSNumber numberWithDouble:STGT_TIME_FILTER] forKey:@"timeFilter"];
    [settings setValue:[NSNumber numberWithDouble:STGT_TRACK_DETECTION_TIME] forKey:@"trackDetectionTime"];
    [settings setValue:[NSNumber numberWithBool:STGT_TRACKER_AUTOSTART] forKey:@"trackerAutoStart"];
    [settings setValue:[NSNumber numberWithDouble:STGT_TRACKER_STARTTIME] forKey:@"trackerStartTime"];
    [settings setValue:[NSNumber numberWithDouble:STGT_TRACKER_FINISHTIME] forKey:@"trackerFinishTime"];
    
    [settings setValue:[NSNumber numberWithDouble:STGT_MAP_HEADING] forKey:@"mapHeading"];
    [settings setValue:[NSNumber numberWithDouble:STGT_MAP_TYPE] forKey:@"mapType"];
    [settings setValue:[NSNumber numberWithDouble:STGT_TRACK_SCALE] forKey:@"trackScale"];
    
    [settings setValue:[NSNumber numberWithInt:STGT_FETCH_LIMIT] forKey:@"fetchLimit"];
    [settings setValue:[NSNumber numberWithDouble:STGT_SYNC_INTERVAL] forKey:@"syncInterval"];
    [settings setValue:STGT_SYNC_SERVER_URI forKey:@"syncServerURI"];
    [settings setValue:STGT_XML_NAMESPACE forKey:@"xmlNamespace"];
    
    [settings setValue:[NSNumber numberWithBool:STGT_LOCAL_ACCESS_TO_SETTINGS] forKey:@"localAccessToSettings"];

    [settings setValue:[NSNumber numberWithBool:STGT_BATTERY_CHECKING] forKey:@"checkingBattery"];

    return [settings copy];
}


@end
