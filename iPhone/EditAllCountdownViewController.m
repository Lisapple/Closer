//
//  EditAllCountdownViewController.m
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "EditAllCountdownViewController.h"
#import "SettingsViewController.h"
#import "ImportFromCalendarViewController.h"
#import "ImportFromWebsiteViewController_Phone.h"
#import "ExportViewController.h"
#import "PageViewController.h"
#import "AProposViewController.h"

#import "CloserAppDelegate_Phone.h"
#import "MainViewController_Phone.h"

#import "NetworkStatus.h"

#import "NSDate+addition.h"
#import "Countdown+addition.h"

@interface EditAllCountdownViewController ()

@property (nonatomic, strong) NSArray <Countdown *> * allCountdowns;
@property (nonatomic, strong) NSMutableArray <Countdown *> * includedCountdowns, * notIncludedCountdowns;

- (void)insertCountdown:(Countdown *)countdown atIndexPath:(NSIndexPath *)indexPath;
- (void)removeCountdown:(Countdown *)countdown indexPath:(NSIndexPath *)indexPath;

@end

@implementation EditAllCountdownViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"All Countdowns", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						   target:self action:@selector(doneAction:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						  target:self action:@selector(addAction:)];
	self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.tableView.allowsSelectionDuringEditing = YES;
	self.tableView.editing = YES;
	[self reloadData];
	
	if ([self respondsToSelector:@selector(registerForPreviewingWithDelegate:sourceView:)]) {
		[self registerForPreviewingWithDelegate:self sourceView:self.tableView];
	}
	
	[NetworkStatus startObserving];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusDidChange:)
												 name:kNetworkStatusDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData)
												 name:CountdownDidUpdateNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self reloadData];
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	/* Reload the whole table view (do not show animations) */
	[self.tableView reloadData];
}

- (void)updateData
{
	_allCountdowns = [Countdown allCountdowns].copy;
	_includedCountdowns = [_allCountdowns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"notificationCenter == YES"]].mutableCopy;
	[_includedCountdowns sortUsingComparator:^NSComparisonResult(Countdown * countdown1, Countdown * countdown2) {
		return OrderComparisonResult([_allCountdowns indexOfObject:countdown1], [_allCountdowns indexOfObject:countdown2]); }];
	
	_notIncludedCountdowns = [_allCountdowns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"notificationCenter == NO"]].mutableCopy;
	[_notIncludedCountdowns sortUsingComparator:^NSComparisonResult(Countdown * countdown1, Countdown * countdown2) {
		return OrderComparisonResult([_allCountdowns indexOfObject:countdown1], [_allCountdowns indexOfObject:countdown2]); }];
	
	self.navigationItem.rightBarButtonItem.enabled = (_allCountdowns.count > 0);
}

- (void)reloadData
{
	[self updateData];
	[self.tableView reloadData];
}

- (IBAction)doneAction:(id)sender
{
	NSInteger index = [Countdown indexOfCountdown:_settingsViewController.countdown];
	if (index == NSNotFound) {
		NSInteger countdownsCount = [Countdown allCountdowns].count;
		if (countdownsCount > 0)
			_settingsViewController.countdown = [Countdown countdownAtIndex:(countdownsCount - 1)];
	}
	
	[Countdown synchronize];
	
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)addAction:(id)sender
{
	if (_allCountdowns.count > 18) {// The limit of countdown for the pageControl view is 18
		NSString * title = NSLocalizedString(@"You must delete at least one countdown to add a new countdown.", nil);
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:NULL]];
		[self presentViewController:alert animated:YES completion:NULL];
	} else {
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"New Countdown", nil)
																		message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alert addTextFieldWithConfigurationHandler:^(UITextField * textField) {
			textField.text = [Countdown proposedNameForType:CountdownTypeCountdown];
			textField.placeholder = NSLocalizedString(@"Name", nil);
		}];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Create", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			Countdown * aCountDown = [[Countdown alloc] initWithIdentifier:nil];
			NSString * name = alert.textFields.firstObject.text;
			aCountDown.name = (name.length > 0) ? name : [Countdown proposedNameForType:CountdownTypeCountdown];
			NSIndexPath * indexPath = [NSIndexPath indexPathForRow:_includedCountdowns.count inSection:0];
			[self insertCountdown:aCountDown atIndexPath:indexPath];
			dispatch_async(dispatch_get_main_queue(), ^{
				[self selectCountdownAtIndexPath:indexPath];
			});
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
		[self presentViewController:alert animated:YES completion:NULL];
	}
}

- (void)insertCountdown:(Countdown *)countdown atIndexPath:(NSIndexPath *)indexPath
{
	[[self.undoManager prepareWithInvocationTarget:self] removeCountdown:countdown indexPath:indexPath];
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_DELETE_COUNTDOWN_ACTION", nil)];
	
	CLSLog(@"Insert %@ from indexPath %@", countdown, indexPath);
	
	[Countdown insertCountdown:countdown atIndex:indexPath.row];
	[self.tableView beginUpdates];
	[self.tableView insertRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self updateData];
	[self.tableView endUpdates];
}

