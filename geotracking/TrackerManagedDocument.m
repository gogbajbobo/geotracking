//
//  TrackerManagedDocument.m
//  geotracking
//
//  Created by Maxim Grigoriev on 12/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "TrackerManagedDocument.h"

@implementation TrackerManagedDocument
@synthesize myManagedObjectModel = _myManagedObjectModel;

- (NSManagedObjectModel *)myManagedObjectModel {
    if (!_myManagedObjectModel) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Tracker" ofType:@"mom"];
        NSURL *momURL = [NSURL fileURLWithPath:path];
        _myManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
    }
    return _myManagedObjectModel;
}

- (NSManagedObjectModel *)managedObjectModel {
    return self.myManagedObjectModel;
}

@end
