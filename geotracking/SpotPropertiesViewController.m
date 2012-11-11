//
//  SpotPropertiesViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "SpotPropertiesViewController.h"
#import "SpotViewController.h"
#import "SpotProperty.h"

@interface SpotPropertiesViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITextField *activeTextField;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@end

@implementation SpotPropertiesViewController

- (void)keyboardNotificationsRegistration
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    NSLog(@"keyboardSize.height %f, keyboardSize.width %f", keyboardSize.height, keyboardSize.width);
//    NSLog(@"self.tableView.contentInset.top %f, self.tableView.contentInset.left %f, self.tableView.contentInset.bottom %f, self.tableView.contentInset.right %f", self.tableView.contentInset.top, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right);
    
    CGFloat heightShift = keyboardSize.height - self.toolbar.frame.size.height;
    NSLog(@"heightShift %f", heightShift);
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, heightShift, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;

//    NSLog(@"self.tableView.contentInset.top %f, self.tableView.contentInset.left %f, self.tableView.contentInset.bottom %f, self.tableView.contentInset.right %f", self.tableView.contentInset.top, self.tableView.contentInset.left, self.tableView.contentInset.bottom, self.tableView.contentInset.right);
    
    CGRect rect = self.tableView.bounds;
    rect.size.height -= heightShift;
    CGRect textFieldFrame = self.activeTextField.superview.superview.frame;
    NSLog(@"rect.origin.x %f, rect.origin.y %f, rect.size.height %f, rect.size.width %f", rect.origin.x, rect.origin.y, rect.size.height, rect.size.width);
    if (!CGRectContainsPoint(rect, textFieldFrame.origin) ) {
        NSLog(@"HERE!");
        CGPoint scrollPoint = CGPointMake(0.0, textFieldFrame.origin.y + textFieldFrame.size.height - heightShift);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;    
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //        NSLog(@"NewSpot dismissViewControllerAnimated");
    }];
}

- (IBAction)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    [self.tableView reloadData];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    SpotViewController *spotVC;
    if ([self.caller isKindOfClass:[SpotViewController class]]) {
        spotVC = self.caller;
    }
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
        NSLog(@"textFieldShouldEndEditing");
        UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
        cell.selected = NO;
        if ([cell.superview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)cell.superview;
            //            NSLog(@"[tableView numberOfRowsInSection:0] %d", [tableView numberOfRowsInSection:0]);
            //            NSLog(@"[tableView indexPathForCell:cell].row %d", [tableView indexPathForCell:cell].row);
            if ([tableView indexPathForCell:cell].row == [tableView numberOfRowsInSection:0] - 1) {
                //                NSLog(@"Last row");
                if (![textField.text isEqualToString:@""]) {
                    //                    NSLog(@"addNewPropertyWithName");
                    [spotVC addNewPropertyWithName:textField.text];
                    textField.text = nil;
                } else {
                    NSLog(@"textField.text isEqualToString:@\"\"");
                }
            } else {
                NSLog(@"Not last row");
                if (![textField.text isEqualToString:cell.textLabel.text]) {
                    if ([textField.text isEqualToString:@""]) {
                        textField.text = cell.textLabel.text;
                    } else {
                        SpotProperty *spotProperty = (SpotProperty *)[spotVC.resultsController.fetchedObjects objectAtIndex:[tableView indexPathForCell:cell].row];
                        spotProperty.name = textField.text;
                        cell.textLabel.text = textField.text;
                        [textField resignFirstResponder];
                        [spotVC.tracker.locationsDatabase saveToURL:spotVC.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                            NSLog(@"updateObject UIDocumentSaveForOverwriting success");
                        }];
                    }
                }
            }
        }
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    //    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
    //        NSLog(@"textFieldShouldReturn");
    //        UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
    //        if ([cell.superview isKindOfClass:[UITableView class]]) {
    //            UITableView *tableView = (UITableView *)cell.superview;
    //            if ([tableView indexPathForCell:cell].row == [tableView numberOfRowsInSection:0] - 1) {
    //                NSLog(@"Last row");
    //                if (![textField.text isEqualToString:@""]) {
    //                    NSLog(@"addNewPropertyWithName");
    //                    [self addNewPropertyWithName:textField.text];
    //                    textField.text = nil;
    //                } else {
    //                    NSLog(@"textField.text isEqualToString:@\"\"");
    //                }
    //            } else {
    //            }
    //        }
    //    }
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

- (void)viewDidLoad
{
    [super viewDidLoad];
//    NSLog(@"self.tableView %@", self.tableView);
    self.tableView.dataSource = self.tableViewDataSource;
    self.tableView.delegate = self.tableViewDataSource;
    if ([self.caller isKindOfClass:[SpotViewController class]]) {
        SpotViewController *caller = self.caller;
        caller.tableView = self.tableView;
    }
    [self keyboardNotificationsRegistration];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setTableView:nil];
    [super viewDidUnload];
}
@end