- (void)moveCountdownAtIndex:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	NSUInteger newIncludedCount = _includedCountdowns.count - (!indexPath.section && toIndexPath.section);
	const NSUInteger sourceIndex = indexPath.section * newIncludedCount + indexPath.row;
	const NSUInteger destinationIndex = toIndexPath.section * newIncludedCount + toIndexPath.row;
	
	Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
	countdown.notificationCenter = (toIndexPath.section == 0);
	if (sourceIndex != destinationIndex) {
		[Countdown moveCountdownAtIndex:CLIP(0, sourceIndex, _allCountdowns.count - 1)
								toIndex:CLIP(0, destinationIndex, _allCountdowns.count - 1)];
		[[self.undoManager prepareWithInvocationTarget:self] moveCountdownAtIndex:toIndexPath toIndexPath:indexPath];
		[self.undoManager setActionName:NSLocalizedString(@"UNDO_MOVE_COUNTDOWN_ACTION", nil)];
	}
	[self updateData];
	[self.tableView reloadData];
}

- (void)removeCountdown:(Countdown *)countdown indexPath:(NSIndexPath *)indexPath
{
	[[self.undoManager prepareWithInvocationTarget:self] insertCountdown:countdown atIndexPath:indexPath];
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_INSERT_COUNTDOWN_ACTION", nil)];
	
	CLSLog(@"Remove %@ (at index %ld) from indexPath %@", countdown, (long)[Countdown indexOfCountdown:countdown], indexPath);
	
	[Countdown removeCountdown:countdown];
	[self.tableView beginUpdates];
	[self.tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
	[self updateData];
	[self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 5; // "Include in notification center", "Do not include", Import, Export and About
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if /**/ (section == 0)
		return NSLocalizedString(@"Include in notification center", nil);
	else if (section == 1)
		return NSLocalizedString(@"Do not include", nil);
	
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0: return self.includedCountdowns.count;
		case 1: return self.notIncludedCountdowns.count;
		case 2 /* Import */: return 1 + ([NetworkStatus isConnected] == YES); // Remove the "Import with Passwords" if no internet connection
		case 3 /* Export */: return 1;
		case 4 /* About */:  return 1;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	if (indexPath.section <= 1) {
		static NSString * countdownCellIdentifier = @"countdownCellIdentifier";
		cell = [self.tableView dequeueReusableCellWithIdentifier:countdownCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:countdownCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		
		Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
		cell.textLabel.text = countdown.name;
		
		if (countdown.type == CountdownTypeTimer) {
			if /**/ (countdown.durations.count >= 2)
				cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld durations", nil), (long)countdown.durations.count];
			else if (countdown.durations.count == 1)
				cell.detailTextLabel.text = [countdown descriptionOfDurationAtIndex:0];
			else
				cell.detailTextLabel.text = NSLocalizedString(@"No durations", nil);
		} else
			cell.detailTextLabel.text = (countdown.endDate).localizedDescription;
		
	} else {
		static NSString * shareCellIdentifier = @"shareCellIdentifier";
		cell = [self.tableView dequeueReusableCellWithIdentifier:shareCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:shareCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
		}
		cell.textLabel.textColor = nil;
		if (indexPath.section == 2) { // Import
			if (indexPath.row == 0) {
				cell.textLabel.text = NSLocalizedString(@"Import from Calendar", nil);
				
				EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
				BOOL granted = (status == EKAuthorizationStatusAuthorized || status == EKAuthorizationStatusNotDetermined);
				if (!granted) {
					cell.textLabel.textColor = [UIColor grayColor];
				}
			}
			else // Shown only if connected to network
				cell.textLabel.text = NSLocalizedString(@"Import with Passwords", nil);
		} else if (indexPath.section == 3) { // Export
			cell.textLabel.text = NSLocalizedString(@"Export Countdowns...", nil);
		} else { // About
			cell.textLabel.text = NSLocalizedString(@"About...", nil);
		}
	}
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section <= 1);
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section <= 1)
		return UITableViewCellEditingStyleDelete;
	
	return UITableViewCellEditingStyleNone;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
		[self removeCountdown:countdown indexPath:indexPath];
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section <= 1);
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (proposedDestinationIndexPath.section > 1) {
		NSInteger row = _notIncludedCountdowns.count - (sourceIndexPath.section >= 1);
		return [NSIndexPath indexPathForRow:row inSection:1];
	}
	return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	if (destinationIndexPath.section <= 1)
		[self moveCountdownAtIndex:sourceIndexPath toIndexPath:destinationIndexPath];
}

#pragma mark - Table view delegate

