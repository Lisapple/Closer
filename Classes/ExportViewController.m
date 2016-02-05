//
//  ExportViewController.m
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ExportViewController.h"

#import "ExportToWebsiteViewController.h"

#import "VCalendar.h"

#import "NetworkStatus.h"

@interface ExportViewController ()

@property (nonatomic, strong) NSArray <Countdown *> * countdowns;
@property (nonatomic, strong) NSMutableArray <Countdown *> * selectedCountdowns;

- (void)exportiCalFile;
- (void)exportToCalendar;
- (void)exportToWebsite;

@end

@implementation ExportViewController

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Choose Countdowns", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Export", nil)
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(exportAction:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
	/* Get only countdowns */
	NSMutableArray * allCountdowns = [[NSMutableArray alloc] initWithCapacity:10];
	for (Countdown * countdown in [Countdown allCountdowns]) {
		if (countdown.type == CountdownTypeCountdown)
			[allCountdowns addObject:countdown];
	}
	
	_countdowns = (NSArray *)allCountdowns;
	_selectedCountdowns = [[NSMutableArray alloc] initWithCapacity:_countdowns.count];
	
	[self updateUI];
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	[_tableView reloadData];
	
    [super viewDidLoad];
}

- (void)updateUI
{
	NSInteger count = 0;
	for (Countdown * countdown in [Countdown allCountdowns]) {
		if (countdown.type == CountdownTypeCountdown)
			count++;
	}
	
	/* Show a placeholder "No Countdowns" */
	if (count == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, self.tableView.frame.size.height);
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
		label.backgroundColor = [UIColor clearColor];
		label.lineBreakMode = NSLineBreakByWordWrapping;
		label.numberOfLines = 0;// Infinite number of line
		label.textColor = [UIColor darkGrayColor];
		label.textAlignment = NSTextAlignmentCenter;
		label.font = [UIFont boldSystemFontOfSize:18.];
		label.shadowColor = [UIColor colorWithWhite:1. alpha:0.7];
		label.shadowOffset = CGSizeMake(0., 1.);
		label.text = NSLocalizedString(@"No Countdowns", nil);
		_tableView.tableFooterView = label;
	}
	
	self.navigationItem.rightBarButtonItem.enabled = (_selectedCountdowns.count > 0);
}

- (IBAction)exportAction:(id)sender
{
	BOOL isConnected = [NetworkStatus isConnected];
	
	NSString * title = nil;
	if (isConnected) {
		title = [NSString  stringWithFormat:NSLocalizedString(@"Do you want to export checked countdowns:\ninto iCalendar file format in iTunes Sharing,\nto the calendar app to your %@\nor to Lisacintosh.com to watch them online?", nil), [UIDevice currentDevice].localizedModel];
	} else {
		title = [NSString  stringWithFormat:NSLocalizedString(@"Do you want to export checked countdowns:\ninto iCalendar file format in iTunes Sharing or\nto the calendar app to your %@?", nil), [UIDevice currentDevice].localizedModel];
	}
	
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Export as iCalendar", nil) style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) { [self exportiCalFile]; }]];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Export to calendar", nil) style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) { [self exportToCalendar]; }]];
	if (isConnected) {
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Export to website", nil) style:UIAlertActionStyleDefault
												handler:^(UIAlertAction * action) { [self exportToWebsite]; }]];
	}
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:NULL]];
	[self presentViewController:alert animated:YES completion:NULL];
}

