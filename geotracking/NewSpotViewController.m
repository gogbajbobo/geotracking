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
@property (strong, nonatomic) UITableView *tableView;
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
//    self.tableData = [[self.tracker interestsList] mutableCopy];
    NSLog(@"Interest array %@", self.tableData);
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (IBAction)editNetworks:(id)sender {
    self.tableDataType = @"Networks";
//    self.tableData = [[self.tracker networkList] mutableCopy];
    NSLog(@"Network array %@", self.tableData);
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[SpotPropertiesViewController class]]) {
        SpotPropertiesViewController *spotPropertiesVC = segue.destinationViewController;
//        NSLog(@"spotPropertiesVC %@", spotPropertiesVC);

        if ([segue.identifier isEqualToString:@"showProperties"]) {
//            NSLog(@"segue.identifier isEqualToString:@\"showProperties\"");
//            self.tableView = [[UITableView alloc] init];
//            spotPropertiesVC.tableView = self.tableView;
//            NSLog(@"self.tableView %@", self.tableView);
            spotPropertiesVC.tableViewDataSource = self;
        }
    }

}

#pragma mark - Table view data source & delegate

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
    UITextField *textField;
    if (![cell.contentView viewWithTag:1]) {
        textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 9, 270, 24)];
        textField.font = [UIFont boldSystemFontOfSize:20];
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.returnKeyType = UIReturnKeyDone;
        textField.tag = 1;
        textField.delegate = self;
    } else {
        textField = (UITextField *)[cell.contentView viewWithTag:1];
    }
    if (indexPath.row == self.tableData.count) {
        NSMutableString *placeholder = [self.tableDataType mutableCopy];
        [placeholder deleteCharactersInRange:NSMakeRange([placeholder length] - 1, 1)];
        textField.placeholder = [NSString stringWithFormat:@"%@ %@", @"Name of", placeholder];
    } else {
        cell.textLabel.text = [self.tableData objectAtIndex:indexPath.row];
        cell.textLabel.tag = 2;
        textField.text = cell.textLabel.text;
    }
    [cell.contentView addSubview:textField];
    [cell.textLabel setHidden:tableView.editing];
    [textField setHidden:!tableView.editing];
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
//        NSLog(@"UITableViewCellEditingStyleInsert");
        if (tableView.editing) {
//            NSLog(@"tableView.editing");
            [self.tableData addObject:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
            [tableView reloadData];
        }
    } else if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tableData removeObjectAtIndex:indexPath.row];
        [tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"HERE!");
//
//    if ([[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:1] isKindOfClass:[UITextField class]]) {
//        NSLog(@"HERE!");
//        UITextField *textField = (UITextField *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:1];
//        [self.tableData replaceObjectAtIndex:indexPath.row withObject:textField.text];
//    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    NSLog(@"textField.superview.superview %@", textField.superview.superview);
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
        NSLog(@"textFieldDidEndEditing");
        UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
        cell.textLabel.text = textField.text;
        if ([cell.superview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)cell.superview;
            if ([tableView indexPathForCell:cell].row == self.tableData.count) {
                [self.tableData addObject:textField.text];
            }
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - view lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    self.tableData = [NSMutableArray arrayWithObjects:@"Test1", nil];
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
