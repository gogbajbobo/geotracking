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

- (void)awakeFromInsert {

//    NSLog(@"awakeFromInsert");

    [self setPrimitiveValue:[[STGTTrackingLocationController sharedTracker] newid] forKey:@"xid"];

    NSDate *ts = [NSDate date];
    
    [self setPrimitiveValue:ts forKey:@"cts"];

}

- (void)willSave {
    
//    NSLog(@"STGTDatum willSave");
    
//    NSLog(@"[self changedValues] %@", [self changedValues]);
    
    if (![[[self changedValues] allKeys] containsObject:@"lts"]) {

        NSDate *ts = [NSDate date];
        
        [self setPrimitiveValue:ts forKey:@"ts"];
        
        NSDate *sqts = [self primitiveValueForKey:@"lts"] ? [self primitiveValueForKey:@"ts"] : [self primitiveValueForKey:@"cts"];
        [self setPrimitiveValue:sqts forKey:@"sqts"];
        
        
    }
    
    [super willSave];
}

@end
