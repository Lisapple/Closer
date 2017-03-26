//
//  NameViewController.m
//  Closer
//
//  Created by Max on 3/2/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "NameViewController.h"

@interface NameViewController ()

@property (nonatomic, assign) IBOutlet UITextField * cellTextField;
@property (nonatomic, assign) IBOutlet UITableView * tableView;

@end

@implementation NameViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Name", nil);
	
	self.tableView.alwaysBounceVertical = YES;
	
	_cellTextField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_cellTextField.text = _countdown.name;
	_cellTextField.delegate = self;
}

- (void)viewDidAppear:(BOOL)animated
{
	[_cellTextField becomeFirstResponder];
	
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	_countdown.name = _cellTextField.text;
	[Countdown synchronize];
	
	[super viewWillDisappear:animated];
}

#pragma mark - Table view data source

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	return UIInterfaceOrientationIsPortrait(orientation) ? 50 : 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell.contentView addSubview:_cellTextField];
	}
	return cell;
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[self.navigationController popViewControllerAnimated:YES];
	return YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	
	[_tableView reloadData];
	[_cellTextField becomeFirstResponder];
}

@end
