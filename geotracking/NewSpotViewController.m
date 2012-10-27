//
//  NewSpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 10/24/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "NewSpotViewController.h"
#import "SpotPropertiesViewController.h"

@interface NewSpotViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic) NSString *tableDataType;
@property (strong, nonatomic) NSMutableArray *tableData;

@end

@implementation NewSpotViewController


- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //        NSLog(@"NewSpot dismissViewControllerAnimated");
    }];
}

- (IBAction)editInterests:(id)sender {
    self.tableDataType = @"Interests";
    self.tableData = [[self.tracker interestsList] mutableCopy];
    NSLog(@"Interest array %@", self.tableData);
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (IBAction)editNetworks:(id)sender {
    self.tableDataType = @"Networks";
    self.tableData = [[self.tracker networkList] mutableCopy];
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
    if (tableView.editing) {
        return self.tableData.count + 1;
    } else {
        return self.tableData.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.tableDataType;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"spotProperty"];
    if (tableView.editing) {
        UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(40, 10, 250, 39)];
        textField.delegate = self;
        if (indexPath.row < self.tableData.count) {
            textField.text = [self.tableData objectAtIndex:indexPath.row];
            textField.placeholder = @"Add new …";
        }
        [cell addSubview:textField];
    } else {
        cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
    }
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.tableData.count) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        NSLog(@"UITableViewCellEditingStyleInsert");
        if (tableView.editing) {
            NSLog(@"tableView.editing");
            [self.tableData addObject:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
            [tableView reloadData];
        }
    }
}


- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ([textField.superview isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)textField.superview;
        cell.textLabel.text = textField.text;
    }
    return YES;
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
