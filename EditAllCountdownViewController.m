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
#import "PageViewController.h"

#import "CloserAppDelegate_Phone.h"
#import "MainViewController_Phone.h"

#import "NetworkStatus.h"

#import "NSDate+addition.h"
#import "Countdown+addition.h"

#import <Crashlytics/Crashlytics.h>

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
																						   target:self action:@selector(done:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
																						  target:self action:@selector(add:)];
	_tableView.delegate = self;
	_tableView.dataSource = self;
    _tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	_tableView.allowsSelectionDuringEditing = YES;
	_tableView.editing = YES;
	[self reloadData];
	
	[self registerForPreviewingWithDelegate:self sourceView:self.tableView];
	
	[NetworkStatus startObserving];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkStatusDidChange:)
												 name:kNetworkStatusDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData)
												 name:CountdownDidUpdateNotification object:nil];
}

- (void)networkStatusDidChange:(NSNotification *)notification
{
	/* Reload the whole table view (do not show animations) */
	[_tableView reloadData];
}

- (IBAction)moreInfo:(id)sender
{
	NSDictionary * infoDictionary = [NSBundle mainBundle].infoDictionary;
	NSString * title = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © %lu, Lis@cintosh", nil), infoDictionary[@"CFBundleShortVersionString"], [NSDate date].year];
	UIAlertController * actionSheet = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"closer.lisacintosh.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://closer.lisacintosh.com"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"support.lisacintosh.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://support.lisacintosh.com/closer/"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"lisacintosh.com" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://lisacintosh.com/"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:@"appstore.com/lisacintosh" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://appstore.com/lisacintosh/"]]; }]];
	[actionSheet addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
	[self presentViewController:actionSheet animated:YES completion:nil];
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
}

- (void)reloadData
{
	[self updateData];
	[self.tableView reloadData];
	self.navigationItem.rightBarButtonItem.enabled = (_allCountdowns.count > 0);
}

- (IBAction)done:(id)sender
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

- (IBAction)add:(id)sender
{
	if (_allCountdowns.count > 18) {// The limit of countdown for the pageControl view is 18
		NSString * title = NSLocalizedString(@"You must delete at least one countdown to add a new countdown.", nil);
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:NULL]];
		[self presentViewController:alert animated:YES completion:NULL];
		
	} else {
		Countdown * aCountDown = [[Countdown alloc] initWithIdentifier:nil];
		aCountDown.name = [Countdown proposedNameForType:CountdownTypeCountdown];
		NSIndexPath * indexPath = [NSIndexPath indexPathForRow:_includedCountdowns.count inSection:0];
		[self insertCountdown:aCountDown atIndexPath:indexPath];
		
		[_tableView scrollToRowAtIndexPath:indexPath
						 atScrollPosition:UITableViewScrollPositionMiddle
								 animated:YES];
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
	NSUInteger sourceIndex = indexPath.section * _includedCountdowns.count + indexPath.row;
	NSUInteger destinationIndex = toIndexPath.section * _includedCountdowns.count + toIndexPath.row;
	
	Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
	countdown.notificationCenter = (toIndexPath.section == 0);
	if (sourceIndex != destinationIndex) {
		[Countdown moveCountdownAtIndex:MIN(MAX(0, sourceIndex), _allCountdowns.count - 1)
								toIndex:MIN(MAX(0, destinationIndex), _allCountdowns.count - 1)];
		[[self.undoManager prepareWithInvocationTarget:self] moveCountdownAtIndex:toIndexPath toIndexPath:indexPath];
		[self.undoManager setActionName:NSLocalizedString(@"UNDO_MOVE_COUNTDOWN_ACTION", nil)];
	}
	[self updateData];
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
	return 4; // "Include in notification center", "Do not include", Import and Export
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if /**/ (section == 0)
		return NSLocalizedString(@"Include in notification center", nil);
	else if (section == 1)
		return NSLocalizedString(@"Do not include", nil);
	
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
	return (section == 3) ? 44. : 0.;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	if (section == 3) { // Info "i" button on the right
		UIView * contentView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., self.view.frame.size.width, 44.)];
		UIButton * button = [UIButton buttonWithType:UIButtonTypeInfoLight];
		const CGFloat kMargin = 23;
		button.frame = CGRectMake(self.view.frame.size.width - 15. - kMargin, 44. - kMargin, kMargin, kMargin);
		[button addTarget:self action:@selector(moreInfo:) forControlEvents:UIControlEventTouchUpInside];
		button.tintColor = self.view.window.tintColor;
		[contentView addSubview:button];
		return contentView;
	}
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	switch (section) {
		case 0: return self.includedCountdowns.count;
		case 1: return self.notIncludedCountdowns.count;
		case 2 /* Import */: return 1 + ([NetworkStatus isConnected] == YES); // Remove the "Import with Passwords" if no internet connection
		case 3 /* Export */ : return 1;
	}
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	if (indexPath.section <= 1) {
		static NSString * countdownCellIdentifier = @"countdownCellIdentifier";
		cell = [_tableView dequeueReusableCellWithIdentifier:countdownCellIdentifier];
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
			cell.detailTextLabel.text = (countdown.endDate).description;
		
	} else {
		static NSString * shareCellIdentifier = @"shareCellIdentifier";
		cell = [_tableView dequeueReusableCellWithIdentifier:shareCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:shareCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
		}
		if (indexPath.section == 2) { // Import
			if (indexPath.row == 0)
				cell.textLabel.text = NSLocalizedString(@"Import from Calendar", nil);
			else // Shown only if connected to network
				cell.textLabel.text = NSLocalizedString(@"Import with Passwords", nil);
		} else // Export
			cell.textLabel.text = NSLocalizedString(@"Export Countdowns...", nil);
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
		if (sourceIndexPath.section == 0) {
			return [NSIndexPath indexPathForRow:_notIncludedCountdowns.count inSection:1];
		} else {
			return [NSIndexPath indexPathForRow:(_notIncludedCountdowns.count-1) inSection:1];
		}
	}
	
	return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	if (destinationIndexPath.section <= 1)
		[self moveCountdownAtIndex:sourceIndexPath toIndexPath:destinationIndexPath];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section <= 1) {
        Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
        _settingsViewController.countdown = countdown;
        [Countdown synchronize];
        [aTableView deselectRowAtIndexPath:indexPath animated:YES];
        [self dismissViewControllerAnimated:YES completion:NULL];
        
    } else if (indexPath.section == 2) { // Import
			switch (indexPath.row) { // Import From Calendar
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
						UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Access Denied!", nil)
																						message:message
																				 preferredStyle:UIAlertControllerStyleAlert];
						[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
							[alert dismissViewControllerAnimated:YES completion:nil]; }]];
						[self presentViewController:alert animated:YES completion:nil];
					}
				}
					break;
				case 1: { // Import with Passwords
					/* Show an alertView to introduce the import from passwords (if not already done) */
					NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
					BOOL showsIntroductionMessage = !([userDefaults boolForKey:@"ImportWithPasswordsIntroductionMessageAlreadyShown"]);
					if (showsIntroductionMessage) {
						NSString * message = NSLocalizedString(@"IMPORT_WITH_PASSWORDS_INTRODUCTION_MESSAGE", nil);
						UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Import with Passwords", nil)
																						message:message
																				 preferredStyle:UIAlertControllerStyleAlert];
						[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
							[alert dismissViewControllerAnimated:YES completion:^{
								ImportFromWebsiteViewController_Phone * importFromWebsiteViewController = [[ImportFromWebsiteViewController_Phone alloc] init];
								UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:importFromWebsiteViewController];
								[self presentViewController:navigationController animated:YES completion:NULL];
							}]; }]];
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
	} else { // Export
		ExportViewController * exportViewController = [[ExportViewController alloc] init];
		[self.navigationController pushViewController:exportViewController animated:YES];
	}
		
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Previewing with 3D Touch

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location
{
	NSIndexPath * indexPath = [self.tableView indexPathForRowAtPoint:location];
	if (indexPath) {
		Countdown * countdown = nil;
		if /**/ (indexPath.section == 0) {
			countdown = _includedCountdowns[indexPath.row];
		}
		else if (indexPath.section == 1) {
			countdown = _notIncludedCountdowns[indexPath.row];
		}
		if (countdown) {
			return [[PageViewController alloc] initWithCountdown:countdown];
		}
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
	return YES;// Return YES to receive undo from shake gesture
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
