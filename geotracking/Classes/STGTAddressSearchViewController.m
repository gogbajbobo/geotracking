//
//  AddressSearchViewController.m
//  geotracking
//
//  Created by Maxim Grigoriev on 12/15/12.
//  Copyright (c) 2012 Maxim V. Grigoriev. All rights reserved.
//

#import "STGTAddressSearchViewController.h"
#import "STGTSpot.h"

@interface STGTAddressSearchViewController () <UISearchDisplayDelegate>
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) NSArray *filteredListContent;
@property (nonatomic, strong) NSArray *listContent;
@property (nonatomic, strong) STGTSpot *filterSpot;

@end

@implementation STGTAddressSearchViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"viewWillAppear");

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"STGTSpot"];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"label" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.predicate = [NSPredicate predicateWithFormat:@"SELF.label == %@", @"@filter"];
    NSError *error;
    self.filterSpot = [[self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error] lastObject];
    request.predicate = nil;
    request.predicate = [NSPredicate predicateWithFormat:@"(SELF.address != NIL) AND (ANY SELF.interests IN %@ || ANY SELF.networks IN %@ || (SELF.interests.@count == 0 && SELF.networks.@count == 0))", self.filterSpot.interests, self.filterSpot.networks];
    self.listContent = [self.tracker.locationsDatabase.managedObjectContext executeFetchRequest:request error:&error];
    NSLog(@"self.listContent %@", self.listContent);
    self.filteredListContent = [NSMutableArray array];

    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.searchController = [[UISearchDisplayController alloc]
                             initWithSearchBar:self.searchBar contentsController:self];
    self.searchController.delegate = self;
    self.searchController.searchResultsDataSource = self;
    self.searchController.searchResultsDelegate = self;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [self.filteredListContent count];
    }
	else {
        return [self.listContent count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addressCell"];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"addressCell"];
	}

	STGTSpot *spot = nil;
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        spot = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else {
        spot = [self.listContent objectAtIndex:indexPath.row];
    }
	
	cell.textLabel.text = spot.address;
//    NSLog(@"cell %@", cell);
	return cell;

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (tableView == self.searchDisplayController.searchResultsTableView) {
        self.mapVC.filteredSpot = [self.filteredListContent objectAtIndex:indexPath.row];
    }
	else {
        self.mapVC.filteredSpot = [self.listContent objectAtIndex:indexPath.row];
    }
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchDisplayController Delegate Methods

- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.address CONTAINS[cd] %@", searchString];
    self.filteredListContent = [self.listContent filteredArrayUsingPredicate:predicate];

    return YES;
}



@end
