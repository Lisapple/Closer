//
//  SettingsViewController.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SettingsViewController.h"
#import "TypeViewController.h"
#import "DatePickerViewController.h"
#import "DurationsViewController.h"
#import "MessageViewControler.h"
#import "SongPickerViewController.h"
#import "EditAllCountdownViewController.h"
#import "NameViewController.h"
#import "PageThemeViewController.h"

#import "NSBundle+addition.h"
#import "UIBarButtonItem+addition.h"
#import "NSDate+addition.h"

@interface SettingsViewController ()

@property (nonatomic, strong) NSArray <NSString *> * cellTitles;

- (IBAction)done:(id)sender;
- (IBAction)editAllCountdowns:(id)sender;
- (IBAction)deleteAction:(id)sender;

- (void)deleteCountdown;

@end

@implementation SettingsViewController

- (instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) { }
	return self;
}

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Settings", nil);
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(done:)];
	
	if (!TARGET_IS_IPAD()) {
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", nil)
																				 style:UIBarButtonItemStylePlain
																				target:self action:@selector(editAllCountdowns:)];
	}
	
	[self reloadData];
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self reloadData];
	
	self.navigationController.view.clipsToBounds = YES;
	
	NSString * title = (_countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Delete Timer", nil) : NSLocalizedString(@"Delete Countdown", nil);
	UIBarButtonItem * deleteItem = [[UIBarButtonItem alloc] initWithTitle:title style:UIBarButtonItemStylePlain
																   target:self action:@selector(deleteAction:)];
	deleteItem.tintColor = [UIColor redColor];
	self.toolbarItems = @[ [UIBarButtonItem flexibleSpace], deleteItem, [UIBarButtonItem flexibleSpace] ];
	self.navigationController.toolbarHidden = NO;
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)reloadData
{
	if (_countdown.type == CountdownTypeTimer) {
		_cellTitles = @[ NSLocalizedString(@"Name", nil),
						 NSLocalizedString(@"Durations", nil),
						 NSLocalizedString(@"Sound", nil),
						 NSLocalizedString(@"Theme", nil) ];
	} else {
		_cellTitles = @[ NSLocalizedString(@"Name", nil),
						 NSLocalizedString(@"Date & Time", nil),
						 NSLocalizedString(@"Message", nil),
						 NSLocalizedString(@"Sound", nil),
						 NSLocalizedString(@"Theme", nil) ];
	}
	
	[self.tableView reloadData];
}

- (IBAction)done:(id)sender
{
#if TARGET_IPHONE_SIMULATOR
	[Countdown synchronize];
#endif
	
	if (TARGET_IS_IPAD()) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsViewControllerDidCloseNotification"
															object:nil];
	} else {
		if ([_delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)])
			[_delegate settingsViewControllerDidFinish:self];
	}
}

- (IBAction)editCountdowns:(id)sender
{
	[self editAllCountdowns:nil];
}

- (IBAction)editAllCountdowns:(id)sender
{
	EditAllCountdownViewController * editAllCountdownViewController = [[EditAllCountdownViewController alloc] init];
	editAllCountdownViewController.settingsViewController = self;
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:editAllCountdownViewController];
	[self presentViewController:navigationController animated:YES completion:NULL];
}

