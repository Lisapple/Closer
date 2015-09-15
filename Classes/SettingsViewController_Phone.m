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

@implementation SettingsViewController_Phone

@synthesize delegate;
@synthesize tableView;
@synthesize footerLabel;

@synthesize countdown;

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Settings", nil);
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(done:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"More", nil)
																			 style:UIBarButtonItemStylePlain
																			target:self action:@selector(editAllCountdowns:)];
	tableView.delegate = self;
	tableView.dataSource = self;
	
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
	showsDeleteButton = (aCountdown.endDate.timeIntervalSinceNow <= 0. || aCountdown.type == CountdownTypeTimer);
	
	countdown = aCountdown;
}

- (void)reloadData
{
	if (countdown.type == CountdownTypeTimer) {
		cellTitles = @[NSLocalizedString(@"Name", nil),
					  NSLocalizedString(@"Durations", nil),
					  NSLocalizedString(@"Sound", nil),
					   NSLocalizedString(@"Theme", nil)];
	} else {
		cellTitles = @[NSLocalizedString(@"Name", nil),
					  NSLocalizedString(@"Date & Time", nil),
					  NSLocalizedString(@"Message", nil),
					  NSLocalizedString(@"Sound", nil),
					  NSLocalizedString(@"Theme", nil)];
	}
	
	showsDeleteButton = (countdown.type == CountdownTypeCountdown && countdown.endDate.timeIntervalSinceNow <= 0.);
	
	[tableView reloadData];
}

- (IBAction)done:(id)sender
{
	if ([delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)])
		[delegate settingsViewControllerDidFinish:self];
	
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
	NSString * title = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Do you really want to delete this timer?", nil) : NSLocalizedString(@"Do you really want to delete this countdown?", nil);
	NSString * destructiveButtonTitle = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Delete Timer", nil) : NSLocalizedString(@"Delete Countdown", nil);
	
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
		
		if ([delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)]) // Returns to PageViewController
			[delegate settingsViewControllerDidFinish:self];
		
	} else { // If we have deleted the last countdown, show editAllCountdowns: panel
		[self editAllCountdowns:nil];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (showsDeleteButton)
		return 3;
	
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return cellTitles.count;
	
	return 1;// Return one row for the type cell and the "delete" button
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	static NSString * cellIdentifier = @"CellID";
	
	if (indexPath.section == 0) {
		
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		
		cell.textLabel.text = NSLocalizedString(@"Type", nil);
		
		cell.detailTextLabel.text = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Timer", nil) : NSLocalizedString(@"Countdown", nil);
		
	} else if (indexPath.section == 1) {
		
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		
		cell.textLabel.text = cellTitles[indexPath.row];
		
		if (countdown.type == CountdownTypeTimer) {
			
			switch (indexPath.row) {
				case 0: { // Name
					cell.detailTextLabel.text = countdown.name;
				}
					break;
				case 1: { // Durations
					if (countdown.durations.count == 0) {
						cell.detailTextLabel.text = @"!";
						cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor redColor];
					} else {
						if (countdown.durations.count == 1) {
							cell.detailTextLabel.text = [countdown shortDescriptionOfDurationAtIndex:0];
						} else {
							cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld timers", nil), (long)countdown.durations.count]; // @TODO: replace "%ld timers" with "%ld durations"
						}
						cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor darkGrayColor];
					}
				}
					break;
				case 2: { // Song
					NSString * songID = countdown.songID;
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:songID];
				}
					break;
				case 3: { // Theme
					NSInteger style = countdown.style;
					cell.detailTextLabel.text = [Countdown styles][style];
				}
					break;
			}
		} else {
			
			switch (indexPath.row) {
				case 0: { // Name
					cell.detailTextLabel.text = countdown.name;
				}
					break;
				case 1: { // Date & Time
					NSDate * date = countdown.endDate;
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
					cell.detailTextLabel.text = (countdown.message)? countdown.message: @"";
				}
					break;
				case 3: { // Song
					NSString * songID = countdown.songID;
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:songID];
				}
					break;
				case 4: { // Theme
					NSInteger style = countdown.style;
					cell.detailTextLabel.text = [Countdown styles][style];
				}
					break;
			}
		}
	} else if (indexPath.section >= 2) {
		if (showsDeleteButton && indexPath.section == 2) {
			
			static NSString * deleteCellIdentifier = @"DeleteCellID";
			
			cell = [tableView dequeueReusableCellWithIdentifier:deleteCellIdentifier];
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

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		TypeViewController * typeViewController = [[TypeViewController alloc] init];
		typeViewController.countdown = countdown;
		[self.navigationController pushViewController:typeViewController animated:YES];
		
	} else if (indexPath.section == 1) {
		
		if (countdown.type == CountdownTypeTimer) {
			
			switch (indexPath.row) {
				case 0: { // Name
					NameViewController * nameViewController = [[NameViewController alloc] init];
					nameViewController.countdown = countdown;
					[self.navigationController pushViewController:nameViewController animated:YES];
				}
					break;
				case 1: { // Durations
					DurationsViewController * durationsViewController = [[DurationsViewController alloc] init];
					durationsViewController.countdown = countdown;
					[self.navigationController pushViewController:durationsViewController animated:YES];
				}
					break;
				case 2: { // Song
					SongPickerViewController * songPickerViewController = [[SongPickerViewController alloc] init];
					songPickerViewController.countdown = countdown;
					[self.navigationController pushViewController:songPickerViewController animated:YES];
				}
					break;
				case 3: { // Theme
					PageThemeViewController * pageThemeViewController = [[PageThemeViewController alloc] init];
					pageThemeViewController.countdown = countdown;
					[self.navigationController pushViewController:pageThemeViewController animated:YES];
				}
					break;
			}
			
		} else {
			switch (indexPath.row) {
				case 0: { // Name
					NameViewController * nameViewController = [[NameViewController alloc] init];
					nameViewController.countdown = countdown;
					[self.navigationController pushViewController:nameViewController animated:YES];
				}
					break;
				case 1: { // Date & Time
					DatePickerViewController * datePickerViewController = [[DatePickerViewController alloc] init];
					datePickerViewController.countdown = countdown;
					[self.navigationController pushViewController:datePickerViewController animated:YES];
				}
					break;
				case 2: { // Message
					MessageViewControler * messageViewControler = [[MessageViewControler alloc] init];
					messageViewControler.countdown = countdown;
					[self.navigationController pushViewController:messageViewControler animated:YES];
				}
					break;
				case 3: { // Song
					SongPickerViewController * songPickerViewController = [[SongPickerViewController alloc] init];
					songPickerViewController.countdown = countdown;
					[self.navigationController pushViewController:songPickerViewController animated:YES];
				}
					break;
				case 4: { // Theme
					PageThemeViewController * pageThemeViewController = [[PageThemeViewController alloc] init];
					pageThemeViewController.countdown = countdown;
					[self.navigationController pushViewController:pageThemeViewController animated:YES];
				}
					break;
			}
		}
		
	} else if (indexPath.section == 2) { // Delete button
		[self deleteAction:nil];
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
