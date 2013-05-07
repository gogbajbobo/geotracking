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

#define TOKEN_SERVER_URL @"system.unact.ru"
#define AUTH_SERVICE_URI @"https://uoauth.unact.ru/a/UPushAuth/"
#define AUTH_SERVICE_PARAMETERS @"_host=hqvsrv73&app_id=geotracking-dev&_svc=a/UPushAuth/"
//#define AUTH_SERVICE_PARAMETERS @""

@interface STGTAuthBasic()

@end

@implementation STGTAuthBasic

- (NSString *) reachabilityServer{
//    return [STGTAuthBasic settings].tokenServerURL;
    return TOKEN_SERVER_URL;
}

- (void) tokenReceived:(UDAuthToken *) token{
    [super tokenReceived:token];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"tokenReceived" object:self];
}

//+ (STGTSettings *)settings {
//    return [STGTTrackingLocationController sharedTracker].settings;
//}

+ (id) tokenRetrieverMaker{
    
    UDAuthTokenRetriever *tokenRetriever = [[UDAuthTokenRetriever alloc] init];
//    tokenRetriever.authServiceURI = [NSURL URLWithString:[self settings].authServiceURI];
    tokenRetriever.authServiceURI = [NSURL URLWithString:AUTH_SERVICE_URI];
    
    UDPushAuthCodeRetriever *codeRetriever = [UDPushAuthCodeRetriever codeRetriever];
//    codeRetriever.requestDelegate.uPushAuthServiceURI = [NSURL URLWithString:[self settings].authServiceURI];
    codeRetriever.requestDelegate.uPushAuthServiceURI = [NSURL URLWithString:AUTH_SERVICE_URI];
    
#if DEBUG
//    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:@"_host=hqvsrv73&app_id=geotracking-dev&_svc=a/UPushAuth/"];
//    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:[self settings].authServiceParameters];
    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:AUTH_SERVICE_PARAMETERS];

#else
//    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:@"_host=hqvsrv73&app_id=geotracking&_svc=a/UPushAuth/"];
//    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:[[self settings].authServiceParameters stringByReplacingOccurrencesOfString:@"-dev" withString:@""]];
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
