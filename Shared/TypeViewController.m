//
//  TypeViewController.m
//  Closer
//
//  Created by Maxime Leroy on 6/17/13.
//
//

#import "TypeViewController.h"

@interface TypeViewController ()

@end

@implementation TypeViewController

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Type", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.alwaysBounceVertical = YES;
	
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2; // "Countdown" and "Timer"
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return NSLocalizedString(@"Countdowns allow you to watch the duration until a precise date, timers are used to measure small periods.", nil);
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	switch (indexPath.row) {
		case 1:
			cell.textLabel.text = NSLocalizedString(@"Timer", nil); break;
		default:
			cell.textLabel.text = NSLocalizedString(@"Countdown", nil); break;
	}
	cell.accessoryType = (_countdown.type == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	_countdown.type = indexPath.row;
	
	if (indexPath.row == 0) {
		[_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]]
						  withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
						  withRowAnimation:UITableViewRowAnimationNone];
	}
	
	UITableViewCell * cell = [_tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
