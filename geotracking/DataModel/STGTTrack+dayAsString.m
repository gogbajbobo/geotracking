//
//  STGTTrack+dayAsString.m
//  geotracking
//
//  Created by Maxim Grigoriev on 2/14/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTTrack+dayAsString.h"

@implementation STGTTrack (dayAsString)

- (NSString *)dayAsString {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy/MM/dd";
    });
    
    NSString *dateString;
    if (self.finishTime) {
        dateString = [formatter stringFromDate:self.finishTime];
    } else {
        dateString = [formatter stringFromDate:self.startTime];
    }
    return dateString;
}

@end
