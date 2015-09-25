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

@interface DurationsViewController ()

@end

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
																						   target:self
																						   action:@selector(addAction:)];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
	NSArray * durationsCopy = _countdown.durations.copy;
	for (NSNumber * duration in durationsCopy) {
		if (duration.integerValue == 0) { // Remove empty durations
			NSInteger index = [_countdown.durations indexOfObject:duration];
			if (index != NSNotFound)
				[_countdown removeDurationAtIndex:index];
		}
	}
	
	[self reloadData];
}

- (void)reloadData
{
	/* Show a placeholder "No Durations" if the timer has no durations */
	if (_countdown.durations.count == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, 40.);
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		label.backgroundColor = [UIColor clearColor];
		label.lineBreakMode = NSLineBreakByWordWrapping;
		label.numberOfLines = 0;// Infinite number of line
		label.textColor = [UIColor darkGrayColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.font = [UIFont boldSystemFontOfSize:18.];
		label.shadowColor = [UIColor colorWithWhite:1. alpha:0.7];
		label.shadowOffset = CGSizeMake(0., 1.);
		
		label.text = NSLocalizedString(@"No Durations", nil);
		
		_tableView.tableFooterView = label;
	} else {
		_tableView.tableFooterView = nil;
	}
	
	[_tableView reloadData];
}

- (IBAction)addAction:(id)sender
{
	[_tableView beginUpdates];
	
	[_countdown addDuration:@0];
	
	NSIndexPath * indexPath = [NSIndexPath indexPathForRow:(_countdown.durations.count - 1)
												 inSection:1];
	[_tableView insertRowsAtIndexPaths:@[indexPath]
					  withRowAnimation:UITableViewRowAnimationFade];
	[_tableView endUpdates];
	
	[_tableView selectRowAtIndexPath:indexPath
							animated:YES
					  scrollPosition:UITableViewScrollPositionMiddle];
	
	/* Show the DurationPicker for the created duration */
	DurationPickerViewController * durationPickerViewController = [[DurationPickerViewController alloc] init];
	durationPickerViewController.countdown = self.countdown;
	durationPickerViewController.durationIndex = indexPath.row;
	[self.navigationController pushViewController:durationPickerViewController animated:YES];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	/* Two for prompt and durations */
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return 1;
	
	return _countdown.durations.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	if (indexPath.section == 0) {
		cell.textLabel.text = NSLocalizedString(@"Ask", nil);
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
		cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
		cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		
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
		
	} else {
		cell.textLabel.text = [_countdown descriptionOfDurationAtIndex:indexPath.row];
		CGSize size = [cell.textLabel sizeThatFits:CGSizeMake(cell.textLabel.frame.size.width, INFINITY)];
		if (size.height > cell.textLabel.frame.size.height || size.width > cell.textLabel.frame.size.width)
			cell.textLabel.text = [_countdown shortDescriptionOfDurationAtIndex:indexPath.row];
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
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
		
		[_countdown removeDurationAtIndex:indexPath.row];
		
		[_tableView deleteRowsAtIndexPaths:@[indexPath]
						  withRowAnimation:UITableViewRowAnimationFade];
		[_tableView endUpdates];
		[self reloadData];
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
	[_tableView reloadData];
}

#pragma mark Table view delegate

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
