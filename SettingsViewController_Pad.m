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

@interface SettingsViewController_Pad ()

@property (nonatomic, strong) NSArray <NSString *> * cellTitles;
@property (nonatomic, strong) NSMutableArray <UIViewController *> * viewControllers;

@end

@implementation SettingsViewController_Pad

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2; // For the type and settings
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return _cellTitles.count;
	
	return 1;// Return one row for the type cell
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	static NSString * cellIdentifier = @"CellID";
	
	if (indexPath.section == 0) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		cell.textLabel.text = NSLocalizedString(@"Type", nil);
		cell.detailTextLabel.text = (_countdown.type == CountdownTypeTimer) ? NSLocalizedString(@"Timer", nil) : NSLocalizedString(@"Countdown", nil);
		
	} else if (indexPath.section == 1) {
		cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.detailTextLabel.textColor = [UIColor darkGrayColor];
		}
		cell.textLabel.text = _cellTitles[indexPath.row];
		
		if (_countdown.type == CountdownTypeTimer) {
			
			switch (indexPath.row) {
				case 0: // Name
					cell.detailTextLabel.text = _countdown.name;
					break;
				case 1: { // Durations
					if (_countdown.durations.count == 0) {
						cell.detailTextLabel.text = NSLocalizedString(@"no durations", nil);
						cell.detailTextLabel.font = [UIFont italicSystemFontOfSize:17.];
						cell.detailTextLabel.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.];
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
				case 2: // Song
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:_countdown.songID];
					break;
				case 3: // Theme
					cell.detailTextLabel.text = [Countdown styles][_countdown.style];
				default: break;
			}
		} else {
			
			switch (indexPath.row) {
				case 0: // Name
					cell.detailTextLabel.text = _countdown.name;
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
				case 2: // Message
					cell.detailTextLabel.text = (_countdown.message)? _countdown.message: @"";
					break;
				case 3: // Song
					cell.detailTextLabel.text = [[NSBundle mainBundle] nameForSongWithID:_countdown.songID];
					break;
				case 4: // Theme
					cell.detailTextLabel.text = [Countdown styles][_countdown.style];
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
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				 target:self action:@selector(close:)];
	_viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
	[_viewControllers addObject:self];
    
	[self reloadData];
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

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reloadData];
}

- (IBAction)close:(id)sender
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsViewControllerDidCloseNotification"
														object:nil];
}

@end