- (IBAction)deleteAction:(id)sender
{
	NSString * title = (_countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Do you really want to delete this timer?", nil) : NSLocalizedString(@"Do you really want to delete this countdown?", nil);
	NSString * destructiveButtonTitle = (_countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Delete Timer", nil) : NSLocalizedString(@"Delete Countdown", nil);
	
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * __nonnull action) {
		[self deleteCountdown]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
	[self presentViewController:alert animated:YES completion:NULL];
}

- (void)deleteCountdown
{
	/* Get the countdown next this one */
	NSInteger index = [Countdown indexOfCountdown:self.countdown];
	[Countdown removeCountdown:self.countdown];
	
	NSInteger count = [Countdown allCountdowns].count;
	if (count > 0) {
		index = MIN(index, count-1);
		Countdown * newCountdown = [Countdown countdownAtIndex:index];
		self.countdown = newCountdown;
		
		if ([_delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)]) // Returns to PageViewController
			[_delegate settingsViewControllerDidFinish:self];
		
	} else { // If we have deleted the last countdown, show editAllCountdowns: panel
		[self editAllCountdowns:nil];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return _cellTitles.count;
	
	return 1; // Return one row for the type cell
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.detailTextLabel.textColor = [UIColor darkGrayColor];
	}
	
	if (indexPath.section == 0) {
		cell.textLabel.text = NSLocalizedString(@"Type", nil);
		cell.detailTextLabel.text = NSLocalizedString((_countdown.type == CountdownTypeTimer) ? @"Timer" : @"Countdown", nil);
	} else {
		cell.textLabel.text = _cellTitles[indexPath.row];
		
		if (_countdown.type == CountdownTypeTimer) {
			switch (indexPath.row) {
				case 0: // Name
					cell.detailTextLabel.text = _countdown.name;
					break;
				case 1: { // Durations
					if (_countdown.durations.count == 0) {
						cell.detailTextLabel.text = NSLocalizedString(@"no durations", nil);
						cell.detailTextLabel.textColor = [UIColor redColor];
					} else {
						if (_countdown.durations.count == 1)
							cell.detailTextLabel.text = [_countdown shortDescriptionOfDurationAtIndex:0];
						else
							cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld durations", nil), (long)_countdown.durations.count];
						
						cell.detailTextLabel.textColor = [UIColor darkGrayColor];
					}
				}
					break;
				case 2: // Song
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:_countdown.songID];
					break;
				case 3: // Theme
					cell.detailTextLabel.text = CountdownStyleDescription(_countdown.style);
				default: break;
			}
		} else {
			switch (indexPath.row) {
				case 0: // Name
					cell.detailTextLabel.text = _countdown.name;
					break;
				case 1: { // Date & Time
					NSDate * date = _countdown.endDate;
					if (date.timeIntervalSinceNow > 0.) {
						cell.detailTextLabel.text = date.localizedDescription;
						cell.detailTextLabel.textColor = [UIColor darkGrayColor];
					} else {
						cell.detailTextLabel.text = @"!";
						cell.detailTextLabel.textColor = [UIColor redColor];
					}
				}
					break;
				case 2: // Message
					cell.detailTextLabel.text = (_countdown.message)? _countdown.message: @"";
					break;
				case 3: // Song
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:_countdown.songID];
					break;
				case 4: // Theme
					cell.detailTextLabel.text = CountdownStyleDescription(_countdown.style);
				default: break;
			}
		}
	}
	return cell;
}

#pragma mark - Table view delegate

- (UIViewController *)showSettingsType:(SettingsType)setting animated:(BOOL)animated
{
	Class controllerClass = nil;
	switch (setting) {
		case SettingsTypeName:		controllerClass = NameViewController.class; break;
		case SettingsTypeDateAndTime: controllerClass = DatePickerViewController.class; break;
		case SettingsTypeMessage:	controllerClass = MessageViewControler.class; break;
		case SettingsTypeDurations:	controllerClass = DurationsViewController.class; break;
		case SettingsTypeSong:		controllerClass = SongPickerViewController.class; break;
		case SettingsTypeTheme:		controllerClass = PageThemeViewController.class; break;
		default: break;
	}
	
	UIViewController * viewController = (UIViewController *)[[controllerClass alloc] init];
	NSAssert([viewController isKindOfClass:UIViewController.class], @"%@ must be a view controller", viewController);
	if ([viewController respondsToSelector:@selector(countdown)])
		[viewController performSelector:@selector(setCountdown:) withObject:_countdown];
	
	[self.navigationController pushViewController:viewController animated:animated];
	return viewController;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		TypeViewController * typeViewController = [[TypeViewController alloc] init];
		typeViewController.countdown = _countdown;
		[self.navigationController pushViewController:typeViewController animated:YES];
		
	} else {
		SettingsType settings = -1;
		if (_countdown.type == CountdownTypeTimer) {
			switch (indexPath.row) {
				case 0: settings = SettingsTypeName; break;
				case 1: settings = SettingsTypeDurations; break;
				case 2: settings = SettingsTypeSong; break;
				case 3: settings = SettingsTypeTheme;
				default: break;
			}
		} else {
			switch (indexPath.row) {
				case 0: settings = SettingsTypeName; break;
				case 1: settings = SettingsTypeDateAndTime; break;
				case 2: settings = SettingsTypeMessage; break;
				case 3: settings = SettingsTypeSong; break;
				case 4: settings = SettingsTypeTheme;
				default: break;
			}
		}
		[self showSettingsType:settings animated:YES];
	}
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
