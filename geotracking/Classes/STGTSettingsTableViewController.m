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
        NSArray *generalSettingsTitles = [NSArray arrayWithObjects:@"localAccessToSettings", nil];
        NSArray *trackerSettingsTitles = [NSArray arrayWithObjects:@"desiredAccuracy", @"requiredAccuracy", @"distanceFilter", @"trackDetectionTime", @"trackerAutoStart", @"trackerStartTime", @"trackerFinishTime", nil];
        NSArray *syncerSettingsTitles = [NSArray arrayWithObjects:@"fetchLimit", @"syncInterval", @"syncServerURI", @"xmlNamespace", nil];
        NSArray *mapViewSettingsTitles = [NSArray arrayWithObjects:@"mapHeading", @"mapType", @"trackScale", nil];
        NSArray *authServiceSettingsTitles = [NSArray arrayWithObjects:@"tokenServerURL", @"authServiceURI", @"authServiceParameters", nil];
        _settingsTitles = [NSArray arrayWithObjects:generalSettingsTitles, trackerSettingsTitles, syncerSettingsTitles, mapViewSettingsTitles, authServiceSettingsTitles, nil];
//        NSLog(@"_settingsTitles %@", _settingsTitles);
    }
    return _settingsTitles;
}


- (void)setupCells {

    int section = 0;
    for (NSArray *settingsGroup in self.settingsTitles) {
        int row = 0;
        for (NSString *settingName in settingsGroup) {
//            NSLog(@"settingsName %@", settingsName);
            UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
//            UILabel *cellLabel = (UILabel *)[cell.contentView viewWithTag:1];
            
            UILabel *valueLabel = (UILabel *)[cell.contentView viewWithTag:2];
            if ([settingName isEqualToString:@"trackerStartTime"] || [settingName isEqualToString:@"trackerFinishTime"]){
                double time = [[self.settings valueForKey:settingName] doubleValue];
                double hours = floor(time);
                double minutes = rint((time - floor(time)) * 60);
                NSNumberFormatter *timeFormatter = [[NSNumberFormatter alloc] init];
                timeFormatter.formatWidth = 2;
                timeFormatter.paddingCharacter = @"0";
                valueLabel.text = [NSString stringWithFormat:@"%@:%@", [timeFormatter stringFromNumber:[NSNumber numberWithDouble:hours]], [timeFormatter stringFromNumber:[NSNumber numberWithDouble:minutes]]];

            } else {
                valueLabel.text = [NSString stringWithFormat:@"%@", [self.settings valueForKey:settingName]];                
            }
            
            UISlider *slider = (UISlider *)[cell.contentView viewWithTag:3];
            [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            double numericValue = [[self.settings valueForKey:settingName] doubleValue];
            if ([settingName isEqualToString:@"desiredAccuracy"]) {
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
                    [self.settings setValue:[NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters] forKey:settingName];
                }
            }
            [slider setValue:numericValue animated:NO];
            
            UISwitch *cellSwitch = (UISwitch *)[cell.contentView viewWithTag:4];
            [cellSwitch setOn:[[self.settings valueForKey:settingName] boolValue] animated:NO];
            [cellSwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];

            UISegmentedControl *segmentedControl = (UISegmentedControl *)[cell.contentView viewWithTag:5];
            [segmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
            segmentedControl.selectedSegmentIndex = [self.settings.mapType integerValue];
            
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:6];
            textField.text = [NSString stringWithFormat:@"%@", [self.settings valueForKey:settingName]];
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.delegate = self;
            
            row++;
        }
        section++;
    }
    [self localAccessToSettings];
}

