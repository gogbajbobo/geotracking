//
//  STGTDatum.h
//  geotracking
//
//  Created by Maxim Grigoriev on 2/6/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface STGTDatum : NSManagedObject

@property (nonatomic, retain) NSDate * cts;
@property (nonatomic, retain) NSDate * lts;
@property (nonatomic, retain) NSDate * sqts;
@property (nonatomic, retain) NSDate * ts;
@property (nonatomic, retain) NSString * xid;

@end
