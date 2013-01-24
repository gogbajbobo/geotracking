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


#define TOKEN_SERVER_URL @"system.unact.ru"
#define AUTH_SERVICE_URI @"https://system.unact.ru/asa"

@implementation STGTAuthBasic

- (NSString *) reachabilityServer{
    return TOKEN_SERVER_URL;
}

+ (id) tokenRetrieverMaker{
    UDAuthTokenRetriever *tokenRetriever = [[UDAuthTokenRetriever alloc] init];
    tokenRetriever.authServiceURI = [NSURL URLWithString:AUTH_SERVICE_URI];
    
    UDPushAuthCodeRetriever *codeRetriever = [UDPushAuthCodeRetriever codeRetriever];
    codeRetriever.requestDelegate.uPushAuthServiceURI = [NSURL URLWithString:AUTH_SERVICE_URI];
#if DEBUG
    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:@"_host=hqvsrv73&app_id=geotracking-dev&_svc=a/UPushAuth/"];
#else
    [(UDPushAuthRequestBasic *)[codeRetriever requestDelegate] setConstantGetParameters:@"_host=hqvsrv73&app_id=geotracking&_svc=a/UPushAuth/"];
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