- (IBAction)cancel:(id)sender
{
	if (self.navigationController.viewControllers.count > 1) {// If the view controller has been pop intot the navigationController (iPhone)
		[self.navigationController popViewControllerAnimated:YES];
	} else {// Else, it has been show as modal
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _countdowns.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	Countdown * countdown = _countdowns[indexPath.row];
	if (countdown.endDate.timeIntervalSinceNow > 0. || countdown.type == CountdownTypeTimer) { // Disable finished countdowns and timers
		static NSString * cellIdentifier = @"CellID";
		cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
			cell.textLabel.textColor = [UIColor blackColor];
			cell.selectionStyle = UITableViewCellSelectionStyleGray;
		}
		
		cell.textLabel.text = countdown.name;
		cell.detailTextLabel.text = countdown.endDate.description;
		
	} else {
		static NSString * finishedCellIdentifier = @"FinishedCellIdentifier";
		cell = [_tableView dequeueReusableCellWithIdentifier:finishedCellIdentifier];
		
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:finishedCellIdentifier];
			cell.textLabel.textColor = [UIColor grayColor];
			cell.detailTextLabel.textColor = [UIColor grayColor];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		cell.textLabel.text = countdown.name;
		cell.detailTextLabel.text = NSLocalizedString(@"Countdown finished", nil);
	}
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Countdown * countdown = _countdowns[indexPath.row];
	
	if (countdown.endDate.timeIntervalSinceNow > 0.) {// Change check state only for valid (not finished) countdowns
		UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			[_selectedCountdowns removeObject:countdown];
			cell.accessoryType = UITableViewCellAccessoryNone;
		} else {
			if (![_selectedCountdowns containsObject:countdown]) // Just check, there is probably no way to get duplicates, but in the case of...
				[_selectedCountdowns addObject:countdown];
			
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		[self updateUI];
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (void)exportiCalFile
{
	if (_selectedCountdowns.count  > 0) {// Create export file only when we've got one or many selected countdowns
		
		NSString * name = _selectedCountdowns.firstObject.name;
		NSString * filename = [NSString stringWithFormat:NSLocalizedString(@"Export %@", nil), name];
		
		/* If we have many countdown, use somthing like "{First countdown name} and {remaining count} more". ex: "Countdown 1 and 2 more.ics" */
		if (_selectedCountdowns.count == 2) {// If we have just "1 more", show as "one more", it's just a detail but it makes all the difference!
			filename = [filename stringByAppendingString:NSLocalizedString(@" and one more", nil)];
		} else if (_selectedCountdowns.count > 2) {// If we have 2 or more to show, use regular "and %i more"
			filename = [filename stringByAppendingFormat:NSLocalizedString(@" and %i more", nil), (_selectedCountdowns.count - 1)];
		}
		
		const NSString * extension = @"ics";
		NSString * documentFolderPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
		NSString * path = [NSString stringWithFormat:@"%@/%@.%@", documentFolderPath, filename, extension];// ex: "~/Documents/Countdown 1 and 2 more.ics"
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {// If file already exist at path, try to find a free filename
			int index = 1;
			while (1) {// While we don't have an available filename, add "(%i++)" at the end the the filename
				path = [NSString stringWithFormat:@"%@/%@ (%i).%@", documentFolderPath, filename, index++, extension];// ex: "~/Documents/Countdown 1 and 2 more (2).ics"
				if (![[NSFileManager defaultManager] fileExistsAtPath:path]) // Break only when we've got a free filename
					break;
			}
		}
		
		VCalendar * calendar = [[VCalendar alloc] initWithVersion:@"2.0"];
		for (Countdown * countdown in _selectedCountdowns)
			[calendar addEvent:[VEvent eventFromCountdown:countdown]];
		
		[calendar writeToFile:path atomically:YES];
		
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"You can retreive the export file as \"%@.%@\" into iTunes Sharing.", nil), filename, extension];
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Export Succeed!", nil)
																		message:message preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault
												handler:^(UIAlertAction * action) { [alert dismissViewControllerAnimated:YES completion:nil]; }]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)exportToCalendar
{
	BOOL success = YES;
	EKEventStore * eventStore = [[EKEventStore alloc] init];
	EKCalendar * defaultCalendar = eventStore.defaultCalendarForNewEvents;// Choose default calendar to put events
	for (Countdown * countdown in _selectedCountdowns) {
		
		EKEvent * event = [EKEvent eventWithEventStore:eventStore];
		event.startDate = countdown.endDate;
		event.endDate = [countdown.endDate dateByAddingTimeInterval:kDefaultEventDuration];
		event.title = countdown.name;
		event.notes = countdown.message;
		event.calendar = defaultCalendar;
		
		NSError * error = nil;
		BOOL succeed = [eventStore saveEvent:event span:EKSpanThisEvent error:&error];
		if (!succeed && error) {
			NSLog(@"saveEvent:span:error: %@", error.localizedDescription); // @TODO: Show errors
			success = NO;
		}
	}
	
	if (success) {
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"All countdowns have been added as event in the calendar app into the calendar named \"%@\".", nil), defaultCalendar.title];
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Export Succeed!", nil)
																		message:message preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[alert dismissViewControllerAnimated:YES completion:nil]; }]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)exportToWebsite
{
	ExportToWebsiteViewController * exportToWebsiteViewController = [[ExportToWebsiteViewController alloc] init];
	exportToWebsiteViewController.countdowns = _selectedCountdowns;
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:exportToWebsiteViewController];
	
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:navigationController animated:YES completion:NULL];
}

@end
