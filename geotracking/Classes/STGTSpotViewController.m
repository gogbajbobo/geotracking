//
//  SpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSpotViewController.h"
#import "STGTSpotPropertiesViewController.h"
#import "STGTSpotProperty.h"
#import "STGTTrack.h"
#import "STGTDataSyncController.h"

@interface STGTSpotViewController () <UIAlertViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSString *typeOfProperty;
@property (weak, nonatomic) IBOutlet UILabel *spotInfo;
@property (weak, nonatomic) IBOutlet UITextField *spotLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *interestsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *networkCollectionView;
@property (weak, nonatomic) IBOutlet UIImageView *spotImageView;
@property (nonatomic, strong) STGTDataSyncController *syncer;


@end

@implementation STGTSpotViewController

- (STGTDataSyncController *)syncer {
    if (!_syncer) {
        _syncer = [STGTDataSyncController sharedSyncer];
    }
    return _syncer;
}

- (IBAction)deleteSpot:(id)sender {
    UIAlertView *deleteSpotAlert = [[UIAlertView alloc] initWithTitle:@"Delete spot" message:@"Delete spot?" delegate:self cancelButtonTitle:@"YES"  otherButtonTitles:@"NO",nil];
    [deleteSpotAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete spot"]) {
        if (buttonIndex == 0) {
            if ([self.spotLabel isFirstResponder]) {
                self.spotLabel.text = @"";
                [self.spotLabel resignFirstResponder];
            }
            [self.tracker.locationsDatabase.managedObjectContext deleteObject:self.spot];
            [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                NSLog(@"deleteObject:self.spot UIDocumentSaveForOverwriting success");
            }];
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else if ([alertView.title isEqualToString:@"SourceSelect"]) {
        if (buttonIndex == 1) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        } else if (buttonIndex == 2) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        } else if (buttonIndex == 3) {
            self.spotImageView.image = nil;
            [self.spotImageView setNeedsDisplay];
        }
    }

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
    if ([self.spot.address isEqualToString:@""]) {
        CLLocationDegrees longitude = [self.spot.longitude doubleValue];
        CLLocationDegrees latitude = [self.spot.latitude doubleValue];
        CLLocation *location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
        CLGeocoder *geoCoder = [[CLGeocoder alloc] init];
        [geoCoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"placemarks %@", placemarks);
            NSLog(@"error %@", error.localizedDescription);
            CLPlacemark *place = [placemarks lastObject];
            self.spotInfo.text = place.name;
            self.spot.address = place.name;
        }];
    } else {
        self.spotInfo.text = self.spot.address;
    }
}

- (void)showSpotLabel {
    self.spotLabel.font = [UIFont boldSystemFontOfSize:20];
    self.spotLabel.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.spotLabel.returnKeyType = UIReturnKeyDone;
    self.spotLabel.tag = 1;
    self.spotLabel.delegate = self;
    self.spotLabel.placeholder = @"Spot label";
    self.spotLabel.text = self.spot.label;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.destinationViewController isKindOfClass:[STGTSpotPropertiesViewController class]]) {
        STGTSpotPropertiesViewController *spotPropertiesVC = segue.destinationViewController;        
        if ([segue.identifier isEqualToString:@"showProperties"]) {
            spotPropertiesVC.spot = self.spot;
            spotPropertiesVC.caller = self;
            spotPropertiesVC.tracker = self.tracker;
            spotPropertiesVC.typeOfProperty = self.typeOfProperty;
            spotPropertiesVC.filterSpot = self.filterSpot;
        }
    }
    
}

- (void)spotImageLongTap:(UILongPressGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIAlertView *sourceSelectAlert = [[UIAlertView alloc] initWithTitle:@"SourceSelect" message:@"Choose source for picture" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Camera", @"PhotoLibrary", @"Delete photo", nil];
        [sourceSelectAlert show];
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
//    self.spotImageView.image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.spotImageView.image = [self resizeImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    self.spot.image = UIImagePNGRepresentation(self.spotImageView.image);
    self.spot.ts = [NSDate date];
//    self.spot.synced = [NSNumber numberWithBool:NO];
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"spot.image UIDocumentSaveForOverwriting success");
    }];
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismissViewControllerAnimated");
    }];
}

