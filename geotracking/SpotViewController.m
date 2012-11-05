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
@property (strong, nonatomic) NSMutableArray *tableData;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) NSString *typeOfProperty;
@property (weak, nonatomic) IBOutlet UILabel *spotInfo;
@property (weak, nonatomic) IBOutlet UITextField *spotLabel;


@end

@implementation SpotViewController


- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SpotProperty"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(compare:)]];
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
    //    self.tableData = [[self.tracker interestsList] mutableCopy];
//    NSLog(@"Interest array %@", self.tableData);
    [self performSegueWithIdentifier:@"showProperties" sender:self];
}

- (IBAction)editNetworks:(id)sender {
    self.typeOfProperty = @"Network";
    //    self.tableData = [[self.tracker networkList] mutableCopy];
//    NSLog(@"Network array %@", self.tableData);
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
        //        NSLog(@"spotPropertiesVC %@", spotPropertiesVC);
        
        if ([segue.identifier isEqualToString:@"showProperties"]) {
            [self performFetch];
//            NSLog(@"segue.identifier isEqualToString:@\"showProperties\"");
//            self.tableView = spotPropertiesVC.tableView;
//            spotPropertiesVC.tableView = self.tableView;
//            NSLog(@"self.tableView %@", self.tableView);
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
    NSLog(@"newProperty %@", newProperty);
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newProperty UIDocumentSaveForOverwriting success");
        NSLog(@"self.resultsController.fetchedObjects %@", self.resultsController.fetchedObjects);
    }];
}

#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return [[self.resultsController sections] count];
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    NSLog(@"[sectionInfo numberOfObjects] %d", [sectionInfo numberOfObjects]);
    if (tableView.editing) {
        return [sectionInfo numberOfObjects] + 1;
//        return self.tableData.count + 1;
    } else {
        return [sectionInfo numberOfObjects];
//        return self.tableData.count;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@s", self.typeOfProperty];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"spotProperty"];
    cell.textLabel.text = @"";
    UIView *viewToDelete = [cell.contentView viewWithTag:1];
    if (viewToDelete) [viewToDelete removeFromSuperview];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(10, 9, 270, 24)];
    textField.font = [UIFont boldSystemFontOfSize:20];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    textField.tag = 1;
    textField.delegate = self;
    textField.placeholder = [NSString stringWithFormat:@"%@ %@", @"Name of", self.typeOfProperty];
    if (indexPath.row != self.resultsController.fetchedObjects.count) {
        SpotProperty *spotProperty = (SpotProperty *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", spotProperty.name];
        textField.text = cell.textLabel.text;
    }
    [cell.contentView addSubview:textField];
    [cell.textLabel setHidden:tableView.editing];
    [textField setHidden:!tableView.editing];
    return cell;
    
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == self.resultsController.fetchedObjects.count) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleInsert) {
        NSLog(@"UITableViewCellEditingStyleInsert");
        if (tableView.editing) {
            UITextField *textField = (UITextField *)[[tableView cellForRowAtIndexPath:indexPath].contentView viewWithTag:1];
            if (![textField.text isEqualToString:@""]) {
                NSLog(@"addNewPropertyWithName");
                [self addNewPropertyWithName:textField.text];
            } else {
                NSLog(@"textField.text isEqualToString:@\"\"");
            }
//            [self.tableData addObject:[tableView cellForRowAtIndexPath:indexPath].textLabel.text];
//            [tableView reloadData];
        }
    } else if (editingStyle == UITableViewCellEditingStyleDelete) {
//        [self.tableData removeObjectAtIndex:indexPath.row];
//        [tableView reloadData];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
        NSLog(@"textFieldDidEndEditing");
        UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
        if ([cell.superview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)cell.superview;
            if ([tableView indexPathForCell:cell].row == self.tableData.count) {
//                [self addNewPropertyWithName:textField.text];
//                [self.tableData addObject:textField.text];
            } else {
//                [self.tableData replaceObjectAtIndex:[tableView indexPathForCell:cell].row withObject:textField.text];
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
    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
        
//        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
//        [self updateInfoLabels];
        
    } else if (type == NSFetchedResultsChangeInsert) {
        
    NSLog(@"NSFetchedResultsChangeInsert");
        
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
    } else if (type == NSFetchedResultsChangeUpdate) {
        
    NSLog(@"NSFetchedResultsChangeUpdate");
        
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
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
