//
//  STGTSessionManager.h
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STGTSession.h"

@interface STGTSessionManager : NSObject

@property (nonatomic, strong) STGTSession *currentSession;

- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id)authDelegate;
- (void)stopCurrentSession;
- (void)sessionCompletionFinished:(id)sender;

+ (STGTSessionManager *)sharedManager;

@end
