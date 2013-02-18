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

@interface STGTImagesViewController () <UIPageViewControllerDataSource>
@property (nonatomic, strong) NSArray *images;

@end

@implementation STGTImagesViewController

- (NSArray *)images {
    if (!_images) {
        NSArray *sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"ts" ascending:NO selector:@selector(compare:)]];
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
    self.dataSource = self;
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
