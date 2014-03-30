//
//  PageThemeViewController.m
//  Closer
//
//  Created by Max on 11/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "PageThemeViewController.h"

#import "Countdown.h"

#import "PageThemeTableViewCell.h"

#import "UIColor+addition.h"

@implementation PageThemeViewController

@synthesize tableView;
@synthesize countdown;


- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Theme", nil);
	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.rowHeight = 71.;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView = backgroundView;
	
	[super viewDidLoad];
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 5;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	PageThemeTableViewCell * cell = (PageThemeTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[PageThemeTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	if (countdown.style == indexPath.row) {// Default style == 0
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		checkedCell = cell;
	}
	
	
	if (indexPath.row == 0) {
		cell.imageView.image = [UIImage imageNamed:@"theme1_preview"];
	} else if (indexPath.row == 1) {
		cell.imageView.image = [UIImage imageNamed:@"theme2_preview"];
	} else if (indexPath.row == 2) {
		cell.imageView.image = [UIImage imageNamed:@"theme3_preview"];
	} else if (indexPath.row == 3) {
		cell.imageView.image = [UIImage imageNamed:@"theme4_preview"];
	} else {
		cell.imageView.image = [UIImage imageNamed:@"theme5_preview"];
	}
	
	cell.textLabel.text = [[Countdown styles] objectAtIndex:indexPath.row];
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	PageThemeTableViewCell * cell = (PageThemeTableViewCell *)[aTableView cellForRowAtIndexPath:indexPath];
	
	if (cell != checkedCell) {
		checkedCell.accessoryType = UITableViewCellAccessoryNone;
		
		checkedCell = cell;
		checkedCell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		countdown.style = indexPath.row;
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
	self.tableView = nil;
	
	[super viewDidUnload];
}




@end
