//
//  STGTSettingsTableViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 1/27/13.
//  Copyright (c) 2013 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTSettingsTableViewController.h"
#import <CoreData/CoreData.h>
#import "STGTSettings.h"
#import "STGTTrackingLocationController.h"

@interface STGTSettingsTableViewController () <UITextFieldDelegate>
@property (nonatomic, strong) STGTSettings *settings;
@property (nonatomic, strong) NSArray *settingsTitles;

@end

@implementation STGTSettingsTableViewController

- (STGTSettings *)settings {
    if (!_settings) {
        _settings = [STGTTrackingLocationController sharedTracker].settings;
    }
    return _settings;
}


- (NSArray *)settingsTitles {
    if (!_settingsTitles) {
        NSArray *trackerSettingsTitles = [NSArray arrayWithObjects:@"desiredAccuracy", @"requiredAccuracy", @"distanceFilter", @"trackDetectionTime", @"trackerAutoStart", @"trackerStartTime", @"trackerFinishTime", nil];
        NSArray *syncerSettingsTitles = [NSArray arrayWithObjects:@"fetchLimit", @"syncInterval", @"syncServerURI", @"xmlNamespace", nil];
        NSArray *mapViewSettingsTitles = [NSArray arrayWithObjects:@"mapHeading", @"mapType", nil];
        NSArray *authServiceSettingsTitles = [NSArray arrayWithObjects:@"tokenServerURL", @"authServiceURI", @"authServiceParameters", nil];
        _settingsTitles = [NSArray arrayWithObjects: trackerSettingsTitles, syncerSettingsTitles, mapViewSettingsTitles, authServiceSettingsTitles, nil];
//        NSLog(@"_settingsTitles %@", _settingsTitles);
    }
    return _settingsTitles;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return self.settingsTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[self.settingsTitles objectAtIndex:section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"Tracker";
    } else if (section == 1) {
        return @"Syncer";
    } else if (section == 2) {
        return @"MapView";
    } else if (section == 3) {
        return @"AuthService";
    } else {
        return @"";
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == 4) {
            return 44.0;
        } else {
            return 70.0;
        }
    } else if (indexPath.section == 1) {
        return 70.0;
    } else if (indexPath.section == 2) {
        return 44.0;
    } else if (indexPath.section == 3) {
        return 70.0;
    } else {
        return 0.0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"settingsCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }

    UILabel *cellLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 220, 24)];
    NSString *settingsName = [[self.settingsTitles objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    cellLabel.text = settingsName;
    cellLabel.font = [UIFont boldSystemFontOfSize:20];
    cellLabel.tag = 1;
    [cell.contentView addSubview:cellLabel];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UILabel *valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(230, 10, 80, 24)];
    valueLabel.font = [UIFont boldSystemFontOfSize:20];
    valueLabel.textAlignment = NSTextAlignmentRight;
    valueLabel.text = [NSString stringWithFormat:@"%@", [self.settings valueForKey:settingsName]];
    valueLabel.tag = 2;

    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(25, 38, 270, 24)];
    slider.tag = 3;
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];

    UISwitch *headingSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(230, 9, 80, 27)];
    [headingSwitch setOn:[[self.settings valueForKey:settingsName] boolValue] animated:NO];
    [headingSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
    headingSwitch.tag = 4;
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(25, 38, 270, 24)];
    textField.text = [NSString stringWithFormat:@"%@", [self.settings valueForKey:settingsName]];
    textField.keyboardType = UIKeyboardTypeURL;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.tag = 6;
    textField.delegate = self;

    double numericValue = [[self.settings valueForKey:settingsName] doubleValue];
    
    if (indexPath.section == 0) {

        if ([settingsName isEqualToString:@"trackerAutoStart"]) {
            
            [cell.contentView addSubview:headingSwitch];
            
        } else {
            
            if ([settingsName isEqualToString:@"trackDetectionTime"]) {
                
                cellLabel.text = [NSString stringWithFormat:@"%@, s", settingsName];
                slider.maximumValue = 600.0;
                slider.minimumValue = 0.0;
                
            } else if ([settingsName isEqualToString:@"trackerStartTime"] || [settingsName isEqualToString:@"trackerFinishTime"]){
                slider.minimumValue = 0.0;
                slider.maximumValue = 24.0;
                double time = [[self.settings valueForKey:settingsName] doubleValue];
                double hours = floor(time);
                double minutes = rint((time - floor(time)) * 60);
                NSNumberFormatter *timeFormatter = [[NSNumberFormatter alloc] init];
                timeFormatter.formatWidth = 2;
                timeFormatter.paddingCharacter = @"0";
                valueLabel.text = [NSString stringWithFormat:@"%@:%@", [timeFormatter stringFromNumber:[NSNumber numberWithDouble:hours]], [timeFormatter stringFromNumber:[NSNumber numberWithDouble:minutes]]];

            } else {
                
                cellLabel.text = [NSString stringWithFormat:@"%@, m", settingsName];
                
                if ([settingsName isEqualToString:@"requiredAccuracy"]) {
                    slider.maximumValue = 100.0;
                    slider.minimumValue = 5.0;
                } else if ([settingsName isEqualToString:@"distanceFilter"]) {
                    slider.maximumValue = 200.0;
                    slider.minimumValue = -1.0;
                } else if ([settingsName isEqualToString:@"desiredAccuracy"]) {
                    NSArray *accuracyArray = [NSArray arrayWithObjects: [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation],
                                              [NSNumber numberWithDouble:kCLLocationAccuracyBest],
                                              [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters],
                                              [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters],
                                              [NSNumber numberWithDouble:kCLLocationAccuracyKilometer],
                                              [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers],nil];
                    slider.maximumValue = accuracyArray.count - 1;
                    slider.minimumValue = 0;
                    numericValue = [accuracyArray indexOfObject:[NSNumber numberWithDouble:numericValue]];
                    if (numericValue == NSNotFound) {
                        NSLog(@"NSNotFoundS");
                        numericValue = [accuracyArray indexOfObject:[NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters]];
                        [self.settings setValue:[NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters] forKey:settingsName];
                    }
                }
            }
            [slider setValue:numericValue animated:NO];
            [cell.contentView addSubview:slider];
            [cell.contentView addSubview:valueLabel];

        }

    } else if (indexPath.section == 1) {
        
        if ([settingsName isEqualToString:@"syncInterval"]) {
            cellLabel.text = [NSString stringWithFormat:@"%@, s", settingsName];
            slider.maximumValue = 3600.0;
            slider.minimumValue = 10.0;
        } else if ([settingsName isEqualToString:@"fetchLimit"]) {
            slider.maximumValue = 100.0;
            slider.minimumValue = 5.0;
        }
        if ([settingsName isEqualToString:@"fetchLimit"] || [settingsName isEqualToString:@"syncInterval"]) {
            [slider setValue:numericValue animated:NO];
            [cell.contentView addSubview:slider];
            [cell.contentView addSubview:valueLabel];
        } else {
            [cell.contentView addSubview:textField];
        }
        
    } else if (indexPath.section == 2) {
        
        if ([settingsName isEqualToString:@"mapHeading"]) {
            [cell.contentView addSubview:headingSwitch];
            
        } else if ([settingsName isEqualToString:@"mapType"]) {
            NSArray *segments = [NSArray arrayWithObjects: @"Map", @"Satellite", @"Hybrid", nil];
            UISegmentedControl *mapTypeControl = [[UISegmentedControl alloc] initWithItems:segments];
            mapTypeControl.frame = CGRectMake(110, 7, 200, 30);
            mapTypeControl.segmentedControlStyle = UISegmentedControlStylePlain;
            NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[UIFont boldSystemFontOfSize:14], UITextAttributeFont,
                                            nil];
            [mapTypeControl setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
            [mapTypeControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
            mapTypeControl.selectedSegmentIndex = [self.settings.mapType integerValue];
            mapTypeControl.tag = 5;
            [cell.contentView addSubview:mapTypeControl];
        }
        
    } else if (indexPath.section == 3) {
        
        [cell.contentView addSubview:textField];
        
    }

    return cell;
}



