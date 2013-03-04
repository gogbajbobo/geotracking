//
//  SpotPropertiesViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 10/25/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSpotPropertiesViewController.h"
#import "STGTDataSyncController.h"
#import "STGTInterest.h"
#import "STGTInterestImage.h"
#import "STGTNetwork.h"
#import "STGTNetworkImage.h"

@interface STGTSpotPropertiesViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITextField *activeTextField;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIImageView *tappedImageView;
//@property (nonatomic, strong) STGTDataSyncController *syncer;

@end

@implementation STGTSpotPropertiesViewController

//- (STGTDataSyncController *)syncer {
//    if (!_syncer) {
//        _syncer = [STGTDataSyncController sharedSyncer];
//    }
//    return _syncer;
//}

- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[NSString stringWithFormat:@"STGT%@", self.typeOfProperty]];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.tracker.document.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
        _resultsController.delegate = self;
    }
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
            // do something
        }
    }
}


- (IBAction)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    [self.tableView reloadData];
}

- (void)addNewPropertyWithName:(NSString *)name {
    
    if ([self.typeOfProperty isEqualToString:@"Interest"]) {
        STGTInterest *newInterest = (STGTInterest *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTInterest" inManagedObjectContext:self.tracker.document.managedObjectContext];
//        [newInterest setXid:[self.tracker newid]];
        [newInterest setName:name];
        STGTInterestImage *interestImage = (STGTInterestImage *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTInterestImage" inManagedObjectContext:self.tracker.document.managedObjectContext];
        interestImage.imageData = UIImagePNGRepresentation([UIImage imageNamed:@"STGTblank_image_44_44.png"]);
        [newInterest setImage:interestImage];
        [self.filterSpot addInterestsObject:newInterest];

    } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
        STGTNetwork *newNetwork = (STGTNetwork *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTNetwork" inManagedObjectContext:self.tracker.document.managedObjectContext];
//        [newNetwork setXid:[self.tracker newid]];
        [newNetwork setName:name];
        STGTNetworkImage *networkImage = (STGTNetworkImage *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTNetworkImage" inManagedObjectContext:self.tracker.document.managedObjectContext];
        networkImage.imageData = UIImagePNGRepresentation([UIImage imageNamed:@"STGTblank_image_44_44.png"]);
        [newNetwork setImage:networkImage];
        [self.filterSpot addNetworksObject:newNetwork];
        
    }
    
//    NSLog(@"newProperty %@", newProperty);
}

- (void)imageTap:(UITapGestureRecognizer *)gesture
{
    if ((gesture.state == UIGestureRecognizerStateChanged) ||
        (gesture.state == UIGestureRecognizerStateEnded)) {
        if (self.tableView.editing) {
//            NSLog(@"imageTap");
            self.tappedImageView = (UIImageView *)gesture.view;
            UITableViewCell *cell = (UITableViewCell *)self.tappedImageView.superview.superview;
            [[cell.contentView viewWithTag:1] resignFirstResponder];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
            if (indexPath.row != self.resultsController.fetchedObjects.count) {
                UIAlertView *sourceSelectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SOURCE SELECT", @"") message:NSLocalizedString(@"CHOOSE SOURCE 2", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"") otherButtonTitles:NSLocalizedString(@"CAMERA", @""), NSLocalizedString(@"PHOTO LIBRARY", @""), nil];
                sourceSelectAlert.tag = 1;
                [sourceSelectAlert show];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        } else if (buttonIndex == 2) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
    }
}

- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)imageSourceType {
    if ([UIImagePickerController isSourceTypeAvailable:imageSourceType]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.sourceType = imageSourceType;
        [self presentViewController:imagePickerController animated:YES completion:^{
            NSLog(@"presentViewController:UIImagePickerController");
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    self.tappedImageView.image = [self resizeImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    [self addSpotPropertyImageFrom:self.tappedImageView];
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismissViewControllerAnimated");
    }];
}

-(UIImage *)resizeImage:(UIImage *)image {
    CGFloat width = 44;
    CGFloat height = 44;
    UIGraphicsBeginImageContext(CGSizeMake(width ,height));
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

- (void)addSpotPropertyImageFrom:(UIImageView *)imageView {
    
    if ([imageView.superview.superview isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)imageView.superview.superview;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

        NSManagedObject *image = [[self.resultsController.fetchedObjects objectAtIndex:indexPath.row] valueForKey:@"image"];
        [image setValue:UIImagePNGRepresentation(imageView.image) forKey:@"imageData"];
    }

}

#pragma mark - Table view data source & delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.resultsController sections] count];
    //    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [[self.resultsController sections] objectAtIndex:section];
    if (tableView.editing) {
        return [sectionInfo numberOfObjects] + 1;
    } else {
        return [sectionInfo numberOfObjects];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self.typeOfProperty isEqualToString:@"Interest"]) {
        return NSLocalizedString(@"INTERESTS", @"");
    } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
        return NSLocalizedString(@"NETWORKS", @"");
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"spotProperty"];
    cell.textLabel.text = @"";
    UIView *viewToDelete = [cell.contentView viewWithTag:1];
    if (viewToDelete) [viewToDelete removeFromSuperview];
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(64, 9, 270, 24)];
    textField.font = [UIFont boldSystemFontOfSize:20];
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.returnKeyType = UIReturnKeyDone;
    textField.tag = 1;
    textField.delegate = self;
    if ([self.typeOfProperty isEqualToString:@"Interest"]) {
        textField.placeholder = NSLocalizedString(@"INTEREST NAME", @"");
    } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
        textField.placeholder = NSLocalizedString(@"NETWORK NAME", @"");
    }
    textField.text = nil;
    cell.imageView.image = [UIImage imageNamed:@"STGTblank_image_44_44.png"];
    if (indexPath.row != self.resultsController.fetchedObjects.count) {
        NSManagedObject *object = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [object valueForKey:@"name"]];
        textField.text = cell.textLabel.text;
        if ([object valueForKey:@"image"]) {
            cell.imageView.image = [UIImage imageWithData:[[object valueForKey:@"image"] valueForKey:@"imageData"]];
        } else {
        }
    } else {
    }

    UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTap:)];
    [cell.imageView addGestureRecognizer:imageTap];

    [cell.contentView addSubview:textField];
    [cell.textLabel setHidden:tableView.editing];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    [textField setHidden:!tableView.editing];
    if (!tableView.editing) {
//        NSLog(@"self.caller.spot.properties %@", self.caller.spot.properties);
//        if ([self.caller.spot.properties containsObject:[self.resultsController.fetchedObjects objectAtIndex:indexPath.row]]) {
        if ([self.typeOfProperty isEqualToString:@"Interest"]) {
            if ([self.spot.interests containsObject:[self.resultsController.fetchedObjects objectAtIndex:indexPath.row]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
            if ([self.spot.networks containsObject:[self.resultsController.fetchedObjects objectAtIndex:indexPath.row]]) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
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
//                NSLog(@"addNewPropertyWithName");
                [self addNewPropertyWithName:textField.text];
                textField.text = nil;
            } else {
//                NSLog(@"textField.text isEqualToString:@\"\"");
            }
        }
    } else if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObject *propertyToDelete = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        if ([self.typeOfProperty isEqualToString:@"Interest"]) {
            [self.filterSpot removeInterestsObject:(STGTInterest *)propertyToDelete];
        } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
            [self.filterSpot removeNetworksObject:(STGTNetwork *)propertyToDelete];
        }
        [self.tracker.document.managedObjectContext deleteObject:propertyToDelete];
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"indexPath %@", indexPath);
    
    NSManagedObject *spotProperty = [self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        if ([self.typeOfProperty isEqualToString:@"Interest"]) {
            [self.spot removeInterestsObject:(STGTInterest *)spotProperty];
        } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
            [self.spot removeNetworksObject:(STGTNetwork *)spotProperty];
        }
    } else if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        if ([self.typeOfProperty isEqualToString:@"Interest"]) {
            [self.spot addInterestsObject:(STGTInterest *)spotProperty];
        } else if ([self.typeOfProperty isEqualToString:@"Network"]) {
            [self.spot addNetworksObject:(STGTNetwork *)spotProperty];
        }
    }
    return indexPath;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    NSLog(@"textFieldShouldEndEditing");
    if ([textField.superview.superview isKindOfClass:[UITableViewCell class]]) {
//        NSLog(@"textFieldShouldEndEditing");
        UITableViewCell *cell = (UITableViewCell *)textField.superview.superview;
        if ([cell.superview isKindOfClass:[UITableView class]]) {
            UITableView *tableView = (UITableView *)cell.superview;
            if ([tableView indexPathForCell:cell].row == [tableView numberOfRowsInSection:0] - 1) {
//                NSLog(@"Last row");
                if (![textField.text isEqualToString:@""]) {
//                    NSLog(@"addNewPropertyWithName");
                    [self addNewPropertyWithName:textField.text];
                    textField.text = nil;
                } else {
//                    NSLog(@"textField.text isEqualToString:@\"\"");
                }
            } else {
//                NSLog(@"Not last row");
                if (![textField.text isEqualToString:cell.textLabel.text]) {
                    if ([textField.text isEqualToString:@""]) {
                        textField.text = cell.textLabel.text;
                    } else {
                        NSManagedObject *spotProperty = [self.resultsController.fetchedObjects objectAtIndex:[tableView indexPathForCell:cell].row];
                        [spotProperty setValue:textField.text forKey:@"name"];
//                        spotProperty.ts = [NSDate date];
//                        spotProperty.synced = [NSNumber numberWithBool:NO];
                        cell.textLabel.text = textField.text;
                        [textField resignFirstResponder];
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
    [self.tracker.document saveToURL:self.tracker.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"controllerDidChangeContent UIDocumentSaveForOverwriting success");
    }];
//    NSLog(@"controllerDidChangeContent");
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
//    NSLog(@"controller didChangeObject");
    
    if (type == NSFetchedResultsChangeDelete) {
        
//        NSLog(@"NSFetchedResultsChangeDelete");
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
        
    } else if (type == NSFetchedResultsChangeInsert) {
        
//        NSLog(@"NSFetchedResultsChangeInsert");
        [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
//        [self.tableView reloadData];
        
    } else if (type == NSFetchedResultsChangeUpdate || type == NSFetchedResultsChangeMove) {
        
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

- (void)viewDidLoad
{
    [super viewDidLoad];
//    NSLog(@"self.spot %@", self.spot);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
//    self.tableView.allowsSelectionDuringEditing = YES;
//    [self keyboardNotificationsRegistration];
    [self performFetch];
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
