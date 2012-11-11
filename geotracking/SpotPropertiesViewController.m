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
    CGFloat heightShift = keyboardSize.height - self.toolbar.frame.size.height;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, heightShift, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    CGRect rect = self.tableView.bounds;
    rect.size.height -= heightShift;
    CGRect textFieldFrame = [self firstResponderCellFrame];
    if (!CGRectContainsPoint(rect, CGPointMake(0.0, textFieldFrame.origin.y + textFieldFrame.size.height))) {
        CGPoint scrollPoint = CGPointMake(0.0, textFieldFrame.origin.y + textFieldFrame.size.height - heightShift);
        [self.tableView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;    
}

- (CGRect)firstResponderCellFrame {
    CGRect frame;
    for (UIView *subview in self.tableView.subviews) {
        if ([subview isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)subview;
            if ([[cell.contentView viewWithTag:1] isFirstResponder]) {
                frame = cell.frame;
            }
        }
    }
    return frame;
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
//    self.tableView.allowsSelectionDuringEditing = NO;
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
