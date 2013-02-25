//
//  STGTGeoTrackable.h
//  geotracking
//
//  Created by kovtash on 25.02.13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <CoreLocation/CoreLocation.h>
#import "STGTDataSyncController.h"

@protocol STGTSession <NSObject> // не подлежит реализации
    - (void) initWithUID:(NSString *) uid AuthDelegate(id) authDelegate;
    - (void) completeSession()
@end

@protocol STGTSessionManagement <NSObject>
    - (void) startSessionForUID:(NSString *) uid AuthDelegate(id) authDelegate;
    - (void) stopCurrentSession;
@end

@protocol STGTSessionManager <NSObject>
    - (void) sessionCompletionFinished:(id) sender;
@end

@protocol STGTManagedSession <STGTSession>
    @property (weak,nonatomic) id <STGTSessionManager> manager;
@end

@interface STGTSession : NSObject <STGTManagedSession>
    @property (strong,nonatomic) STGTLocationManagedDocument *locationManagedDocument;
    @property (strong,nonatomic) CLLocationManager *locationManager;
    @property (strong,nonatomic) STGTDataSyncController *syncController;
@end