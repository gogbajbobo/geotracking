//
//  STGTSettingsController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 1/24/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "STGTSettings.h"

@interface STGTSettingsController : NSObject

@property (nonatomic, strong) STGTSettings *settings;

+ (NSDictionary *)defaultSettings;

@end
