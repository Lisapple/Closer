//
//  SettingsViewController.m
//  test_iPad
//
//  Created by Max on 20/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "SettingsViewController_Pad.h"
#import "TypeViewController.h"
#import "DatePickerViewController.h"
#import "MessageViewControler.h"
#import "SongPickerViewController.h"
#import "NameViewController.h"
#import "DurationsViewController.h"
#import "PageThemeViewController.h"

#import "Countdown.h"

#import "NSBundle+addition.h"

@implementation SettingsViewController_Pad

@synthesize countdown;

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2; // For the type and settings
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return cellTitles.count;
	
	return 1;// Return one row for the type cell
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	static NSString * cellIdentifier = @"CellID";
	
	if (indexPath.section == 0) {
		
		cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		
		cell.textLabel.text = NSLocalizedString(@"Type", nil);
		
		cell.detailTextLabel.text = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Timer", nil) : NSLocalizedString(@"Countdown", nil);
		
	} else if (indexPath.section == 1) {
		
		cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
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
						cell.detailTextLabel.text = NSLocalizedString(@"no durations", nil);
						cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.];
					} else {
						if (countdown.durations.count == 1) {
							cell.detailTextLabel.text = [countdown shortDescriptionOfDurationAtIndex:0];
						} else {
							cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld durations", nil), (long)countdown.durations.count];
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
					if (date && ([date timeIntervalSinceNow] > 0.)) {
						cell.detailTextLabel.text = [date description];
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
	}
	
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Settings", nil);
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	self.navigationController.delegate = self;
	
	UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				 target:self
																				 action:@selector(close:)];
	if (!TARGET_IS_IOS7_OR_LATER())
		doneButton.tintColor = [UIColor doneButtonColor];
	self.navigationItem.rightBarButtonItem = doneButton;
	
	_viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
	[_viewControllers addObject:self];
	
    if (!TARGET_IS_IOS7_OR_LATER()) {
		UIView * backgroundView = [[UIView alloc] init];
		backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		self.tableView.backgroundView = backgroundView;
	}
    
	[self reloadData];
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
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self reloadData];
	
	[super viewWillAppear:animated];
}

- (IBAction)close:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsViewControllerDidCloseNotification"
														object:nil];
}

@end
