//
//  STGTSpotImageViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 2/17/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSpotImageViewController.h"
#import "STGTSpotImage.h"

@interface STGTSpotImageViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation STGTSpotImageViewController


- (void)loadImage {
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;

    UIImage *spotImage = [UIImage imageWithData:self.spot.image.imageData];
    if (spotImage) {
        self.imageView.image = spotImage;
    } else {
        self.imageView.image = [UIImage imageNamed:@"STGTblank_spotImage_132_85"];
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
    [self loadImage];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
