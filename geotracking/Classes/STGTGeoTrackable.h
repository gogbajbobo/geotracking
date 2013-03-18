//
//  STGTGeoTrackable.h
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>

//@protocol STGTGeoTrackable <NSObject>
//
//@end

@protocol STGTSessionManager <NSObject>

- (void)sessionCompletionFinished:(id)sender;

@end


@protocol STGTSessionManagement <NSObject>

- (void)startSessionForUID:(NSString *) uid AuthDelegate:(id)authDelegate;
- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id)authDelegate settings:(NSDictionary *)settings;
- (void)stopSessionForUID:(NSString *)uid;

@end


@protocol STGTSession <NSObject>

- (id)initWithUID:(NSString *) uid AuthDelegate:(id)authDelegate;
- (id)initWithUID:(NSString *)uid AuthDelegate:(id)authDelegate settings:(NSDictionary *)settings;
- (void) completeSession;

@end


@protocol STGTManagedSession <STGTSession>

@property (weak,nonatomic) id <STGTSessionManager> manager;

@end
