//
//  SpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSpotViewController.h"
#import "STGTSpotPropertiesViewController.h"
#import "STGTTrack.h"
#import "STGTDataSyncController.h"
#import "STGTInterest.h"
#import "STGTNetwork.h"
#import "STGTSpotImage.h"
#import "STGTSpotImageViewController.h"
#import "STGTImagesViewController.h"

@interface STGTSpotViewController () <UIAlertViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSString *typeOfProperty;
@property (weak, nonatomic) IBOutlet UILabel *spotInfo;
@property (weak, nonatomic) IBOutlet UITextField *spotLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *interestsCollectionView;
@property (weak, nonatomic) IBOutlet UICollectionView *networkCollectionView;
@property (weak, nonatomic) IBOutlet UIImageView *spotImageView;
@property (nonatomic, strong) STGTDataSyncController *syncer;
@property (weak, nonatomic) IBOutlet UILabel *spotInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *interestsLabel;
@property (weak, nonatomic) IBOutlet UILabel *networksLabel;


@end

@implementation STGTSpotViewController

- (STGTDataSyncController *)syncer {
    if (!_syncer) {
        _syncer = [STGTDataSyncController sharedSyncer];
    }
    return _syncer;
}

- (IBAction)deleteSpot:(id)sender {
    UIAlertView *deleteSpotAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DELETE SPOT", @"") message:@"?" delegate:self cancelButtonTitle:NSLocalizedString(@"NO", @"")  otherButtonTitles:NSLocalizedString(@"YES", @""),nil];
    deleteSpotAlert.tag = 1;
    [deleteSpotAlert show];
}

- (void)spotImageTap:(UITapGestureRecognizer *)gesture {
    if (self.spot.images.count == 0) {
        UIAlertView *sourceSelectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SOURCE SELECT", @"") message:NSLocalizedString(@"CHOOSE SOURCE", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"") otherButtonTitles:NSLocalizedString(@"CAMERA", @""), NSLocalizedString(@"PHOTO LIBRARY", @""), nil];
        sourceSelectAlert.tag = 2;
        [sourceSelectAlert show];
    } else {
        [self performSegueWithIdentifier:@"showImageCollection" sender:self];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
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
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        } else if (buttonIndex == 2) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
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
//            NSLog(@"placemarks %@", placemarks);
            if (error) {
                NSLog(@"error %@", error.localizedDescription);
            }
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
    self.spotLabel.placeholder = NSLocalizedString(@"SPOT LABEL", @"");
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
    } else if ([segue.destinationViewController isKindOfClass:[STGTImagesViewController class]]) {
        STGTImagesViewController *imagesVC = segue.destinationViewController;
        if ([segue.identifier isEqualToString:@"showImageCollection"]) {
            imagesVC.spot = self.spot;
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
    [self startSavingAnimationWithMessage:NSLocalizedString(@"ADD PHOTO TO SPOT", @"") withTag:666 forView:self.view];
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismissViewControllerAnimated");
        [self saveImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        [self stopSavingAnimationWithTag:666 forView:self.view];
    }];
}

- (void)saveImage:(UIImage *)image {
    
    STGTSpotImage *spotImage = (STGTSpotImage *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTSpotImage" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    image = [self resizeImage:image toSize:CGSizeMake(1024, 1024)];
    spotImage.imageData = UIImagePNGRepresentation(image);
    [self.spot addImagesObject:spotImage];
//    NSLog(@"self.spot.avatarXid %@", self.spot.avatarXid);
    if (!self.spot.avatarXid || [self.spot.avatarXid isEqualToString:@""]) {
        self.spot.avatarXid = spotImage.xid;
        self.spotImageView.image = [self resizeImage:image toSize:CGSizeMake(self.spotImageView.bounds.size.width, self.spotImageView.bounds.size.height)];
    }
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"spotImage UIDocumentSaveForOverwriting success");
    }];

}

