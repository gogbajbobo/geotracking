//
//  STGTSessionManager.h
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STGTGeoTrackable.h"
#import "STGTSession.h"

@interface STGTSessionManager : NSObject <STGTSessionManager, STGTSessionManagement>

@property (nonatomic, strong) STGTSession *currentSession;
@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, strong) NSString *currentSessionUID;

- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id)authDelegate;
- (void)stopSessionForUID:(NSString *)uid;
- (void)sessionCompletionFinished:(id)sender;
- (void)cleanCompleteSessions;

+ (STGTSessionManager *)sharedManager;

@end
