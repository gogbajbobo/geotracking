//
//  SpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "SpotViewController.h"
#import "SpotPropertiesViewController.h"
#import "Spot.h"
#import "SpotProperty.h"
#import "Track.h"

@interface SpotViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, NSFetchedResultsControllerDelegate>
@property (nonatomic, strong) NSString *typeOfProperty;
@property (weak, nonatomic) IBOutlet UILabel *spotInfo;
@property (weak, nonatomic) IBOutlet UITextField *spotLabel;


@end

@implementation SpotViewController


- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SpotProperty"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", self.typeOfProperty];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.tracker.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _resultsController.delegate = self;
    }
//    NSLog(@"self.tracker.locationsDatabase.managedObjectContext %@", self.tracker.locationsDatabase.managedObjectContext);
//    NSLog(@"self.resultsController.fetchedObjects %@", _resultsController.fetchedObjects);
//    NSLog(@"self.tracker.locationsDatabase.managedObjectContext.registeredObjects %@", self.tracker.locationsDatabase.managedObjectContext.registeredObjects);
//    NSLog(@"self.tracker.locationsDatabase.managedObjectModel %@", self.tracker.locationsDatabase.managedObjectModel);
    return _resultsController;
}

- (void)performFetch {
    if (self.resultsController) {
        self.resultsController.delegate = nil;
        self.resultsController = nil;
    }
    NSError *error;
    if (![self.resultsController performFetch:&error]) {
        NSLog(@"performFetch error %@", error.localizedDescription);
    } else {
        if (self.resultsController.fetchedObjects.count > 0) {
//            self.currentTrack = [self.resultsController.fetchedObjects objectAtIndex:0];
        }
//        [self.tableView reloadData];
    }
}

- (IBAction)doneButtonPressed:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        //        NSLog(@"NewSpot dismissViewControllerAnimated");
    }];
}

- (IBAction)editInterests:(id)sender {
    self.typeOfProperty = @"Interest";
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (IBAction)editNetworks:(id)sender {
    self.typeOfProperty = @"Network";
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (void)showSpotInfo {
    CLLocationDegrees longitude = self.userLocation.location.coordinate.longitude;
    CLLocationDegrees latitude = self.userLocation.location.coordinate.latitude;
    self.spotInfo.text = [NSString stringWithFormat:@"lon/lat %.2f/%.2f", longitude, latitude];
}

- (void)showSpotLabel {
    self.spotLabel.font = [UIFont boldSystemFontOfSize:20];
    self.spotLabel.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.spotLabel.returnKeyType = UIReturnKeyDone;
    self.spotLabel.tag = 1;
    self.spotLabel.delegate = self;
    self.spotLabel.placeholder = @"Spot label";
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[SpotPropertiesViewController class]]) {
        SpotPropertiesViewController *spotPropertiesVC = segue.destinationViewController;        
        if ([segue.identifier isEqualToString:@"showProperties"]) {
            [self performFetch];
            spotPropertiesVC.caller = self;
            spotPropertiesVC.tableViewDataSource = self;
        }
    }
    
}

- (void)addNewPropertyWithName:(NSString *)name {
    SpotProperty *newProperty = (SpotProperty *)[NSEntityDescription insertNewObjectForEntityForName:@"SpotProperty" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    [newProperty setXid:[self.tracker newid]];
    [newProperty setType:self.typeOfProperty];
    [newProperty setName:name];
//    NSLog(@"newProperty %@", newProperty);
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newProperty UIDocumentSaveForOverwriting success");
    }];
}

- (void)imageTap:(UITapGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        if (self.tableView.editing) {
            NSLog(@"imageTap");
        }
    }
}


