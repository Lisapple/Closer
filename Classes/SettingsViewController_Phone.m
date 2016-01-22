//
//  FlipsideViewController.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SettingsViewController_Phone.h"
#import "TypeViewController.h"
#import "DatePickerViewController.h"
#import "DurationsViewController.h"
#import "MessageViewControler.h"
#import "SongPickerViewController.h"
#import "EditAllCountdownViewController.h"
#import "NameViewController.h"
#import "PageThemeViewController.h"

#import "DeleteTableViewCell.h"

#import "Countdown.h"

#import "NSBundle+addition.h"

const NSInteger kDeleteSheetTag = 234;
const NSInteger kDeleteButtonTag = 345;

@interface SettingsViewController_Phone ()

@property (nonatomic, strong) NSArray <NSString *> * cellTitles;
@property (nonatomic, assign) BOOL showsDeleteButton;

- (IBAction)done:(id)sender;
- (IBAction)editAllCountdowns:(id)sender;
- (IBAction)deleteAction:(id)sender;

- (void)deleteCountdown;

@end

@implementation SettingsViewController_Phone

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Settings", nil);
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(done:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", nil)
																			 style:UIBarButtonItemStylePlain
																			target:self action:@selector(editAllCountdowns:)];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	[self reloadData];
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self reloadData];
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)setCountdown:(Countdown *)aCountdown
{
	_showsDeleteButton = (aCountdown.endDate.timeIntervalSinceNow <= 0. || aCountdown.type == CountdownTypeTimer);
	
	_countdown = aCountdown;
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
	
	_showsDeleteButton = (_countdown.type == CountdownTypeCountdown && _countdown.endDate.timeIntervalSinceNow <= 0.);
	
	[_tableView reloadData];
}

- (IBAction)done:(id)sender
{
	if ([_delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)])
		[_delegate settingsViewControllerDidFinish:self];
	
#if TARGET_IPHONE_SIMULATOR
	[Countdown synchronize];
#endif
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
		
		if (index > (count - 1)) { // Clip to bounds
			index = (count - 1);// Selected the last one
		}
		
		Countdown * newCountdown = [Countdown countdownAtIndex:index];
		self.countdown = newCountdown;
		
		if ([_delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)]) // Returns to PageViewController
			[_delegate settingsViewControllerDidFinish:self];
		
	} else { // If we have deleted the last countdown, show editAllCountdowns: panel
		[self editAllCountdowns:nil];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (_showsDeleteButton)
		return 3;
	
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return _cellTitles.count;
	
	return 1;// Return one row for the type cell and the "delete" button
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	static NSString * cellIdentifier = @"CellID";
	
	if (indexPath.section == 0) {
		
		cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		
		cell.textLabel.text = NSLocalizedString(@"Type", nil);
		
		cell.detailTextLabel.text = (_countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Timer", nil) : NSLocalizedString(@"Countdown", nil);
		
	} else if (indexPath.section == 1) {
		
		cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		
		cell.textLabel.text = _cellTitles[indexPath.row];
		
		if (_countdown.type == CountdownTypeTimer) {
			
			switch (indexPath.row) {
				case 0: { // Name
					cell.detailTextLabel.text = _countdown.name;
				}
					break;
				case 1: { // Durations
					if (_countdown.durations.count == 0) {
						cell.detailTextLabel.text = @"!";
						cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor redColor];
					} else {
						if (_countdown.durations.count == 1) {
							cell.detailTextLabel.text = [_countdown shortDescriptionOfDurationAtIndex:0];
						} else {
							cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld durations", nil), (long)_countdown.durations.count];
						}
						cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor darkGrayColor];
					}
				}
					break;
				case 2: { // Song
					NSString * songID = _countdown.songID;
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:songID];
				}
					break;
				case 3: { // Theme
					NSInteger style = _countdown.style;
					cell.detailTextLabel.text = [Countdown styles][style];
				}
					break;
			}
		} else {
			
			switch (indexPath.row) {
				case 0: { // Name
					cell.detailTextLabel.text = _countdown.name;
				}
					break;
				case 1: { // Date & Time
					NSDate * date = _countdown.endDate;
					if (date && (date.timeIntervalSinceNow > 0.)) {
						cell.detailTextLabel.text = date.description;
						cell.detailTextLabel.textColor = [UIColor darkGrayColor];
					} else {
						cell.detailTextLabel.text = @"!";
						cell.detailTextLabel.textColor = [UIColor redColor];
					}
                    
                    cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
				}
					break;
				case 2: { // Message
					cell.detailTextLabel.text = (_countdown.message)? _countdown.message: @"";
				}
					break;
				case 3: { // Song
					NSString * songID = _countdown.songID;
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:songID];
				}
					break;
				case 4: { // Theme
					NSInteger style = _countdown.style;
					cell.detailTextLabel.text = [Countdown styles][style];
				}
					break;
			}
		}
	} else if (indexPath.section >= 2) {
		if (_showsDeleteButton && indexPath.section == 2) {
			
			static NSString * deleteCellIdentifier = @"DeleteCellID";
			
			cell = [_tableView dequeueReusableCellWithIdentifier:deleteCellIdentifier];
			if (cell == nil) {
				cell = [[DeleteTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:deleteCellIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.textAlignment = NSTextAlignmentCenter;
				
				cell.textLabel.textColor = [UIColor whiteColor];
			}
			
			cell.textLabel.text = NSLocalizedString(@"Delete", nil);
			cell.textLabel.font = [UIFont systemFontOfSize:20.];
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
	
	if (controllerClass) {
		UIViewController * viewController = (UIViewController *)[[controllerClass alloc] init];
		NSAssert([viewController isKindOfClass:UIViewController.class], @"%@ must be a view controller", viewController);
		if ([viewController respondsToSelector:@selector(countdown)]) {
			[viewController performSelector:@selector(setCountdown:) withObject:_countdown];
		}
		[self.navigationController pushViewController:viewController animated:animated];
		return viewController;
	}
	return nil;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		TypeViewController * typeViewController = [[TypeViewController alloc] init];
		typeViewController.countdown = _countdown;
		[self.navigationController pushViewController:typeViewController animated:YES];
		
	} else if (indexPath.section == 1) {
		
		SettingsType settings = SettingsTypeNone;
		if (_countdown.type == CountdownTypeTimer) {
			switch (indexPath.row) {
				case 0: settings = SettingsTypeName; break;
				case 1: settings = SettingsTypeDurations; break;
				case 2: settings = SettingsTypeSong; break;
				case 3: settings = SettingsTypeTheme; break;
			}
		} else {
			switch (indexPath.row) {
				case 0: settings = SettingsTypeName; break;
				case 1: settings = SettingsTypeDateAndTime; break;
				case 2: settings = SettingsTypeMessage; break;
				case 3: settings = SettingsTypeSong; break;
				case 4: settings = SettingsTypeTheme; break;
			}
		}
		[self showSettingsType:settings animated:YES];
		
	} else if (indexPath.section == 2) { // Delete button
		[self deleteAction:nil];
	}
	
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
