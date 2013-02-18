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

@interface STGTImagesViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIAlertViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
@property (nonatomic, strong) NSArray *images;
@property (nonatomic, strong) STGTTrackingLocationController *tracker;
@property (nonatomic) NSUInteger currentIndex;

@end

@implementation STGTImagesViewController

- (STGTTrackingLocationController *)tracker {
    if (!_tracker) {
        _tracker = [STGTTrackingLocationController sharedTracker];
    }
    return  _tracker;
}

- (IBAction)editButtonPressed:(id)sender {
    UIAlertView *photosEditAlert = [[UIAlertView alloc] initWithTitle:@"Manage photos" message:@"Choose action" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Add new photo", @"Set current photo as avatar", @"Delete current photo", nil];
    [photosEditAlert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([alertView.title isEqualToString:@"Manage photos"]) {
        if (buttonIndex == 1) {
            UIAlertView *sourceSelectAlert = [[UIAlertView alloc] initWithTitle:@"SourceSelect" message:@"Choose source for picture" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Camera", @"PhotoLibrary", nil];
            [sourceSelectAlert show];
        } else if (buttonIndex == 2) {
            NSLog(@"Set current photo as avatar");
        } else if (buttonIndex == 3) {
//            NSLog(@"Delete current photo");
            [self.spot removeImagesObject:[self.images objectAtIndex:self.currentIndex]];
            self.images = nil;
            if (self.images.count > 0) {
                if (self.currentIndex > 0) {
                    self.currentIndex--;
                }
                [self activateViewControllerAtIndex:self.currentIndex];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    } else if ([alertView.title isEqualToString:@"SourceSelect"]) {
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
    [picker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"dismissViewControllerAnimated");
        [self saveImage:[info objectForKey:UIImagePickerControllerOriginalImage]];
    }];
}

- (void)saveImage:(UIImage *)image {
    
    STGTSpotImage *spotImage = (STGTSpotImage *)[NSEntityDescription insertNewObjectForEntityForName:@"STGTSpotImage" inManagedObjectContext:self.tracker.locationsDatabase.managedObjectContext];
    image = [self resizeImage:image toSize:CGSizeMake(1024, 1024)];
    spotImage.imageData = UIImagePNGRepresentation(image);
    [self.spot addImagesObject:spotImage];
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"spotImage UIDocumentSaveForOverwriting success");
    }];
    self.images = nil;
    self.currentIndex = self.images.count - 1;
    [self activateViewControllerAtIndex:self.currentIndex];
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


- (NSArray *)images {
    if (!_images) {
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:YES selector:@selector(compare:)]];
        _images = [self.spot.images sortedArrayUsingDescriptors:sortDescriptors];
    }
    return _images;
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
    STGTSpotImageViewController *startVC = [self viewControllerAtIndex:index storyboard:self.storyboard];
    NSArray *viewControllers = @[startVC];
    [self setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    [self updateTitle];
}

- (void)updateTitle {
    self.currentIndex = [self.images indexOfObject:[[self.viewControllers lastObject] spotImage]];
    self.title = [NSString stringWithFormat:@"%d of %d", self.currentIndex+1, self.images.count];
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
    self.currentIndex = 0;
    [self activateViewControllerAtIndex:self.currentIndex];
    self.dataSource = self;
    self.delegate = self;
	// Do any additional setup after loading the view.
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.tracker.locationsDatabase saveToURL:self.tracker.locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"spot.image UIDocumentSaveForOverwriting success");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
