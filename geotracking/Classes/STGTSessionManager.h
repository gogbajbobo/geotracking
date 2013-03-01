//
//  STGTSessionManager.h
//  geotracking
//
//  Created by Maxim Grigoriev on 3/1/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STGTSessionManager : NSObject

- (void)startSessionForUID:(NSString *)uid AuthDelegate:(id)authDelegate;
- (void)stopCurrentSession;
- (void)sessionCompletionFinished:(id)sender;

+ (STGTSessionManager *)sharedManager;

@end
