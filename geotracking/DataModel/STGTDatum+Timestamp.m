//
//  STGTDatum+Timestamp.m
//  geotracking
//
//  Created by Maxim Grigoriev on 1/22/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTDatum+Timestamp.h"
#import "STGTTrackingLocationController.h"

@implementation STGTDatum (Timestamp)

- (void)willSave {
    
//    NSLog(@"STGTDatum willSave");
    
//    NSLog(@"[self changedValues] %@", [self changedValues]);
    
    if (![[[self changedValues] allKeys] containsObject:@"lts"]) {

        NSDate *ts = [NSDate date];
        
        [self setPrimitiveValue:ts forKey:@"ts"];
        
        if (![self primitiveValueForKey:@"cts"])
            [self setPrimitiveValue:ts forKey:@"cts"];
        
        NSDate *sqts = [self primitiveValueForKey:@"lts"] ? [self primitiveValueForKey:@"ts"] : [self primitiveValueForKey:@"cts"];
        [self setPrimitiveValue:sqts forKey:@"sqts"];
        
        if (![self primitiveValueForKey:@"xid"])
            [self setPrimitiveValue:[[STGTTrackingLocationController sharedTracker] newid] forKey:@"xid"];
        
    }
    
    [super willSave];
}

@end