#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
//    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
//    NSLog(@"[sectionInfo numberOfObjects] %d", [sectionInfo numberOfObjects]);
    if (tableView.editing) {
        return [sectionInfo numberOfObjects] + 1;
    } else {
        return [sectionInfo numberOfObjects];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@s", self.typeOfProperty];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"spotProperty"];
//    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    cell.textLabel.text = @"";
    UIView *viewToDelete = [cell.contentView viewWithTag:1];
    if (viewToDelete) [viewToDelete removeFromSuperview];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(54, 9, 270, 24)];
    textField.font = [UIFont boldSystemFontOfSize:20];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    textField.tag = 1;
    textField.delegate = self;
    textField.placeholder = [NSString stringWithFormat:@"%@ %@", @"Name of", self.typeOfProperty];
    textField.text = nil;
    if (indexPath.row != self.resultsController.fetchedObjects.count) {
        SpotProperty *spotProperty = (SpotProperty *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", spotProperty.name];
        textField.text = cell.textLabel.text;
    } else {
//        [textField becomeFirstResponder];
    }
    [cell.contentView addSubview:textField];
    [cell.textLabel setHidden:tableView.editing];
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [textField setHidden:!tableView.editing];

    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTap:)];
    [cell.imageView addGestureRecognizer:imageTap];

    return cell;
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.editing) {
        if (indexPath.row == self.resultsController.fetchedObjects.count) {
            return UITableViewCellEditingStyleInsert;
        } else {
            return UITableViewCellEditingStyleDelete;
        }
    } else {
        return UITableViewCellEditingStyleNone;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleInsert) {
//        NSLog(@"UITableViewCellEditingStyleInsert");
        if (tableView.editing) {
            UITextField *textField = (UITextField *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:1];
            if (![textField.text isEqualToString:@""]) {
                NSLog(@"addNewPropertyWithName");
                [self addNewPropertyWithName:textField.text];
                textField.text = nil;
            } else {
                NSLog(@"textField.text isEqualToString:@\"\"");
            }
        }
    } else if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.tracker.locationsDatabase.managedObjectContext deleteObject:[self.resultsController.fetchedObjects objectAtIndex:indexPath.row]];
        [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"deleteObject UIDocumentSaveForOverwriting success");
        }];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
//        NSLog(@"textFieldShouldEndEditing");
        UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
        if ([cell.superview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)cell.superview;
//            NSLog(@"[tableView numberOfRowsInSection:0] %d", [tableView numberOfRowsInSection:0]);
//            NSLog(@"[tableView indexPathForCell:cell].row %d", [tableView indexPathForCell:cell].row);
            if ([tableView indexPathForCell:cell].row == [tableView numberOfRowsInSection:0] - 1) {
//                NSLog(@"Last row");
                if (![textField.text isEqualToString:@""]) {
//                    NSLog(@"addNewPropertyWithName");
                    [self addNewPropertyWithName:textField.text];
                    textField.text = nil;
                } else {
                    NSLog(@"textField.text isEqualToString:@\"\"");
                }
            } else {
//                NSLog(@"Not last row");
                if (![textField.text isEqualToString:cell.textLabel.text]) {
                    if ([textField.text isEqualToString:@""]) {
                        textField.text = cell.textLabel.text;
                    } else {
                        SpotProperty *spotProperty = (SpotProperty *)[self.resultsController.fetchedObjects objectAtIndex:[tableView indexPathForCell:cell].row];
                        spotProperty.name = textField.text;
                        cell.textLabel.text = textField.text;
                        [textField resignFirstResponder];
                        [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
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
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - NSFetchedResultsController delegate


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
//    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
        
//        NSLog(@"NSFetchedResultsChangeDelete");
//        NSLog(@"indexPath %@", indexPath);
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
    } else if (type == NSFetchedResultsChangeInsert) {
        
//        NSLog(@"NSFetchedResultsChangeInsert");
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
    } else if (type == NSFetchedResultsChangeUpdate) {
        
//        NSLog(@"NSFetchedResultsChangeUpdate");
// reloadRowsAtIndexPaths causes strange error don't know why
//        [self.tableView reloadData];
//        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
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
    [self showSpotInfo];
    [self showSpotLabel];
//    NSLog(@"spotVC self.tracker %@", self.tracker);
//    self.tableData = [NSMutableArray arrayWithObjects:@"Test1", nil];
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

- (void)viewDidUnload {
    [self setSpotInfo:nil];
    [self setSpotLabel:nil];
    [super viewDidUnload];
}

@end