- (void)removeTargets {

    int section = 0;
    for (NSArray *settingsGroup in self.settingsTitles) {
        int row = 0;
        for (NSString *settingName in settingsGroup) {
//            NSLog(@"settingName %@", settingsName);
            UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
            UISlider *slider = (UISlider *)[cell.contentView viewWithTag:3];
            [slider removeTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            UISwitch *cellSwitch = (UISwitch *)[cell.contentView viewWithTag:4];
            [cellSwitch removeTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            UISegmentedControl *segmentedControl = (UISegmentedControl *)[cell.contentView viewWithTag:5];
            [segmentedControl removeTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:6];
            textField.delegate = nil;
            
            row++;
        }
        section++;
    }
    
}


- (void)sliderValueChanged:(UISlider *)sender {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
    NSString *settingName = [[self.settingsTitles objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    
    if ([settingName isEqualToString:@"requiredAccuracy"]) {
        [sender setValue:rint(sender.value/10)*10];
        self.settings.requiredAccuracy = [NSNumber numberWithDouble:sender.value];
    } else if ([settingName isEqualToString:@"desiredAccuracy"]) {
        NSArray *accuracyArray = [NSArray arrayWithObjects: [NSNumber numberWithDouble:kCLLocationAccuracyBestForNavigation],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyBest],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyNearestTenMeters],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyHundredMeters],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyKilometer],
                                  [NSNumber numberWithDouble:kCLLocationAccuracyThreeKilometers],nil];
        [sender setValue:rint(sender.value)];
        self.settings.desiredAccuracy = [accuracyArray objectAtIndex:(NSUInteger)sender.value];
    } else if ([settingName isEqualToString:@"distanceFilter"]) {
        [sender setValue:floor(sender.value/10)*10];
        self.settings.distanceFilter = [NSNumber numberWithDouble:sender.value];
    } else if ([settingName isEqualToString:@"trackDetectionTime"]) {
        [sender setValue:rint(sender.value/30)*30];
        self.settings.trackDetectionTime = [NSNumber numberWithDouble:sender.value];
    } else if ([settingName isEqualToString:@"syncInterval"]) {
        [sender setValue:rint(sender.value/60)*60];
        self.settings.syncInterval = [NSNumber numberWithDouble:sender.value];
    } else if ([settingName isEqualToString:@"fetchLimit"]) {
        [sender setValue:rint(sender.value/5)*5];
        self.settings.fetchLimit = [NSNumber numberWithDouble:sender.value];
    } else if ([settingName isEqualToString:@"trackerStartTime"]) {
        [sender setValue:rint(sender.value/0.5)*0.5];
        self.settings.trackerStartTime = [NSNumber numberWithDouble:sender.value];
    } else if ([settingName isEqualToString:@"trackerFinishTime"]) {
        [sender setValue:rint(sender.value/0.5)*0.5];
        self.settings.trackerFinishTime = [NSNumber numberWithDouble:sender.value];        
    } else if ([settingName isEqualToString:@"trackScale"]) {
        [sender setValue:rint(sender.value/0.5)*0.5];
        self.settings.trackScale = [NSNumber numberWithDouble:sender.value];
    }
}

- (void)switchValueChanged:(UISwitch *)sender {
    
    NSIndexPath *indexPath = [self.tableView indexPathForCell:(UITableViewCell *)sender.superview.superview];
    NSString *settingName = [[self.settingsTitles objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    [self.settings setValue:[NSNumber numberWithBool:sender.on] forKey:settingName];
    
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
                                                            @"fetchLimit",
                                                            @"trackScale", nil];
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
            
        } else if ([keyPath isEqualToString:@"mapHeading"] ||
                   [keyPath isEqualToString:@"trackerAutoStart"] ||
                   [keyPath isEqualToString:@"localAccessToSettings"]) {
            UISwitch *switchButton = (UISwitch *)[cell.contentView viewWithTag:4];
            [switchButton setOn:[[self.settings valueForKey:keyPath] boolValue] animated:YES];
            if ([keyPath isEqualToString:@"localAccessToSettings"]) {
                [self localAccessToSettings];
            }
            
        } else if ([keyPath isEqualToString:@"mapType"]) {
            UISegmentedControl *segmentedControl = (UISegmentedControl *)[cell.contentView viewWithTag:5];
            segmentedControl.selectedSegmentIndex = [[self.settings valueForKey:keyPath] integerValue];
        } else if ([keyPath isEqualToString:@"syncServerURI"] ||
                   [keyPath isEqualToString:@"xmlNamespace"] ||
                   [keyPath isEqualToString:@"tockenServerURL"] ||
                   [keyPath isEqualToString:@"authServiceURI"] ||
                   [keyPath isEqualToString:@"authServiceParameters"]) {
            UITextField *textField = (UITextField *)[cell.contentView viewWithTag:6];
            textField.text = [self.settings valueForKey:keyPath];
        }

    }
    
}

- (void)localAccessToSettings {
    
    int section = 0;
    for (NSArray *array in self.settingsTitles) {
        int row = 0;
        NSString *sectionTitle = [self tableView:self.tableView titleForHeaderInSection:section];
        if (![sectionTitle isEqualToString:@"General settings"] && ![sectionTitle isEqualToString:@"MapView"]) {
            for (NSString *settingName in array) {
                UITableViewCell *cell = [self tableView:self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:row inSection:section]];
                UISlider *slider = (UISlider *)[cell.contentView viewWithTag:3];
                UISwitch *switchButton = (UISwitch *)[cell.contentView viewWithTag:4];
                UISegmentedControl *segmentedControl = (UISegmentedControl *)[cell.contentView viewWithTag:5];
                UITextField *textField = (UITextField *)[cell.contentView viewWithTag:6];
                slider.enabled = [self.settings.localAccessToSettings boolValue];
                switchButton.enabled = [self.settings.localAccessToSettings boolValue];
                segmentedControl.enabled = [self.settings.localAccessToSettings boolValue];
                textField.enabled = [self.settings.localAccessToSettings boolValue];
                row++;
            }
        }
        section++;
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
    [self setupCells];
    for (NSString *settingsName in [self.settings.entity.propertiesByName allKeys]) {
        [self.settings addObserver:self forKeyPath:settingsName options:NSKeyValueObservingOptionNew context:nil];
    }

//    NSLog(@"self.settings.lts %@", self.settings.lts);
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self removeTargets];
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
