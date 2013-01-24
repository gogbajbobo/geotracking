//
//  STGTAuthBasic.h
//  geotracking
//
//  Created by Maxim Grigoriev on 1/24/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <UDPushAuth/UDOAuthBasicAbstract.h>
#import "STGTRequestAuthenticatable.h"

@interface STGTAuthBasic : UDOAuthBasicAbstract <STGTRequestAuthenticatable>

- (NSString *) reachabilityServer;

+ (id) tokenRetrieverMaker;

@end
