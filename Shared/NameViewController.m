//
//  NameViewController.m
//  Closer
//
//  Created by Max on 3/2/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NameViewController.h"

#import "UIColor+addition.h"
#import "UITableView+addition.h"

@implementation NameViewController

@synthesize cellTextField;
@synthesize tableView;

@synthesize countdown;

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Name", nil);
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.alwaysBounceVertical = YES;
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView = backgroundView;
	
	cellTextField.text = countdown.name;
	cellTextField.delegate = self;
	
	[tableView setFooterText:NSLocalizedString(@"The name of the countdown can help you to identify it.", nil)];
	
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated
{
	[cellTextField becomeFirstResponder];
	
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	countdown.name = cellTextField.text;
	[Countdown synchronize];
	
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (orientation == UIInterfaceOrientationPortrait || orientation == UIInterfaceOrientationPortraitUpsideDown)
		return @" ";
	else
		return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		[cell.contentView addSubview:cellTextField];
	}
	
	return cell;
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self.navigationController popViewControllerAnimated:YES];
	return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
	[tableView reloadData];
	[cellTextField becomeFirstResponder];
	
	[super willAnimateRotationToInterfaceOrientation:orientation duration:duration];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	self.cellTextField = nil;
	self.tableView = nil;
	
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}



@end
