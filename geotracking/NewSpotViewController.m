//
//  NewSpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 10/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "NewSpotViewController.h"
#import "SpotPropertiesViewController.h"

@interface NewSpotViewController () <UITableViewDataSource>
@property (strong, nonatomic) NSString *tableDataType;
@property (strong, nonatomic) NSArray *tableData;

@end

@implementation NewSpotViewController

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //        NSLog(@"NewSpot dismissViewControllerAnimated");
    }];
}

- (IBAction)editInterests:(id)sender {
    self.tableDataType = @"Interests";
    self.tableData = [self.tracker interestsList];
    NSLog(@"Interest array %@", self.tableData);
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (IBAction)editNetworks:(id)sender {
    self.tableDataType = @"Networks";
    self.tableData = [self.tracker networkList];
    NSLog(@"Network array %@", self.tableData);
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[SpotPropertiesViewController class]]) {
        SpotPropertiesViewController *spotPropertiesVC = segue.destinationViewController;
//        NSLog(@"spotPropertiesVC %@", spotPropertiesVC);

        if ([segue.identifier isEqualToString:@"showProperties"]) {
//            NSLog(@"segue.identifier isEqualToString:@\"showProperties\"");
            spotPropertiesVC.tableViewDataSource = self;
        }
    }

}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableData.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    if (indexPath.row < self.tableData.count) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"spotProperty"];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"newProperty"];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.tableDataType;
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
