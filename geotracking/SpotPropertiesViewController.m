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

@interface SpotPropertiesViewController () <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UITextFieldDelegate, UIAlertViewDelegate>
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) UITextField *activeTextField;
@property (nonatomic, strong) NSFetchedResultsController *resultsController;
@property (nonatomic, strong) UIImageView *tappedImageView;


@end

@implementation SpotPropertiesViewController


- (NSFetchedResultsController *)resultsController {
    if (!_resultsController) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"SpotProperty"];
        request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
        request.predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", self.typeOfProperty];
        _resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:self.tracker.locationsDatabase.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
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
            // do something else
        }
    }
}


#pragma mark - keyboard behavior

//- (void)keyboardNotificationsRegistration
//{
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
//    
//}
//
//- (void)keyboardDidShow:(NSNotification *)notification
//{
//    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
////    CGFloat heightShift = keyboardSize.height - self.toolbar.frame.size.height;
//    CGFloat heightShift = keyboardSize.height;
//    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, heightShift, 0.0);
//    self.tableView.contentInset = contentInsets;
//    self.tableView.scrollIndicatorInsets = contentInsets;
//    
//    CGRect rect = self.tableView.bounds;
//    rect.size.height -= heightShift;
//    CGRect textFieldFrame = [self firstResponderCellFrame];
//    if (!CGRectContainsPoint(rect, CGPointMake(0.0, textFieldFrame.origin.y + textFieldFrame.size.height))) {
//        CGPoint scrollPoint = CGPointMake(0.0, textFieldFrame.origin.y + textFieldFrame.size.height - heightShift);
//        [self.tableView setContentOffset:scrollPoint animated:YES];
//    }
//}
//
//- (void)keyboardWillHide:(NSNotification *)notification {
//    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
//    self.tableView.contentInset = contentInsets;
//    self.tableView.scrollIndicatorInsets = contentInsets;    
//}
//
//- (CGRect)firstResponderCellFrame {
//    CGRect frame;
//    for (UIView *subview in self.tableView.subviews) {
//        if ([subview isKindOfClass:[UITableViewCell class]]) {
//            UITableViewCell *cell = (UITableViewCell *)subview;
//            if ([[cell.contentView viewWithTag:1] isFirstResponder]) {
//                frame = cell.frame;
//            }
//        }
//    }
//    return frame;
//}

- (IBAction)editButtonPressed:(id)sender {
    [self.tableView setEditing:!self.tableView.editing animated:YES];
    [self.tableView reloadData];
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
//            NSLog(@"imageTap");
            self.tappedImageView = (UIImageView *)gesture.view;
            UIAlertView *sourceSelectAlert = [[UIAlertView alloc] initWithTitle:@"SourceSelect" message:@"Choose source for picture" delegate:self cancelButtonTitle:@"Camera" otherButtonTitles:@"PhotoLibrary", nil];
            [sourceSelectAlert show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"SourceSelect"]) {
        if (buttonIndex == 0) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        } else {
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
//    NSLog(@"info %@", info);
//    NSLog(@"UIImagePickerControllerOriginalImage %@", [info objectForKey:UIImagePickerControllerOriginalImage]);
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
        SpotProperty *spotProperty = (SpotProperty *)[self.resultsController.fetchedObjects objectAtIndex:indexPath.row];
        spotProperty.image = UIImagePNGRepresentation(imageView.image);
        [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"updateObject UIDocumentSaveForOverwriting success");
        }];
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
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(64, 9, 270, 24)];
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
        if (spotProperty.image) {
            cell.imageView.image = [UIImage imageWithData:spotProperty.image];
        }
        UITapGestureRecognizer *imageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageTap:)];
        [cell.imageView addGestureRecognizer:imageTap];
    } else {
//        [textField becomeFirstResponder];
    }
    [cell.contentView addSubview:textField];
    [cell.textLabel setHidden:tableView.editing];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [textField setHidden:!tableView.editing];
    if (!tableView.editing) {
//        cell.accessoryType = UITableViewCellAccessoryCheckmark;
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"indexPath %@", indexPath);
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    return indexPath;
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
        [self.tableView reloadData];
        //        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
        
    } else if (type == NSFetchedResultsChangeUpdate) {
        
        //        NSLog(@"NSFetchedResultsChangeUpdate");
        // reloadRowsAtIndexPaths causes strange error don't know why
        [self.tableView reloadData];
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
