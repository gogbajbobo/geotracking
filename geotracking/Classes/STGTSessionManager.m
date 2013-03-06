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

- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id)authDelegate {
    STGTSession *session = [self.sessions objectForKey:uid];
    if (!session) {
        session = [[STGTSession alloc] initWithUID:uid AuthDelegate:authDelegate];
        session.manager = self;
        [self.sessions setValue:session forKey:uid];
    } else {
        
    }
    session.status = @"running";
    self.currentSessionUID = uid;
}

- (void)stopSessionForUID:(NSString *)uid {
    [[self.sessions objectForKey:uid] completeSession];
    self.currentSessionUID = nil;
}

- (void)sessionCompletionFinished:(id)sender {
    if ([[(STGTSession *)sender uid] isEqualToString:self.currentSessionUID]) {
        self.currentSessionUID = nil;
    }
    [[self.sessions objectForKey:[(STGTSession *)sender uid]] setStatus:@"complete"];
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


+ (STGTSessionManager *)sharedManager {
    static dispatch_once_t pred = 0;
    __strong static id _sharedManager = nil;
    dispatch_once(&pred, ^{
        _sharedManager = [[self alloc] init];
    });
    return _sharedManager;
}


@end
