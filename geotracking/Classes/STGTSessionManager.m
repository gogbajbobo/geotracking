//
//  STGTSessionManager.m
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSessionManager.h"

@interface STGTSessionManager()

@end

@implementation STGTSessionManager

- (NSMutableDictionary *)sessions {
    if (!_sessions) {
        _sessions = [NSMutableDictionary dictionary];
    }
    return _sessions;
}

- (STGTSession *)currentSession {
    return [self.sessions objectForKey:self.currentSessionUID];
}

- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id <STGTRequestAuthenticatable>)authDelegate {
    STGTSession *session = [self.sessions objectForKey:uid];
    if (!session) {
        session = [[STGTSession alloc] initWithUID:uid AuthDelegate:authDelegate];
        session.manager = self;
        [self.sessions setValue:session forKey:uid];
    } else {
        session.syncer.authDelegate = authDelegate;
        if (![session.status isEqualToString:@"running"]) {
            [session.tracker trackerInit];
        }
    }
    session.status = @"running";
    self.currentSessionUID = uid;
}

- (void)stopSessionForUID:(NSString *)uid {
    STGTSession *session = [self.sessions objectForKey:uid];
    session.status = @"finishing";
    [session completeSession];
    self.currentSessionUID = nil;
}

- (void)sessionCompletionFinished:(id)sender {
    if ([[(STGTSession *)sender uid] isEqualToString:self.currentSessionUID]) {
        self.currentSessionUID = nil;
    }
    [[self.sessions objectForKey:[(STGTSession *)sender uid]] setStatus:@"completed"];
//    [self.sessions removeObjectForKey:[(STGTSession *)sender uid]];
}

- (void)setCurrentSessionUID:(NSString *)currentSessionUID {
    if ([[self.sessions allKeys] containsObject:currentSessionUID] || !currentSessionUID) {
        if (_currentSessionUID != currentSessionUID) {
            _currentSessionUID = currentSessionUID;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentSessionChange" object:[self.sessions objectForKey:_currentSessionUID]];
        }
    }
}

- (void)cleanCompleteSessions {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.status == %@", @"completed"];
    NSArray *completedSessions = [[self.sessions allValues] filteredArrayUsingPredicate:predicate];
    for (STGTSession *session in completedSessions) {
        [self.sessions removeObjectForKey:session.uid];
    }
}

+ (STGTSessionManager *)sharedManager {
    static dispatch_once_t pred = 0;
    __strong static id _sharedManager = nil;
    dispatch_once(&pred, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}


@end