- (void)sliderValueChanged:(UISlider *)sender {
    if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"requiredAccuracy"].location != NSNotFound) {
        [sender setValue:rint(sender.value/10)*10];
        self.settings.requiredAccuracy = [NSNumber numberWithDouble:sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"desiredAccuracy"].location != NSNotFound) {
        NSArray *accuracyArray = [NSArray arrayWithObjects: [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyBest],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyKilometer],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers],nil];
        [sender setValue:rint(sender.value)];
        self.settings.desiredAccuracy = [accuracyArray objectAtIndex:(NSUInteger)sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"distanceFilter"].location != NSNotFound) {
        [sender setValue:floor(sender.value/10)*10];
        self.settings.distanceFilter = [NSNumber numberWithDouble:sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"trackDetectionTime"].location != NSNotFound) {
        [sender setValue:rint(sender.value/30)*30];
        self.settings.trackDetectionTime = [NSNumber numberWithDouble:sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"syncInterval"].location != NSNotFound) {
        [sender setValue:rint(sender.value/60)*60];
        self.settings.syncInterval = [NSNumber numberWithDouble:sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"fetchLimit"].location != NSNotFound) {
        [sender setValue:rint(sender.value/5)*5];
        self.settings.fetchLimit = [NSNumber numberWithDouble:sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"trackerStartTime"].location != NSNotFound) {
        [sender setValue:rint(sender.value/0.5)*0.5];
        self.settings.trackerStartTime = [NSNumber numberWithDouble:sender.value];
    } else if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"trackerFinishTime"].location != NSNotFound) {
        [sender setValue:rint(sender.value/0.5)*0.5];
        self.settings.trackerFinishTime = [NSNumber numberWithDouble:sender.value];        
    }
}

