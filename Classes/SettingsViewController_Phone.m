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

#import "MoreInfoButton.h"

#import "Countdown.h"

#import "UIColor+addition.h"
#import "NSBundle+addition.h"
#import "UITableView+addition.h"

const NSInteger kMoreInfoSheetTag = 123;
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
	
	UIBarButtonItem * doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					 target:self
																					 action:@selector(done:)];
	if ([doneButtonItem respondsToSelector:@selector(setTintColor:)])
		doneButtonItem.tintColor = [UIColor doneButtonColor];
	
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	
	UIBarButtonItem * editButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Edit All", nil)
																		style:UIBarButtonItemStylePlain
																	   target:self
																	   action:@selector(editAllCountdowns:)];
	self.navigationItem.leftBarButtonItem = editButtonItem;
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView = backgroundView;
	
	[self reloadData];
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	[self reloadData];
	
	double delayInSeconds = 0.25;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:YES];
	});
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
}

- (void)setCountdown:(Countdown *)aCountdown
{
	showsDeleteButton = ([aCountdown.endDate timeIntervalSinceNow] <= 0. || aCountdown.type == CountdownTypeTimer);
	
	countdown = aCountdown;
}

- (void)reloadData
{
	if (countdown.type == CountdownTypeTimer) {
		cellTitles = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Name", nil),
					  NSLocalizedString(@"Durations", nil),
					  NSLocalizedString(@"Song", nil), nil];
	} else {
		cellTitles = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Name", nil),
					  NSLocalizedString(@"Date & Time", nil),
					  NSLocalizedString(@"Message", nil),
					  NSLocalizedString(@"Song", nil),
					  NSLocalizedString(@"Theme", nil), nil];
	}
	
	showsDeleteButton = ([countdown.endDate timeIntervalSinceNow] <= 0. || countdown.type == CountdownTypeTimer);
	
	[tableView reloadData];
}

- (IBAction)done:(id)sender
{
	if ([delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)])
		[delegate settingsViewControllerDidFinish:self];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
	
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
	
	[self presentModalViewController:navigationController animated:YES];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © 2013, Lis@cintosh\n", nil), [infoDictionary objectForKey:@"CFBundleShortVersionString"]]; // @TODO: generate the year
	
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:nil
													 otherButtonTitles:
								   NSLocalizedString(@"Show Countdowns Online", nil),
								   NSLocalizedString(@"Feedback & Support", nil),
								   NSLocalizedString(@"Go to my website", nil),
								   NSLocalizedString(@"See all my applications", nil), nil];
	
	actionSheet.tag = kMoreInfoSheetTag;
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[actionSheet showInView:self.view];
}

- (IBAction)deleteAction:(id)sender
{
	NSString * title = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Do you really want to delete this timer?", nil) : NSLocalizedString(@"Do you really want to delete this countdown?", nil);
	NSString * destructiveButtonTitle = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Delete Timer", nil) : NSLocalizedString(@"Delete Countdown", nil);
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:destructiveButtonTitle
													 otherButtonTitles:nil];
	
	actionSheet.tag = kDeleteSheetTag;
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[actionSheet showInView:self.view];
}

