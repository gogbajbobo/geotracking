//
//  TrackerManagedDocument.h
//  geotracking
//
//  Created by Maxim Grigoriev on 12/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface TrackerManagedDocument : UIManagedDocument
@property(nonatomic, strong, readonly) NSManagedObjectModel *myManagedObjectModel;

@end
