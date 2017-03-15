//
//  DurationsViewController.m
//  Closer
//
//  Created by Maxime Leroy on 6/18/13.
//
//

#import "DurationsViewController.h"
#import "PromptViewController.h"
#import "DurationPickerViewController.h"

@implementation DurationsViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Durations", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.alwaysBounceVertical = YES;
	_tableView.allowsSelectionDuringEditing = YES;
	_tableView.editing = YES;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self action:@selector(addAction:)];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reloadData];
}

- (void)updateUI
{
	/* Show a placeholder "No Durations" if the timer has no durations */
	if (_countdown.durations.count == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, 40.);
		UIButton * button = [[UIButton alloc] initWithFrame:frame];
		button.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		button.titleLabel.font = [UIFont boldSystemFontOfSize:18.];
		[button setTitle:NSLocalizedString(@"Add Duration", nil) forState:UIControlStateNormal];
		[button addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
		_tableView.tableFooterView = button;
	} else
		_tableView.tableFooterView = nil;
}

- (void)reloadData
{
	[self updateUI];
	[_tableView reloadData];
}

- (IBAction)addAction:(id)sender
{
	[self showAddDurationWithAnimation:YES];
}

- (void)showAddDurationWithAnimation:(BOOL)animated
{
	[_countdown addDuration:@0 withName:nil];
	
	NSInteger index = _countdown.durations.count - 1;
	DurationPickerViewController * controller = [[DurationPickerViewController alloc] init];
	controller.countdown = self.countdown;
	controller.durationIndex = index;
	[self.navigationController pushViewController:controller animated:animated];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2; // Two for prompt and durations
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	
	return _countdown.durations.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		static NSString * promptCellIdentifier = @"PromptCellID";
		UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:promptCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:promptCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		cell.textLabel.text = NSLocalizedString(@"Ask", nil);
		
		switch (_countdown.promptState) {
			case PromptStateNone:
				cell.detailTextLabel.text = NSLocalizedString(@"Never", nil);
				break;
			case PromptStateEveryTimers:
				cell.detailTextLabel.text = NSLocalizedString(@"For every duration", nil);
				break;
			case PromptStateEnd:
				cell.detailTextLabel.text = NSLocalizedString(@"When all durations finished", nil);
				break;
		}
		return cell;
		
	} else {
		static NSString * cellIdentifier = @"CellID";
		UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
		
		NSString * name = (indexPath.row < _countdown.names.count) ? _countdown.names[indexPath.row] : nil;
		if (name.length > 0) {
			cell.textLabel.text = name;
			cell.detailTextLabel.text = [_countdown descriptionOfDurationAtIndex:indexPath.row];
			CGSize size = [cell.detailTextLabel sizeThatFits:CGSizeMake(cell.detailTextLabel.frame.size.width, INFINITY)];
			if (size.height > cell.detailTextLabel.frame.size.height || size.width > cell.detailTextLabel.frame.size.width)
				cell.detailTextLabel.text = [_countdown shortDescriptionOfDurationAtIndex:indexPath.row];
		} else {
			cell.textLabel.text = [_countdown descriptionOfDurationAtIndex:indexPath.row];
			CGSize size = [cell.textLabel sizeThatFits:CGSizeMake(cell.textLabel.frame.size.width, INFINITY)];
			if (size.height > cell.textLabel.frame.size.height || size.width > cell.textLabel.frame.size.width)
				cell.textLabel.text = [_countdown shortDescriptionOfDurationAtIndex:indexPath.row];
		}
		return cell;
	}
	
	return nil;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section == 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NSLocalizedString(@"Remove", nil);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 1)
		return UITableViewCellEditingStyleDelete;
	
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		[_tableView beginUpdates];
		{
			[_countdown removeDurationAtIndex:indexPath.row];
			
			[_tableView deleteRowsAtIndexPaths:@[ indexPath ]
							  withRowAnimation:UITableViewRowAnimationFade];
		}
		[_tableView endUpdates];
		[self updateUI];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	/* Moving is allowed only for the "duration" section */
	return (indexPath.section == 1);
}

- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	[_countdown moveDurationAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
	[self updateUI];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section ==  0) {
		PromptViewController * promptViewController = [[PromptViewController alloc] init];
		promptViewController.countdown = self.countdown;
		[self.navigationController pushViewController:promptViewController animated:YES];
		
	} else {
		DurationPickerViewController * durationPickerViewController = [[DurationPickerViewController alloc] init];
		durationPickerViewController.countdown = self.countdown;
		durationPickerViewController.durationIndex = indexPath.row;
		[self.navigationController pushViewController:durationPickerViewController animated:YES];
	}
	
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
