//
//  SpotPropertiesViewController.h
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SpotPropertiesViewController : UIViewController
@property (nonatomic) id caller;
@property (strong, nonatomic) id <UITableViewDataSource, UITableViewDelegate> tableViewDataSource;

@end