-(UIImage *)resizeImage:(UIImage *)image {
    CGFloat width = self.spotImageView.bounds.size.width;
    CGFloat height = self.spotImageView.bounds.size.height;
    NSLog(@"width, height %f %f", width, height);
    NSLog(@"spotImage.size.height, spotImage.size.width %f %f", image.size.height, image.size.width);
    if (image.size.width >= image.size.height) {
        NSLog(@">=");
        height = width * image.size.height / image.size.width;
    } else {
        NSLog(@"<");
        width = height * image.size.width / image.size.height;
    }
    NSLog(@"width, height %f %f", width, height);
    UIGraphicsBeginImageContext(CGSizeMake(width ,height));
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}


#pragma mark - UICollectionViewDataSource, Delegate, DelegateFlowLayout

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSString *predicateString;
    if (collectionView.tag == 1) {
        predicateString = @"Interest";
    } else if (collectionView.tag == 2) {
        predicateString = @"Network";
    }
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", predicateString];
    NSUInteger count = [[self.spot.properties filteredSetUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]]].count;
    return count+1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSString *predicateString;
    NSString *cellIdentifier;
    if (collectionView.tag == 1) {
        predicateString = @"Interest";
        cellIdentifier = @"interestCell";
    } else if (collectionView.tag == 2) {
        predicateString = @"Network";
        cellIdentifier = @"networkCell";
    }

    UICollectionViewCell *cell;

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", predicateString];
    NSArray *spotPropertiesArray = [[self.spot.properties filteredSetUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
    
    if (indexPath.row == spotPropertiesArray.count) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%@", @"add", predicateString] forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [[cell.contentView viewWithTag:1] removeFromSuperview];
        STGTSpotProperty *spotProperty = [spotPropertiesArray objectAtIndex:indexPath.row];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height)];
        imageView.image = [UIImage imageWithData:spotProperty.image];
        imageView.tag = 1;
        [cell.contentView addSubview:imageView];
    }
    
    return cell;
}

//- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
//    UICollectionReusableView *view;
//    NSString *viewIdentifier;
//    if (collectionView.tag == 1) {
//        viewIdentifier = @"interestHeader";
//    } else if (collectionView.tag == 2) {
//        viewIdentifier = @"networkHeader";
//    }
//    if (kind == UICollectionElementKindSectionHeader) {
//        view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:viewIdentifier forIndexPath:indexPath];
//    } else if (kind == UICollectionElementKindSectionFooter) {
////        view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"interestFooter" forIndexPath:indexPath];
//    }
//    return view;
//}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
//    CGSize headerSize;
//    headerSize.height = 50;
//    headerSize.width = 100;
//    return headerSize;
//}
//
//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section {
//    CGSize footerSize;
//    footerSize.height = 50;
//    footerSize.width = 100;
//    return footerSize;
//}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (![textField.text isEqualToString:@""]) {
        if (![textField.text isEqualToString:self.spot.label]) {
            self.spot.label = textField.text;
            self.spot.ts = [NSDate date];
//            self.spot.synced = [NSNumber numberWithBool:NO];
            [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                NSLog(@"spot.label UIDocumentSaveForOverwriting success");
            }];
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
    [self.interestsCollectionView reloadData];
    [self.networkCollectionView reloadData];
}

- (void)viewDidLoad
{
    if (!self.spot) {
    STGTSpot *newSpot = (STGTSpot *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTSpot" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    [newSpot setXid:[self.tracker newid]];
    newSpot.latitude = [NSNumber numberWithDouble:self.coordinate.latitude];
    newSpot.longitude = [NSNumber numberWithDouble:self.coordinate.longitude];
    NSDate *ts = [NSDate date];
    newSpot.ts = ts;
    newSpot.cts = ts;
    newSpot.address = @"";
    [self.syncer changesCountPlusOne];
    self.spot = newSpot;
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"newSpot UIDocumentSaveForOverwriting success");
    }];
}
    self.interestsCollectionView.dataSource = self;
    self.interestsCollectionView.delegate = self;
    self.interestsCollectionView.tag = 1;
    self.networkCollectionView.dataSource = self;
    self.networkCollectionView.delegate = self;
    self.networkCollectionView.tag = 2;
    [self showSpotInfo];
    [self showSpotLabel];
    UIImage *spotImage = [UIImage imageWithData:self.spot.image];
    if (spotImage) {
        self.spotImageView.image = spotImage;
    } else {
        self.spotImageView.image = [UIImage imageNamed:@"STGTblank_spotImage_132_85"];
    }

    self.spotImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UILongPressGestureRecognizer *spotImageLongTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(spotImageLongTap:)];
    [self.spotImageView addGestureRecognizer:spotImageLongTap];


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