- (void)selectCountdownAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section <= 1) {
		[self dismissViewControllerAnimated:YES completion:NULL];
		
		Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
		_settingsViewController.countdown = countdown;
		[Countdown synchronize];
	}
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section <= 1) {
		[self selectCountdownAtIndexPath:indexPath];
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		
	} else if (indexPath.section == 2) { // Import
		switch (indexPath.row) { // Import From Calendar
			case 0: {
				EKAuthorizationStatus status = [EKEventStore authorizationStatusForEntityType:EKEntityTypeEvent];
				BOOL granted = (status == EKAuthorizationStatusAuthorized || status == EKAuthorizationStatusNotDetermined);
				if (granted) {
					ImportFromCalendarViewController * importFromCalendarViewController = [[ImportFromCalendarViewController alloc] initWithStyle:UITableViewStyleGrouped];
					[self.navigationController pushViewController:importFromCalendarViewController animated:YES];
				} else {
					NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer have not access to events from calendar. Check privacy settings for calendar from your %@ settings.", nil), [UIDevice currentDevice].localizedModel];
					UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Access Denied!", nil)
																					message:message
																			 preferredStyle:UIAlertControllerStyleAlert];
					[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
						[alert dismissViewControllerAnimated:YES completion:nil];
					}]];
					[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
						NSURL * settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
						if ([UIApplication instancesRespondToSelector:@selector(openURL:options:completionHandler:)])
							[[UIApplication sharedApplication] openURL:settingsURL options:@{} completionHandler:nil];
						else
IGNORE_DEPRECATION_BEGIN
							[[UIApplication sharedApplication] openURL:settingsURL];
IGNORE_DEPRECATION_END
					}]];
					
					[self presentViewController:alert animated:YES completion:nil];
				}
			}
				break;
			case 1: { // Import with Passwords
				// Show an alertView to introduce the import from passwords (if not already done)
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				BOOL showsIntroductionMessage = !([userDefaults boolForKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"]);
				if (showsIntroductionMessage) {
					NSString * message = NSLocalizedString(@"IMPORT_WITH_PASSWORDS_INTRODUCTION_MESSAGE", nil);
					UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Import with Passwords", nil)
																					message:message
																			 preferredStyle:UIAlertControllerStyleAlert];
					[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
						dispatch_async(dispatch_get_main_queue(), ^{
							ImportFromWebsiteViewController_Phone * controller = [[ImportFromWebsiteViewController_Phone alloc] init];
							UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
							[self presentViewController:navigationController animated:YES completion:NULL];
						});
					}]];
					[self presentViewController:alert animated:YES completion:nil];
					
					[userDefaults setBool:YES forKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"];
				} else {
					ImportFromWebsiteViewController_Phone * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Phone alloc] init];
					UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
					[self presentViewController:navigationController animated:YES completion:NULL];
				}
				break;
			}
			default: break;
		}
	} else if (indexPath.section == 3) { // Export
		ExportViewController * exportViewController = [[ExportViewController alloc] initWithStyle:UITableViewStyleGrouped];
		[self.navigationController pushViewController:exportViewController animated:YES];
	} else {
		AProposViewController * controller = [[AProposViewController alloc] initWithLicenseType:ApplicationLicenseTypeMIT];
		controller.author = @"Lis@cintosh";
		[controller setURLsStrings:@[ @"closer.lisacintosh.com",
									  @"appstore.com/lisacintosh",
									  @"support.lisacintosh.com/closer",
									  @"lisacintosh.com"]];
		controller.repositoryURL = [NSURL URLWithString:@"https://github.com/lisapple/closer"];
		
		UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
		[self presentViewController:navigationController animated:YES completion:nil];
	}
		
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Previewing with 3D Touch

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
	NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
	if (indexPath) {
		Countdown * countdown = nil;
		switch (indexPath.section) {
			case 0: countdown = _includedCountdowns[indexPath.row]; break;
			case 1: countdown = _notIncludedCountdowns[indexPath.row];
			default: break;
		}
		
		if (countdown)
			return [[PageViewController alloc] initWithCountdown:countdown];
	}
	
	return nil;
}

- (void)previewingContext:(id<UIViewControllerPreviewing>)previewingContext commitViewController:(UIViewController *)viewControllerToCommit
{
	if ([viewControllerToCommit isKindOfClass:PageViewController.class]) {
		
		// Dismiss EditAll controller and settings
		[self dismissViewControllerAnimated:NO completion:nil];
		CloserAppDelegate_Phone * appDelegate = (CloserAppDelegate_Phone *)[UIApplication sharedApplication].delegate;
		
		// Select countdown with pressed one
		Countdown * countdown = [(PageViewController *)viewControllerToCommit countdown];
		[appDelegate.mainViewController selectPageWithCountdown:countdown animated:NO];
		
		// Dismiss settings
		[appDelegate.mainViewController dismissViewControllerAnimated:NO completion:nil];
	}
}

- (BOOL)canBecomeFirstResponder
{
	return YES; // Return YES to receive undo from shake gesture
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
