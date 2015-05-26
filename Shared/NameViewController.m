//
//  NameViewController.m
//  Closer
//
//  Created by Max on 3/2/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NameViewController.h"

@implementation NameViewController

@synthesize cellTextField;
@synthesize tableView;

@synthesize countdown;

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Name", nil);
	self.view.tintColor = [UIColor blackColor];
	
	tableView.delegate = self;
	tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    tableView.alwaysBounceVertical = YES;
	
	cellTextField.text = countdown.name;
	cellTextField.delegate = self;
	
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (countdown.type == CountdownTypeTimer) {
        return NSLocalizedString(@"The name of the timer can help you to identify it.", nil);
    }
	return NSLocalizedString(@"The name of the countdown can help you to identify it.", nil);
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

@end
