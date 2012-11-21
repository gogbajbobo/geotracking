//
//  SpotViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 11/2/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "SpotViewController.h"
#import "SpotPropertiesViewController.h"
#import "SpotProperty.h"
#import "Track.h"

@interface SpotViewController () <UIAlertViewDelegate, UITextFieldDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>
@property (nonatomic, strong) NSString *typeOfProperty;
@property (weak, nonatomic) IBOutlet UILabel *spotInfo;
@property (weak, nonatomic) IBOutlet UITextField *spotLabel;
@property (weak, nonatomic) IBOutlet UICollectionView *interestsCollectionView;


@end

@implementation SpotViewController

- (IBAction)deleteSpot:(id)sender {
    UIAlertView *deleteSpotAlert = [[UIAlertView alloc] initWithTitle:@"Delete spot" message:@"Delete spot?" delegate:self cancelButtonTitle:@"YES"  otherButtonTitles:@"NO",nil];
    [deleteSpotAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView.title isEqualToString:@"Delete spot"]) {
        if (buttonIndex == 0) {
            [self.tracker.locationsDatabase.managedObjectContext deleteObject:self.spot];
            [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                NSLog(@"deleteObject:self.spot UIDocumentSaveForOverwriting success");
            }];
            [self.navigationController popViewControllerAnimated:YES];
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
    CLLocationDegrees longitude = [self.spot.longitude doubleValue];
    CLLocationDegrees latitude = [self.spot.latitude doubleValue];
    self.spotInfo.text = [NSString stringWithFormat:@"lon/lat %.2f/%.2f", longitude, latitude];
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
    
    if ([segue.destinationViewController isKindOfClass:[SpotPropertiesViewController class]]) {
        SpotPropertiesViewController *spotPropertiesVC = segue.destinationViewController;        
        if ([segue.identifier isEqualToString:@"showProperties"]) {
            spotPropertiesVC.caller = self;
            spotPropertiesVC.tracker = self.tracker;
            spotPropertiesVC.typeOfProperty = self.typeOfProperty;
        }
    }
    
}

#pragma mark - UICollectionViewDataSource, Delegate, DelegateFlowLayout

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @"Interest"];
    NSUInteger count = [[self.spot.properties filteredSetUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]]].count;
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.type == %@", @"Interest"];
    SpotProperty *spotProperty = [[[self.spot.properties filteredSetUsingPredicate:predicate] sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)]]] objectAtIndex:indexPath.row];

    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"interestCell" forIndexPath:indexPath];
    [cell.contentView addSubview:[[UIImageView alloc] initWithImage:[UIImage imageWithData:spotProperty.image]]];
    return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *view;
    if (kind == UICollectionElementKindSectionHeader) {
        view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"interestHeader" forIndexPath:indexPath];
    } else if (kind == UICollectionElementKindSectionFooter) {
//        view = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter withReuseIdentifier:@"interestFooter" forIndexPath:indexPath];
    }
    return view;
}

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
    if (![textField.text isEqualToString:self.spot.label]) {
        self.spot.label = textField.text;
        [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"spot.label UIDocumentSaveForOverwriting success");
        }];
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
//    NSLog(@"self.spot %@", self.spot);
    if (!self.spot) {
        Spot *newSpot = (Spot *)[NSEntityDescription insertNewObjectForEntityForName:@"Spot" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
        [newSpot setXid:[self.tracker newid]];
        newSpot.latitude = [NSNumber numberWithDouble:self.coordinate.latitude];
        newSpot.longitude = [NSNumber numberWithDouble:self.coordinate.longitude];
        newSpot.timestamp = [NSDate date];
        self.spot = newSpot;
        [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
            NSLog(@"newSpot UIDocumentSaveForOverwriting success");
        }];
    }
    self.interestsCollectionView.dataSource = self;
    self.interestsCollectionView.delegate = self;
    [self showSpotInfo];
    [self showSpotLabel];
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
