//
//  STGTImagesViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 2/18/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTImagesViewController.h"
#import "STGTSpotImageViewController.h"
#import "STGTSpotImage.h"
#import "STGTTrackingLocationController.h"
#import "STGTSessionManager.h"
#import "STGTSession.h"

@interface STGTImagesViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic) NSUInteger currentIndex;

@end

@implementation STGTImagesViewController

- (STGTTrackingLocationController *)tracker {
    if (!_tracker) {
//        _tracker = [STGTTrackingLocationController sharedTracker];
        _tracker = [(STGTSession *)[[STGTSessionManager sharedManager] currentSession] tracker];
    }
    return  _tracker;
}

- (IBAction)editButtonPressed:(id)sender {
    UIAlertView *photosEditAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"MANAGE PHOTOS", @"") message:NSLocalizedString(@"CHOOSE ACTION", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"") otherButtonTitles:NSLocalizedString(@"ADD NEW PHOTO", @""), NSLocalizedString(@"SET AS AVATAR", @""), NSLocalizedString(@"DELETE PHOTO", @""), nil];
    photosEditAlert.tag = 1;
    [photosEditAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 1) {
        if (buttonIndex == 1) {
            UIAlertView *sourceSelectAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SOURCE SELECT", @"") message:NSLocalizedString(@"CHOOSE SOURCE", @"") delegate:self cancelButtonTitle:NSLocalizedString(@"CANCEL", @"") otherButtonTitles:NSLocalizedString(@"CAMERA", @""), NSLocalizedString(@"PHOTO LIBRARY", @""), nil];
            sourceSelectAlert.tag = 2;
            [sourceSelectAlert show];
        } else if (buttonIndex == 2) {
//            NSLog(@"Set current photo as avatar");
            STGTSpotImage *spotImage = [self.images objectAtIndex:self.currentIndex];
            self.spot.avatarXid = spotImage.xid;
        } else if (buttonIndex == 3) {
//            NSLog(@"Delete current photo");
            UIAlertView *deleteAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DELETE PHOTO", @"") message:NSLocalizedString(@"R U SURE", @"") delegate: self cancelButtonTitle:NSLocalizedString(@"NO", @"")  otherButtonTitles:NSLocalizedString(@"YES", @""),nil];
            deleteAlert.tag = 3;
            [deleteAlert show];
        }
    } else if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
        } else if (buttonIndex == 2) {
            [self showImagePickerForSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        }
    } else if (alertView.tag == 3) {
        if (buttonIndex == 1) {
            STGTSpotImage *spotImage = [self.images objectAtIndex:self.currentIndex];
            [self.spot removeImagesObject:spotImage];
            self.images = [self spotImages];
            if (self.images.count > 0) {
                if ([spotImage.xid isEqualToString:self.spot.avatarXid]) {
                    NSUInteger index = (self.currentIndex == 0) ? 1 : 0;
                    STGTSpotImage *firstImage = [self.images objectAtIndex:index];
                    self.spot.avatarXid = firstImage.xid;
                }
                if (self.currentIndex > 0) {
                    self.currentIndex--;
                }
                [self activateViewControllerAtIndex:self.currentIndex];
            } else {
                self.spot.avatarXid = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
            [self.tracker.document.managedObjectContext deleteObject:spotImage];
            [self.tracker.document saveToURL:self.tracker.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
                NSLog(@"spotImage UIDocumentSaveForOverwriting success");
            }];

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
        [self saveImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
        NSLog(@"dismissViewControllerAnimated");
        [self stopSavingAnimationWithTag:666 forView:self.view];
    }];
}

- (void)saveImage:(UIImage *)image {
    
    STGTSpotImage *spotImage = (STGTSpotImage *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTSpotImage" inManagedObjectContext:self.tracker.document.managedObjectContext];
    image = [self resizeImage:image toSize:CGSizeMake(1024, 1024)];
    spotImage.imageData = UIImagePNGRepresentation(image);
    [self.spot addImagesObject:spotImage];
    self.images = [self spotImages];
    [self activateViewControllerAtIndex:self.images.count - 2];
    self.currentIndex = self.images.count - 1;
    [self activateViewControllerAtIndex:self.currentIndex];
    [self.tracker.document saveToURL:self.tracker.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"spotImage UIDocumentSaveForOverwriting success");
    }];

}

-(UIImage *)resizeImage:(UIImage *)image toSize:(CGSize)size{
    CGFloat width = size.width;
    CGFloat height = size.height;
    if (image.size.width >= image.size.height) {
        height = width * image.size.height / image.size.width;
    } else {
        width = height * image.size.width / image.size.height;
    }
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

- (NSArray *)spotImages {
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"cts" ascending:YES selector:@selector(compare:)]];
        return [self.spot.images sortedArrayUsingDescriptors:sortDescriptors];
}

- (STGTSpotImageViewController *)viewControllerAtIndex:(NSUInteger)index storyboard:(UIStoryboard *)storyboard
{
    if ((self.images.count == 0) || (index >= self.images.count)) {
        return nil;
    } else {
        STGTSpotImageViewController *spotImageVC = [storyboard instantiateViewControllerWithIdentifier:@"STGTSpotImageVC"];
        spotImageVC.spotImage = (STGTSpotImage *)[self.images objectAtIndex:index];
        return spotImageVC;
    }
}

- (void)activateViewControllerAtIndex:(NSUInteger)index {
    self.currentIndex = index;
    STGTSpotImageViewController *imageVC = [self viewControllerAtIndex:index storyboard:self.storyboard];
    NSArray *viewControllers = @[imageVC];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    [self updateTitle];
}

- (void)updateTitle {
    self.currentIndex = [self.images indexOfObject:[[self.viewControllers lastObject] spotImage]];
    self.title = [NSString stringWithFormat:@"%d %@ %d", self.currentIndex+1, NSLocalizedString(@"OF", @""), self.images.count];
}

#pragma mark - Page View Controller Data Source

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    if ([viewController isKindOfClass:[STGTSpotImageViewController class]]) {
        STGTSpotImageViewController *spotImageVC = (STGTSpotImageViewController *)viewController;
        NSUInteger index = [self.images indexOfObject:spotImageVC.spotImage];
    
        if ((index == 0) || (index == NSNotFound)) {
            return nil;
        
        } else {
            index--;
            return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
        }
    
    } else {
        return nil;
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    if ([viewController isKindOfClass:[STGTSpotImageViewController class]]) {
        STGTSpotImageViewController *spotImageVC = (STGTSpotImageViewController *)viewController;
        NSUInteger index = [self.images indexOfObject:spotImageVC.spotImage];
        
        if (index == NSNotFound || index == self.images.count - 1) {
            return nil;
            
        } else {
            index++;
            return [self viewControllerAtIndex:index storyboard:viewController.storyboard];
        }
        
    } else {
        return nil;
    }
}

#pragma mark - Page View Controller Delegate

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray *)pendingViewControllers {
    
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed {
    if (completed) {
        [self updateTitle];
    }
}

//- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
//    return self.images.count;
//}
//
//- (NSInteger)presentationIndexForPageViewController:(UIPageViewController *)pageViewController {
//    return self.currentIndex;
//}

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
    self.images = [self spotImages];
    self.currentIndex = 0;
    [self activateViewControllerAtIndex:self.currentIndex];
    self.dataSource = self;
    self.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tracker.document saveToURL:self.tracker.document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"spot.image UIDocumentSaveForOverwriting success");
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if ([self isViewLoaded] && [self.view window] == nil) {
        self.view = nil;
    }
}

@end
