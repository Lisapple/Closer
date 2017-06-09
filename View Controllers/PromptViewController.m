//
//  PromptViewController.m
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import "PromptViewController.h"

@interface PromptViewController ()

@property (nonatomic, strong) NSArray * cellsTitle;

@end

@implementation PromptViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Ask to Continue", nil);
	
	self.tableView.alwaysBounceVertical = YES;
	
	_cellsTitle = @[NSLocalizedString(@"Never", nil), NSLocalizedString(@"At the end of each timer", nil), NSLocalizedString(@"When all timers are finished", nil)];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	/* Three for "Never", "At the end of each timer" and "When all timers are finished" */
	return _cellsTitle.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return NSLocalizedString(@"An alert can be shown to ask you to continue the timer.", nil);
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	cell.textLabel.text = _cellsTitle[indexPath.row];
	cell.accessoryType = (_countdown.promptState == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	_countdown.promptState = indexPath.row;
	
	for (NSInteger row = 0; row < _cellsTitle.count; row++) {
		if (row != indexPath.row) {
			[self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:row inSection:0] ]
							  withRowAnimation:UITableViewRowAnimationNone];
		}
	}
	
	UITableViewCell * cell = [self.tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
