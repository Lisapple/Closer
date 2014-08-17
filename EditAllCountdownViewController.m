//
//  EditAllCountdownViewController.m
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "EditAllCountdownViewController.h"
#import "SettingsViewController_Phone.h"
#import "ImportFromCalendarViewController.h"
#import "ImportFromWebsiteViewController_Phone.h"
#import "ExportViewController.h"

#import "NetworkStatus.h"

@interface EditAllCountdownViewController (PrivateMethods)

- (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index;
- (void)removeCountdown:(Countdown *)countdown index:(NSInteger)index;

@end

@implementation EditAllCountdownViewController

@synthesize settingsViewController;

const NSInteger kDoneButtonItemTag = 1;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"All Countdowns", nil);
	
	UIBarButtonItem * doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					 target:self
																					 action:@selector(done:)];
	doneButtonItem.tag = kDoneButtonItemTag;
	
	if (!TARGET_IS_IOS7_OR_LATER()) {
		self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
		doneButtonItem.tintColor = [UIColor doneButtonColor];
	}
	
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	
	UIBarButtonItem * addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																					target:self
																					action:@selector(add:)];
	UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoLight];
	button.frame = CGRectMake(0., 0., 23., 23.);
	[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
	if (TARGET_IS_IOS7_OR_LATER())
        button.tintColor = self.view.window.tintColor;
	
    UIBarButtonItem * infoButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
	
	self.navigationItem.leftBarButtonItems = @[addButtonItem, infoButtonItem];
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
    tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (!TARGET_IS_IOS7_OR_LATER()) {
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        
        UIView * backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        tableView.backgroundView = backgroundView;
    }
    
	tableView.allowsSelectionDuringEditing = YES;
	tableView.editing = YES;
	
	[self reloadData];
	
	[NetworkStatus startObserving];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(networkStatusDidChange:)
												 name:kNetworkStatusDidChangeNotification
											   object:nil];
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	/* Reload the second section (Import/Export) */
	[tableView reloadSections:[NSIndexSet indexSetWithIndex:1]
			 withRowAnimation:UITableViewRowAnimationFade];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadData)
												 name:CountdownDidSynchronizeNotification
											   object:nil]; // @TODO: don't reload on changes
	
	[self reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CountdownDidSynchronizeNotification
												  object:nil];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [[NSBundle mainBundle] infoDictionary];
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © 2014, Lis@cintosh\n", nil), infoDictionary[@"CFBundleShortVersionString"]]; // @TODO: generate the year
	
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:nil
													 otherButtonTitles:
								   NSLocalizedString(@"Show Countdowns Online", nil),
								   NSLocalizedString(@"Feedback & Support", nil),
								   NSLocalizedString(@"Go to my website", nil),
								   NSLocalizedString(@"See all my applications", nil), nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[actionSheet showInView:self.view];
}

- (void)reloadData
{
	NSArray * oldCountdowns = [countdowns copy];
	
	if (![oldCountdowns isEqualToArray:[Countdown allCountdowns]]) { // Change to "save" only if we have real change
		
		countdowns = [[Countdown allCountdowns] copy];
		[tableView reloadData];
		
		BOOL animated = (self.navigationItem.rightBarButtonItem.tag == kDoneButtonItemTag);
		UIBarButtonItem * saveButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
																						 target:self
																						 action:@selector(done:)];
		if (!TARGET_IS_IOS7_OR_LATER())
			saveButtonItem.tintColor = [UIColor doneButtonColor];
		
		[self.navigationItem setRightBarButtonItem:saveButtonItem animated:animated];
	}
	
	self.navigationItem.rightBarButtonItem.enabled = (countdowns.count > 0);
}