-(UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size{
//    NSLog(@"image.size.height %f, image.size.width %f", image.size.height, image.size.width);
    CGFloat width = size.width;
    CGFloat height = size.height;
//    NSLog(@"width, height %f %f", width, height);
//    NSLog(@"spotImage.size.height, spotImage.size.width %f %f", image.size.height, image.size.width);
    if (image.size.width >= image.size.height) {
//        NSLog(@">=");
        height = width * image.size.height / image.size.width;
    } else {
//        NSLog(@"<");
        width = height * image.size.width / image.size.height;
    }
//    NSLog(@"width, height %f %f", width, height);
    UIGraphicsBeginImageContext(CGSizeMake(width ,height));
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *resultImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImage;
}

-(void)startSavingAnimationWithMessage:(NSString *)message withTag:(NSUInteger)tag forView:(UIView *)view {
    
    UIView *activityView = [[UIView alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    activityView.tag = tag;
    activityView.backgroundColor = [UIColor darkGrayColor];
    activityView.alpha = 0.75;
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityView addSubview:activityIndicator];
    
    UILabel *requestingInformation = [[UILabel alloc] init];
    requestingInformation.text = message;
    requestingInformation.backgroundColor = [UIColor clearColor];
    requestingInformation.textColor = [UIColor whiteColor];
    requestingInformation.font = [UIFont boldSystemFontOfSize:20];
    [activityView addSubview:requestingInformation];
    
    CGSize requestingInformationSize = [requestingInformation.text sizeWithFont:requestingInformation.font constrainedToSize:CGSizeMake(self.view.frame.size.width, self.view.frame.size.height/2) lineBreakMode:requestingInformation.lineBreakMode];
    
    activityIndicator.center = CGPointMake(self.view.frame.size.width/2,(self.view.frame.size.height/2));
    requestingInformation.frame = CGRectMake((self.view.frame.size.width - requestingInformationSize.width)/2, self.view.frame.size.height/2 + requestingInformationSize.height, requestingInformationSize.width, requestingInformation.font.lineHeight);
    
    [view addSubview:activityView];
    [view bringSubviewToFront:activityView];
    
    [activityIndicator startAnimating];
}

-(void)stopSavingAnimationWithTag:(NSUInteger)tag forView:(UIView *)view {
    
    UIView *activityView = [view viewWithTag:tag];

    for (UIView *subview in [activityView subviews]) {
        
        if ([subview isKindOfClass:[UIActivityIndicatorView class]]) {
            
            UIActivityIndicatorView *activityIndicator = (UIActivityIndicatorView *)subview;
            [activityIndicator stopAnimating];
            break;
            
        }
    }

    [activityView removeFromSuperview];
}


#pragma mark - UICollectionViewDataSource, Delegate, DelegateFlowLayout

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSUInteger count;
    if (collectionView.tag == 1) {
        count = [self.spot.interests sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]]].count;
    } else if (collectionView.tag == 2) {
        count = [self.spot.networks sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]]].count;
    }
    return count+1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

    NSString *type;
    NSString *cellIdentifier;
    NSArray *spotPropertiesArray;
    if (collectionView.tag == 1) {
        type = @"Interest";
        spotPropertiesArray = [self.spot.interests sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
        cellIdentifier = @"interestCell";
    } else if (collectionView.tag == 2) {
        spotPropertiesArray = [self.spot.networks sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]];
        type = @"Network";
        cellIdentifier = @"networkCell";
    }

    UICollectionViewCell *cell;
    
    if (indexPath.row == spotPropertiesArray.count) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:[NSString stringWithFormat:@"%@%@", @"add", type] forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
        [[cell.contentView viewWithTag:1] removeFromSuperview];
        NSManagedObject *spotProperty = [spotPropertiesArray objectAtIndex:indexPath.row];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, cell.contentView.frame.size.width, cell.contentView.frame.size.height)];
        imageView.image = [UIImage imageWithData:[[spotProperty valueForKey:@"image"] valueForKey:@"imageData"]];
        imageView.tag = 1;
        [cell.contentView addSubview:imageView];
    }
    
    return cell;
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    if (![textField.text isEqualToString:@""]) {
        if (![textField.text isEqualToString:self.spot.label]) {
            self.spot.label = textField.text;
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
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTImage"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"xid" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"SELF.xid == %@", self.spot.avatarXid];
    NSError *error;
    STGTImage *spotImage = [[self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error] lastObject];
    
    if (spotImage) {
        self.spotImageView.image = [self resizeImage:[UIImage imageWithData:spotImage.imageData] toSize:CGSizeMake(self.spotImageView.bounds.size.width, self.spotImageView.bounds.size.height)];
    } else {
        self.spotImageView.image = [UIImage imageNamed:@"STGTblank_spotImage_132_85"];
    }
    
    self.spotImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    UITapGestureRecognizer *spotImageTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(spotImageTap:)];
    [self.spotImageView addGestureRecognizer:spotImageTap];

}

- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"SPOT", @"");
    self.spotInfoLabel.text = NSLocalizedString(@"SPOT INFO", @"");
    self.interestsLabel.text = NSLocalizedString(@"INTERESTS", @"");
    self.networksLabel.text = NSLocalizedString(@"NETWORKS", @"");
    
    if (!self.spot) {
    STGTSpot *newSpot = (STGTSpot *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTSpot" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    newSpot.latitude = [NSNumber numberWithDouble:self.coordinate.latitude];
    newSpot.longitude = [NSNumber numberWithDouble:self.coordinate.longitude];
    newSpot.address = @"";
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