- (void)switchValueChanged:(UISwitch *)sender {
    if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"mapHeading"].location != NSNotFound) {
        self.settings.mapHeading = [NSNumber numberWithBool:sender.on];
    } else if (([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"trackerAutoStart"].location != NSNotFound)) {
        self.settings.trackerAutoStart = [NSNumber numberWithBool:sender.on];
    }
}

- (void)segmentedControlValueChanged:(UISegmentedControl *)sender {
    if ([[(UILabel *)[sender.superview viewWithTag:1] text] rangeOfString:@"mapType"].location != NSNotFound) {
        self.settings.mapType = [NSNumber numberWithInteger:sender.selectedSegmentIndex];
    }
}



#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
//    NSLog(@"textFieldShouldEndEditing");
//    NSLog(@"%@", [(UILabel *)[textField.superview viewWithTag:1] text]);
    [self.settings setValue:textField.text forKey:[(UILabel *)[textField.superview viewWithTag:1] text]];
    return YES;
}


#pragma mark - observeValueForKeyPath

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
//    NSLog(@"observeValueForKeyPath %@", keyPath);
//    NSLog(@"object %@", object);
//    NSLog(@"change %@", change);

    int i = 0;
    int section = 0;
    int row = 0;
    BOOL gotcha = NO;
    for (NSArray *array in self.settingsTitles) {
        if ([array containsObject:keyPath]) {
            row = [array indexOfObject:keyPath];
            section = i;
            gotcha = YES;
        }
        i++;
    }

    if (gotcha) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
        
        NSArray *slidersLabels = [NSArray arrayWithObjects: @"requiredAccuracy",
                                                            @"distanceFilter",
                                                            @"trackDetectionTime",
                                                            @"syncInterval",
                                                            @"fetchLimit", nil];
        if ([slidersLabels containsObject:keyPath]) {
            UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:2];
            valueLabel.text = [NSString stringWithFormat:@"%@", [self.settings valueForKey:keyPath]];
            UISlider *slider = (UISlider *)[cell.contentView viewWithTag:3];
            [slider setValue:[[self.settings valueForKey:keyPath] doubleValue] animated:YES];
            
        } else if ([keyPath isEqualToString:@"desiredAccuracy"]) {
            NSArray *accuracyArray = [NSArray arrayWithObjects: [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation],
                                      [NSNumber numberWithDouble:kCLLocationAccuracyBest],
                                      [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters],
                                      [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters],
                                      [NSNumber numberWithDouble:kCLLocationAccuracyKilometer],
                                      [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers],nil];
            UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:2];
            valueLabel.text = [NSString stringWithFormat:@"%@", self.settings.desiredAccuracy];
            UISlider *slider = (UISlider *)[cell.contentView viewWithTag:3];
            [slider setValue:[accuracyArray indexOfObject:self.settings.desiredAccuracy] animated:YES];
            
        } else if ([keyPath isEqualToString:@"trackerStartTime"] || [keyPath isEqualToString:@"trackerFinishTime"]) {
            UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:2];
            double time = [[self.settings valueForKey:keyPath] doubleValue];
            double hours = floor(time);
            double minutes = rint((time - floor(time)) * 60);
            NSNumberFormatter *timeFormatter = [[NSNumberFormatter alloc] init];
            timeFormatter.formatWidth = 2;
            timeFormatter.paddingCharacter = @"0";
            valueLabel.text = [NSString stringWithFormat:@"%@:%@", [timeFormatter stringFromNumber:[NSNumber numberWithDouble:hours]], [timeFormatter stringFromNumber:[NSNumber numberWithDouble:minutes]]];
            UISlider *slider = (UISlider *)[cell.contentView viewWithTag:3];
            [slider setValue:[[self.settings valueForKey:keyPath] doubleValue] animated:YES];
            
        } else if ([keyPath isEqualToString:@"mapHeading"] || [keyPath isEqualToString:@"trackerAutoStart"]) {
            UISwitch *headingSwitch = (UISwitch *)[cell.contentView viewWithTag:4];
            [headingSwitch setOn:[[self.settings valueForKey:keyPath] boolValue] animated:YES];
            
        } else if ([keyPath isEqualToString:@"mapType"]) {
            UISegmentedControl *segmentedControl = (UISegmentedControl *)[cell.contentView viewWithTag:5];
            segmentedControl.selectedSegmentIndex = [self.settings.mapType integerValue];
        }

    }
    
}


#pragma mark - View lifecycle

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
        
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
    for (NSString *settingsName in [self.settings.entity.propertiesByName allKeys]) {
        [self.settings addObserver:self forKeyPath:settingsName options:NSKeyValueObservingOptionNew context:nil];
    }
    
//    NSLog(@"self.settings.lts %@", self.settings.lts);
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    for (NSString *settingsName in [self.settings.entity.propertiesByName allKeys]) {
        [self.settings removeObserver:self forKeyPath:settingsName];
    }
    [[STGTTrackingLocationController sharedTracker].locationsDatabase saveToURL:[STGTTrackingLocationController sharedTracker].locationsDatabase.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:^(BOOL success) {
        NSLog(@"settingViewWillDisappear UIDocumentSaveForOverwriting success");
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