- (IBAction)done:(id)sender
{
	NSInteger index = [Countdown indexOfCountdown:settingsViewController.countdown];
	if (index == NSNotFound) {
		NSInteger countdownsCount = [Countdown allCountdowns].count;
		if (countdownsCount > 0)
			settingsViewController.countdown = [Countdown countdownAtIndex:(countdownsCount - 1)];
	}
	
	[Countdown synchronize];
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (NSString *)proposedNameForType:(CountdownType)type
{
	NSString * name = (type == CountdownTypeTimer) ? NSLocalizedString(@"New Timer", nil) : NSLocalizedString(@"New Countdown", nil);
	
	int index = 1;
	while (1) {
		
		BOOL nameIsFree = YES;
		for (int i = 0; i < countdowns.count; i++) {
			Countdown * countdown = (Countdown *)countdowns[i];
			if ([countdown.name isEqualToString:name]) {
				nameIsFree = NO;
				break;
			}
		}
		
		if (nameIsFree)
			return name;
		
		if (type == CountdownTypeTimer)
			name = [NSString stringWithFormat:NSLocalizedString(@"New Timer %i", nil), index++];
		else
			name = [NSString stringWithFormat:NSLocalizedString(@"New Countdown %i", nil), index++];
	}
}

- (IBAction)add:(id)sender
{
	if (countdowns.count > 18) {// The limit of countdown for the pageControl view is 18
		UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"You must delete at least one countdown to add a new countdown.", nil)
																  delegate:nil
														 cancelButtonTitle:NSLocalizedString(@"OK", nil)
													destructiveButtonTitle:nil
														 otherButtonTitles:nil];
		
		actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
		[actionSheet showInView:self.view];
		
	} else {
		
		Countdown * aCountDown = [[Countdown alloc] init];
		aCountDown.name = [self proposedNameForType:CountdownTypeCountdown];
		[Countdown addCountdown:aCountDown];
		/* Note: the tableView is automatically reloaded */
		// @TODO: animated the row insertion
		
		[tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(countdowns.count - 1) inSection:0]
						 atScrollPosition:UITableViewScrollPositionMiddle
								 animated:YES];
	}
}

- (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index
{
	[[self.undoManager prepareWithInvocationTarget:self] removeCountdown:countdown index:index];
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_DELETE_COUNTDOWN_ACTION", nil)];
	
	[Countdown insertCountdown:countdown atIndex:index];
	/* Note: the tableView is automatically reloaded */
	// @TODO: animated the row insertion
}

- (void)removeCountdown:(Countdown *)countdown index:(NSInteger)index
{
	[[self.undoManager prepareWithInvocationTarget:self] insertCountdown:countdown atIndex:index];
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_DELETE_COUNTDOWN_ACTION", nil)];
	
	[Countdown removeCountdown:countdown];
	/* Note: the tableView is automatically reloaded */
	// @TODO: animated the row insertion
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;// One section for countdowns and one for Import/Export
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0)
		return countdowns.count;
	else if (section == 1)
		return ([NetworkStatus isConnected] == YES)? 3: 2; // Remove the "Import with Passwords" if no internet connection
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	if (indexPath.section == 0) {
		static NSString * countdownCellIdentifier = @"countdownCellIdentifier";
		cell = [tableView dequeueReusableCellWithIdentifier:countdownCellIdentifier];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:countdownCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		
		Countdown * countdown = countdowns[indexPath.row];
		cell.textLabel.text = countdown.name;
		
		if (countdown.type == CountdownTypeTimer) {
			if (countdown.durations.count >= 2) {
				cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld timers", nil), (long)countdown.durations.count]; // @TODO: replace "%ld timers" with "%ld durations"
			} else if (countdown.durations.count == 1) {
				cell.detailTextLabel.text = [countdown descriptionOfDurationAtIndex:0];
			} else {
				cell.detailTextLabel.text = NSLocalizedString(@"No timers", nil); // @TODO: replace "No timers" with "No durations"
			}
		} else {
			cell.detailTextLabel.text = [countdown.endDate description];
		}
		
	} else {
		static NSString * shareCellIdentifier = @"shareCellIdentifier";
		cell = [tableView dequeueReusableCellWithIdentifier:shareCellIdentifier];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:shareCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
		}
		
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = NSLocalizedString(@"Import from Calendar", nil);
				break;
			case 1: {
				BOOL isConnected = [NetworkStatus isConnected];
				if (isConnected) {
					cell.textLabel.text = NSLocalizedString(@"Import with Passwords", nil);
					break;
				}
			}
			default:
				cell.textLabel.text = NSLocalizedString(@"Export Countdowns...", nil);
				break;
		}
	}
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section == 0);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0)
		return UITableViewCellEditingStyleDelete;
	
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		NSInteger index = indexPath.row;
		[self removeCountdown:[Countdown countdownAtIndex:index]
						index:index];
		// @TODO: animated the row deletion
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section == 0);
}

- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	[Countdown moveCountdownAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
	//[self reloadData];
	// @TODO: animated the row movement
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		settingsViewController.countdown = countdowns[indexPath.row];
		
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
		
		[Countdown synchronize];
		
		[self dismissViewControllerAnimated:YES completion:NULL];
	} else {
		switch (indexPath.row) {// Import From Calendar
			case 0: {
				
				BOOL granted = YES;
				if ([EKEventStore instancesRespondToSelector:@selector(requestAccessToEntityType:completion:)]) {
					EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
					granted = (status == EKAuthorizationStatusAuthorized || status == EKAuthorizationStatusNotDetermined);
				}
				
				if (granted) {
					ImportFromCalendarViewController * importFromCalendarViewController = [[ImportFromCalendarViewController alloc] init];
					[self.navigationController pushViewController:importFromCalendarViewController animated:YES];
				} else {
					NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer have not access to events from calendar. Check privacy settings for calendar from your %@ settings.", nil), [UIDevice currentDevice].localizedModel];
					UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied!", nil)
																		 message:message
																		delegate:nil
															   cancelButtonTitle:NSLocalizedString(@"OK", nil)
															   otherButtonTitles:nil];
					[alertView show];
				}
			}
				break;
			case 1: {
				NSInteger numberOfRows = [tableView numberOfRowsInSection:1];
				/* 3 rows means that the "Import with Passwords" is active, else this cell is "Export..." */
				if (numberOfRows == 3) {// Import with Passwords
					
					/* Show an alertView to introduce the import from passwords (if not already done) */
					NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
					BOOL showsIntroductionMessage = !([userDefaults boolForKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"]);
					if (showsIntroductionMessage) {
						
						NSString * message = NSLocalizedString(@"IMPORT_WITH_PASSWORDS_INTRODUCTION_MESSAGE", nil);
						UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Import with Passwords", nil)
																			 message:message
																			delegate:self
																   cancelButtonTitle:NSLocalizedString(@"OK", nil)
																   otherButtonTitles:nil];
						[alertView show];
						
						[userDefaults setBool:YES forKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"];
					} else {
						ImportFromWebsiteViewController_Phone * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Phone alloc] init];
						UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
						[self presentViewController:navigationController animated:YES completion:NULL];
					}
					
					break;
				}// else, for "Export...", don't break for executing the default case
			}
			default: {
				ExportViewController * exportViewController = [[ExportViewController alloc] init];
				[self.navigationController pushViewController:exportViewController animated:YES];
			}
				break;
		}
		
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

#pragma mark - UIActionSheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
		switch (buttonIndex) {
			case 0:// Show Countdowns Online
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://closer.lisacintosh.com/index.php"]];
				break;
			case 1:// Feedback & Support
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/closer/"]];
				break;
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
}

#pragma mark - UIAlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	ImportFromWebsiteViewController_Phone * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Phone alloc] init];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
	[self presentViewController:navigationController animated:YES completion:NULL];
}

- (BOOL)canBecomeFirstResponder
{
	return YES;// Return YES to receive undo from shake gesture
}

@end
