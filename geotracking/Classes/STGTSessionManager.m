//
//  STGTSessionManager.m
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSessionManager.h"
#import "STGTSession.h"

@interface STGTSessionManager()

@property (nonatomic, strong) NSMutableDictionary *sessions;
@property (nonatomic, strong) NSString *currentSessionUID;

@end

@implementation STGTSessionManager


- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id)authDelegate {
    STGTSession *session = [[STGTSession alloc] initWithUID:uid AuthDelegate:authDelegate];
    [self.sessions setValue:session forKey:uid];
    self.currentSessionUID = uid;
}

- (void)stopCurrentSession {
    [[self.sessions objectForKey:self.currentSessionUID] completeSession];
}

- (void)sessionCompletionFinished:(id)sender {
    [self.sessions removeObjectForKey:[(STGTSession *)sender uid]];
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
