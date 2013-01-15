//
//  TrackerManagedDocument.m
//  geotracking
//
//  Created by Maxim Grigoriev on 12/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTTrackerManagedDocument.h"

@implementation STGTTrackerManagedDocument
@synthesize myManagedObjectModel = _myManagedObjectModel;

- (NSManagedObjectModel *)myManagedObjectModel {
    if (!_myManagedObjectModel) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"STGTTracker" ofType:@"momd"];
        if (!path) {
            path = [[NSBundle mainBundle] pathForResource:@"STGTTracker" ofType:@"mom"];
        }
//        NSLog(@"path %@", path);
        NSURL *url = [NSURL fileURLWithPath:path];
//        NSLog(@"url %@", url);
        _myManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
    }
    return _myManagedObjectModel;
}

- (NSManagedObjectModel *)managedObjectModel {
    return self.myManagedObjectModel;
}

@end