- (void)deleteCountdown
{
	/* Get the countdown next this one */
	NSInteger index = [Countdown indexOfCountdown:self.countdown];
	[Countdown removeCountdown:self.countdown];
	
	NSInteger count = [Countdown allCountdowns].count;
	if (count > 0) {
		
		if (index > (count - 1)) {// Clip to bounds
			index = (count - 1);// Selected the last one
		}
		
		Countdown * newCountdown = [Countdown countdownAtIndex:index];
		self.countdown = newCountdown;
		
		if ([delegate respondsToSelector:@selector(settingsViewControllerDidFinish:)]) // Returns to PageViewController
			[delegate settingsViewControllerDidFinish:self];
		
		/* Animate the status bar to opaque black */
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:YES];
		
	} else {// If we have deleted the last countdown, show editAllCountdowns: panel
		[self editAllCountdowns:nil];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (showsDeleteButton)
		return 4;
	
	return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return cellTitles.count;
	
	return 1;// Return one row for the type cell, the "delete" button and the "about" cell
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
		
		cell.textLabel.text = [cellTitles objectAtIndex:indexPath.row];
		
		if (countdown.type == CountdownTypeTimer) {
			
			switch (indexPath.row) {
				case 0: {// Name
					cell.detailTextLabel.text = countdown.name;
				}
					break;
				case 1: {// Durations
					if (countdown.durations.count == 0) {
						cell.detailTextLabel.text = NSLocalizedString(@"no timers", nil); // @TODO: replace "no timers" with "no durations"
						cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.];
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
				case 2: {// Song
					NSString * songID = countdown.songID;
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:songID];
				}
					break;
			}
		} else {
			
			switch (indexPath.row) {
				case 0: {// Name
					cell.detailTextLabel.text = countdown.name;
				}
					break;
				case 1: {// Date & Time
					NSDate * date = countdown.endDate;
					if (date && ([date timeIntervalSinceNow] > 0)) {
						cell.detailTextLabel.text = [date description];
						
						cell.detailTextLabel.font = [UIFont systemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor darkGrayColor];
					} else {
						cell.detailTextLabel.text = NSLocalizedString(@"No date", nil);
						
						cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.];
					}
				}
					break;
				case 2: {// Message
					cell.detailTextLabel.text = (countdown.message)? countdown.message: @"";
				}
					break;
				case 3: {// Song
					NSString * songID = countdown.songID;
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:songID];
				}
					break;
				case 4: {// Theme
					NSInteger style = countdown.style;
					cell.detailTextLabel.text = [[Countdown styles] objectAtIndex:style];
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
				cell.textLabel.textAlignment = UITextAlignmentCenter;
				
				cell.textLabel.textColor = [UIColor whiteColor];
			}
			
			cell.textLabel.text = (countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Delete Timer", nil) : NSLocalizedString(@"Delete Countdown", nil);
			cell.textLabel.font = [UIFont boldSystemFontOfSize:18.];
			
			cell.textLabel.shadowColor = [UIColor colorWithRed:0.3 green:0. blue:0. alpha:0.8];
			cell.textLabel.shadowOffset = CGSizeMake(0., -1.);
			
		} else {
			
			static NSString * aboutCellIdentifier = @"AboutCellID";
			
			cell = [tableView dequeueReusableCellWithIdentifier:aboutCellIdentifier];
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:aboutCellIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
				
				cell.detailTextLabel.textColor = [UIColor darkGrayColor];
				
				UIImageView * accessoryImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"info_button"]];
				cell.accessoryView = accessoryImageView;
			}
			
			cell.textLabel.text = @"Closer & Closer";
			cell.detailTextLabel.text = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
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
				case 0: {// Name
					NameViewController * nameViewController = [[NameViewController alloc] init];
					nameViewController.countdown = countdown;
					[self.navigationController pushViewController:nameViewController animated:YES];
				}
					break;
				case 1: {// Durations
					DurationsViewController * durationsViewController = [[DurationsViewController alloc] init];
					durationsViewController.countdown = countdown;
					[self.navigationController pushViewController:durationsViewController animated:YES];
				}
					break;
				case 2: {// Song
					SongPickerViewController * songPickerViewController = [[SongPickerViewController alloc] init];
					songPickerViewController.countdown = countdown;
					[self.navigationController pushViewController:songPickerViewController animated:YES];
				}
					break;
			}
			
		} else {
			switch (indexPath.row) {
				case 0: {// Name
					NameViewController * nameViewController = [[NameViewController alloc] init];
					nameViewController.countdown = countdown;
					[self.navigationController pushViewController:nameViewController animated:YES];
				}
					break;
				case 1: {// Date & Time
					DatePickerViewController * datePickerViewController = [[DatePickerViewController alloc] init];
					datePickerViewController.countdown = countdown;
					[self.navigationController pushViewController:datePickerViewController animated:YES];
				}
					break;
				case 2: {// Message
					MessageViewControler * messageViewControler = [[MessageViewControler alloc] init];
					messageViewControler.countdown = countdown;
					[self.navigationController pushViewController:messageViewControler animated:YES];
				}
					break;
				case 3: {// Song
					SongPickerViewController * songPickerViewController = [[SongPickerViewController alloc] init];
					songPickerViewController.countdown = countdown;
					[self.navigationController pushViewController:songPickerViewController animated:YES];
				}
					break;
				case 4: {// Theme
					PageThemeViewController * pageThemeViewController = [[PageThemeViewController alloc] init];
					pageThemeViewController.countdown = countdown;
					[self.navigationController pushViewController:pageThemeViewController animated:YES];
				}
					break;
			}
		}
		
	} else if (indexPath.section >= 2) {
		if (showsDeleteButton && indexPath.section == 2) {
			[self deleteAction:nil];
		} else {
			[self moreInfo:nil];
		}
	}
	
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.tag == kMoreInfoSheetTag) {
		switch (buttonIndex) {
			case 0:// Show Countdowns Online
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://closer.lisacintosh.com/index.php"]];
				break;
			case 1:// Feedback & Support
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/closer/"]];
				break;
				/*
				 case 2:// Send me an e-mail
				 [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"mailto://4automator@googlemail.com"]];
				 break;
				 */
			case 2:// Go to my website
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lisacintosh.com/"]];
				break;
			case 3: {// See all my applications
				/* Link via iTunes -> AppStore, I haven't found better! */
				NSString * iTunesLink = @"https://itunes.apple.com/us/artist/lisacintosh/id320891279?uo=4";// old link = http://search.itunes.apple.com/WebObjects/MZContentLink.woa/wa/link?path=apps%2flisacintosh
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
				
				/* Link via Safari -> iTunes -> AppStore */
				//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://itunes.com/apps/lisacintosh/"]];
			}
				break;
			default:// Cancel
				break;
		}
	} else if (actionSheet.tag == kDeleteSheetTag) {
		switch (buttonIndex)
		{
			case 0://Delete Countdown
				[self deleteCountdown];
				break;
			default://Cancel
				break;
		}
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload
{
	self.tableView = nil;
	self.footerLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}

- (void)dealloc
{
	self.countdown = nil;
}


@end
