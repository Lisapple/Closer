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

- (BOOL)canBecomeFirstResponder
{
	return YES; // For duration pop-up menu
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Durations", nil);
	
	self.tableView.alwaysBounceVertical = YES;
	self.tableView.allowsSelectionDuringEditing = YES;
	self.tableView.editing = YES;
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						   target:self action:@selector(addAction:)];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reloadData];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIMenuControllerWillHideMenuNotification
													  object:nil queue:nil
												  usingBlock:^(NSNotification * note) {
													  [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:NO];
												  }];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillHideMenuNotification object:nil];
}

- (void)updateUI
{
	/* Show a placeholder "No Durations" if the timer has no durations */
	if (_countdown.durations.count == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, 40.);
		UIButton * button = [[UIButton alloc] initWithFrame:frame];
		button.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		[button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
		button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
		[button setTitle:NSLocalizedString(@"Add Duration", nil) forState:UIControlStateNormal];
		[button addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
		self.tableView.tableFooterView = button;
	} else
		self.tableView.tableFooterView = nil;
}

- (void)reloadData
{
	[self updateUI];
	[self.tableView reloadData];
}

- (IBAction)addAction:(id)sender
{
	[self showAddDurationWithAnimation:YES];
}

- (void)showAddDurationWithAnimation:(BOOL)animated
{
	[_countdown addDuration:@0 withName:nil];
	
	NSInteger index = _countdown.durations.count - 1;
	DurationPickerViewController * controller = [[DurationPickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
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
		UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:promptCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:promptCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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
		UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
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
		[self.tableView beginUpdates];
		{
			[_countdown removeDurationAtIndex:indexPath.row];
			
			[self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
							  withRowAnimation:UITableViewRowAnimationFade];
		}
		[self.tableView endUpdates];
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

- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
	dispatch_async(dispatch_get_main_queue(), ^{
		UIMenuController * menu = [UIMenuController sharedMenuController];
		menu.menuItems = @[ [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Duplicate", nil)
													   action:@selector(duplicateDurationAction:)] ];
		UITableViewCell * cell = [tableView cellForRowAtIndexPath:indexPath];
		[menu setTargetRect:CGRectMake(CGRectGetMidX(cell.bounds), 0, 1, 1) inView:cell];
		[menu setMenuVisible:YES animated:YES];
	});
	return NO;
}

- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { return NO; }
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender { }

- (void)duplicateDurationAction:(id)sender
{
	[self.tableView beginUpdates];
	{
		NSIndexPath * indexPath = self.tableView.indexPathForSelectedRow;
		NSNumber * duration = _countdown.durations[indexPath.row];
		NSString * name = _countdown.names[indexPath.row];
		[_countdown addDuration:duration withName:name];
		[self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:_countdown.durations.count-1 inSection:indexPath.section] ]
						  withRowAnimation:UITableViewRowAnimationTop];
	}
	[self.tableView endUpdates];
	[self updateUI];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([UIMenuController sharedMenuController].isMenuVisible)
		return ;
	
	if (indexPath.section == 0) {
		PromptViewController * promptViewController = [[PromptViewController alloc] initWithStyle:UITableViewStyleGrouped];
		promptViewController.countdown = self.countdown;
		[self.navigationController pushViewController:promptViewController animated:YES];
		
	} else {
		DurationPickerViewController * durationPickerViewController = [[DurationPickerViewController alloc] initWithStyle:UITableViewStyleGrouped];
		durationPickerViewController.countdown = self.countdown;
		durationPickerViewController.durationIndex = indexPath.row;
		[self.navigationController pushViewController:durationPickerViewController animated:YES];
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
