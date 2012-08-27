//
//  CoreDataController.m
//  geotracking
//
//  Created by Григорьев Максим on 8/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "CoreDataController.h"

@implementation CoreDataController

- (NSManagedObjectContext *) managedObjectContext {
    
    if (!managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
        if (coordinator !=nil) {
            //            NSLog(@"NSManagedObjectContext alloc init");
            //            NSLog(@"NSManagedObjectModel %@",coordinator.managedObjectModel);
            managedObjectContext = [[NSManagedObjectContext alloc] init];
            [managedObjectContext setPersistentStoreCoordinator: coordinator];
        }
    }
    return managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel {
	
    if (!managedObjectModel) managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    return managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (!persistentStoreCoordinator) {
        NSURL *storeUrl = [self applicationDocumentsDirectory];

        NSFileManager *fileManager = [NSFileManager defaultManager];
        if (![fileManager fileExistsAtPath:[storeUrl path]]) {
            NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:@"geoTracker" ofType:@"sqlite"];
//            NSLog(@"defaultStorePath %@",defaultStorePath);
            if (defaultStorePath) {
                [fileManager copyItemAtPath:defaultStorePath toPath:[storeUrl path] error:NULL];
            }
        }
        
        NSError *error;
        persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
        if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
            NSLog(@"persistentStoreCoordinator error %@", error.localizedDescription);        
        }    
    }
    
    return persistentStoreCoordinator;
}

- (NSURL *)applicationDocumentsDirectory {
	
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    url = [url URLByAppendingPathComponent:@"geoTracker.sqlite"];
//    NSLog(@"url %@",url);
    return url;
}

//- (IBAction)saveAction:(id)sender {
//	
//    NSError *error;
//    if (![[self managedObjectContext] save:&error]) {
//		NSLog(@"[managedObjectContext save:&error] %@", error.localizedDescription);
//    }
//}

@end
