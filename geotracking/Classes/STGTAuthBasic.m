//
//  STGTAuthBasic.m
//  geotracking
//
//  Created by Maxim Grigoriev on 1/24/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTAuthBasic.h"
#import <UDPushAuth/UDAuthTokenRetriever.h>
#import <UDPushAuth/UDPushAuthCodeRetriever.h>
#import <UDPushAuth/UDPushAuthRequestBasic.h>
#import "STGTSettingsController.h"
#import "STGTSettings.h"
#import "STGTTrackingLocationController.h"

#define AUTH_SERVICE_URI @"https://system.unact.ru/asa"
#define AUTH_SERVICE_PARAMETERS @"_host=hqvsrv73&app_id=geotracking-dev&_svc=a/UPushAuth/"

@interface STGTAuthBasic()
@property (nonatomic, strong) STGTSettings *settings;

@end


@implementation STGTAuthBasic

- (STGTSettings *)settings {
    if (!_settings) {
        _settings = [STGTTrackingLocationController sharedTracker].settings;
    }
    return _settings;
}

- (NSString *) reachabilityServer{
    return self.settings.tokenServerURL;
}

- (void) tokenReceived:(UDAuthToken *) token{
//    if (token != nil && token != self.authToken) {
//        self.authToken = token;
//        
//        NSLog(@"Token Received with ttl: %f",self.authToken.ttl);
//    }
}

+ (id) tokenRetrieverMaker{
    
    UDAuthTokenRetriever *tokenRetriever = [[UDAuthTokenRetriever alloc] init];
    tokenRetriever.authServiceURI = [NSURL URLWithString:AUTH_SERVICE_URI];
    
    UDPushAuthCodeRetriever *codeRetriever = [UDPushAuthCodeRetriever codeRetriever];
    codeRetriever.requestDelegate.uPushAuthServiceURI = [NSURL URLWithString:AUTH_SERVICE_URI];
#if DEBUG
//    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:@"_host=hqvsrv73&app_id=geotracking-dev&_svc=a/UPushAuth/"];
    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:AUTH_SERVICE_PARAMETERS];
#else
//    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:@"_host=hqvsrv73&app_id=geotracking&_svc=a/UPushAuth/"];
    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:[AUTH_SERVICE_PARAMETERS stringByReplacingOccurrencesOfString:@"-dev" withString:@""]];
#endif
    tokenRetriever.codeDelegate = codeRetriever;
        
    return tokenRetriever;
}

- (NSURLRequest *) authenticateRequest:(NSURLRequest *)request{
    NSMutableURLRequest *resultingRequest = nil;
    
    if (self.tokenValue != nil) {
        resultingRequest = [request mutableCopy];
        [resultingRequest addValue:[NSString stringWithFormat:@"Bearer %@",self.tokenValue] forHTTPHeaderField:@"Authorization"];
    }
    
    return resultingRequest;
}



@end
