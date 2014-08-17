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


@interface ExportViewController (PrivateMethods)

- (void)exportiCalFile;
- (void)exportToCalendar;
- (void)exportToWebsite;

@end

@implementation ExportViewController

@synthesize tableView;

- (void)viewDidLoad
{
	NSString * title = NSLocalizedString(@"Choose Countdowns", nil);
	NSArray * components = [title componentsSeparatedByString:@"\n"];
	
	if (TARGET_IS_IOS7_OR_LATER()) {
		self.title = title;
	} else {
		if (components.count == 1) {
			UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., self.navigationController.navigationBar.frame.size.width, 40.)];
			titleLabel.backgroundColor = [UIColor clearColor];
			titleLabel.text = title;
			titleLabel.font = [UIFont boldSystemFontOfSize:20.];
			titleLabel.minimumScaleFactor = (14. / 20.);
			titleLabel.adjustsFontSizeToFitWidth = YES;
			titleLabel.textAlignment = NSTextAlignmentCenter;
			titleLabel.textColor = [UIColor whiteColor];
			titleLabel.shadowOffset = CGSizeMake(0., -1);
			titleLabel.shadowColor = [UIColor blackColor];
			self.navigationItem.titleView = titleLabel;
			
		} else {
			
			CGRect rect = CGRectMake(0., 0., self.navigationController.navigationBar.frame.size.width, self.navigationController.navigationBar.frame.size.height);
			UIView * titleView = [[UIView alloc] initWithFrame:rect];
			
			float height = self.navigationController.navigationBar.frame.size.height / 3.;
			
			UILabel * upTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., height / 2., self.navigationController.navigationBar.frame.size.width, height)];
			upTitleLabel.backgroundColor = [UIColor clearColor];
			upTitleLabel.text = components[0];
			upTitleLabel.font = [UIFont boldSystemFontOfSize:14.];
			upTitleLabel.textAlignment = NSTextAlignmentCenter;
			upTitleLabel.textColor = [UIColor whiteColor];
			upTitleLabel.shadowOffset = CGSizeMake(0., -1);
			upTitleLabel.shadowColor = [UIColor blackColor];
			
			upTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			
			[titleView addSubview:upTitleLabel];
			
			UILabel * downTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., height * (1.5), self.navigationController.navigationBar.frame.size.width, height)];
			downTitleLabel.backgroundColor = [UIColor clearColor];
			downTitleLabel.text = components[1];
			downTitleLabel.font = [UIFont boldSystemFontOfSize:14.];
			downTitleLabel.textAlignment = NSTextAlignmentCenter;
			downTitleLabel.textColor = [UIColor whiteColor];
			downTitleLabel.shadowOffset = CGSizeMake(0., -1);
			downTitleLabel.shadowColor = [UIColor blackColor];
			
			downTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			
			[titleView addSubview:downTitleLabel];
			
			titleView.autoresizesSubviews = YES;
			self.navigationItem.titleView = titleView;
		}
	}
	
	UIBarButtonItem * importButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Export", nil)
																	  style:UIBarButtonItemStyleDone
																	 target:self
																	 action:@selector(export:)];
	if (!TARGET_IS_IOS7_OR_LATER())
		importButton.tintColor = [UIColor doneButtonColor];
	
	self.navigationItem.rightBarButtonItem = importButton;
	
	UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																				   target:self
																				   action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
	
	/* Get only countdowns */
	NSMutableArray * allCountdowns = [[NSMutableArray alloc] initWithCapacity:10];
	for (Countdown * countdown in [Countdown allCountdowns]) {
		if (countdown.type == CountdownTypeCountdown)
			[allCountdowns addObject:countdown];
	}
	
	countdowns = (NSArray *)allCountdowns;
	selectedCountdowns = [[NSMutableArray alloc] initWithCapacity:countdowns.count];
	
	[self updateUI];
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    if (!TARGET_IS_IOS7_OR_LATER()) {
		tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
		tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		
		UIView * backgroundView = [[UIView alloc] init];
		backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		tableView.backgroundView = backgroundView;
	}
    
	[tableView reloadData];
	
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
		
		tableView.tableFooterView = label;
	}
	
	self.navigationItem.rightBarButtonItem.enabled = (selectedCountdowns.count > 0);
}

- (IBAction)export:(id)sender
{
	BOOL isConnected = [NetworkStatus isConnected];
	
	NSString * title = nil;
	if (isConnected) {
		title = [NSString  stringWithFormat:NSLocalizedString(@"Do you want to export checked countdowns:\ninto iCalendar file format in iTunes Sharing,\nto the calendar app to your %@\nor to Lisacintosh.com to watch them online?", nil), [UIDevice currentDevice].localizedModel];
	} else {
		title = [NSString  stringWithFormat:NSLocalizedString(@"Do you want to export checked countdowns:\ninto iCalendar file format in iTunes Sharing or\nto the calendar app to your %@?", nil), [UIDevice currentDevice].localizedModel];
	}
	
	UIActionSheet * actionSheet = [[UIActionSheet alloc] initWithTitle:title
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
												destructiveButtonTitle:nil
													 otherButtonTitles:NSLocalizedString(@"Export as iCalendar", nil), NSLocalizedString(@"Export to calendar", nil),
								   (isConnected)? NSLocalizedString(@"Export to website", nil) : nil, nil, nil];
	
	actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
	[actionSheet showInView:self.view];// @TODO: If "[NetworkStatus isConnected]" change, remove the actionSheet from screen
}

- (IBAction)cancel:(id)sender
{
	if (self.navigationController.viewControllers.count > 1) {// If the view controller has been pop intot the navigationController (iPhone)
		[self.navigationController popViewControllerAnimated:YES];
	} else {// Else, it has been show as modal
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return countdowns.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	Countdown * countdown = countdowns[indexPath.row];
	if ([countdown.endDate timeIntervalSinceNow] > 0. || countdown.type == CountdownTypeTimer) { // Disable finished countdowns and timers
		
		static NSString * cellIdentifier = @"CellID";
		cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
		}
		
		cell.textLabel.text = countdown.name;
		
		cell.textLabel.textColor = [UIColor blackColor];
		cell.detailTextLabel.text = [countdown.endDate description];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
	} else {
		
		static NSString * finishedCellIdentifier = @"FinishedCellIdentifier";
		cell = [tableView dequeueReusableCellWithIdentifier:finishedCellIdentifier];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:finishedCellIdentifier];
		}
		
		cell.textLabel.text = countdown.name;
		cell.textLabel.textColor = [UIColor grayColor];
		
		cell.detailTextLabel.text = NSLocalizedString(@"Countdown finished", nil);
		cell.detailTextLabel.textColor = [UIColor grayColor];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Countdown * countdown = countdowns[indexPath.row];
	
	if ([countdown.endDate timeIntervalSinceNow] > 0.) {// Change check state only for valid (not finished) countdowns
		UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			
			[selectedCountdowns removeObject:countdown];
			cell.accessoryType = UITableViewCellAccessoryNone;
			
		} else {
			
			if (![selectedCountdowns containsObject:countdown]) {// Just check, there is probably no way to get duplicates, but in the case of...
				[selectedCountdowns addObject:countdown];
			}
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
		
		[self updateUI];
		
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

#pragma mark - Action sheet delegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex) {
		case 0: {// Export to iCalendar
			[self exportiCalFile];
		}
			break;
		case 1: {// Export to iOS' calendar
			[self exportToCalendar];
		}
			break;
		case 2: {// Export to closer website OR Cancel
			/* *Four* buttons means that we have "Export to website", else means that is the cancel button */
			if (actionSheet.numberOfButtons == 4)
				[self exportToWebsite];
		}
			break;
		default:// Cancel
			break;
	}
	
}

- (void)exportiCalFile
{
	if (selectedCountdowns.count  > 0) {// Create export file only when we've got one or many selected countdowns
		
		NSString * name = ((Countdown *)selectedCountdowns[0]).name;
		NSString * filename = [NSString stringWithFormat:NSLocalizedString(@"Export %@", nil), name];
		
		/* If we have many countdown, use somthing like "{First countdown name} and {remaining count} more". ex: "Countdown 1 and 2 more.ics" */
		if (selectedCountdowns.count == 2) {// If we have just "1 more", show as "one more", it's just a detail but it makes all the difference!
			filename = [filename stringByAppendingString:NSLocalizedString(@" and one more", nil)];
		} else if (selectedCountdowns.count > 2) {// If we have 2 or more to show, use regular "and %i more"
			filename = [filename stringByAppendingFormat:NSLocalizedString(@" and %i more", nil), (selectedCountdowns.count - 1)];
		}
		
		NSString * extension = @"ics";
		
		NSString * documentFolderPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
		NSString * path = [NSString stringWithFormat:@"%@/%@.%@", documentFolderPath, filename, extension];// ex: "~/Documents/Countdown 1 and 2 more.ics"
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {// If file already exist at path, try to find a free filename
			int index = 1;
			while (1) {// While we don't have an available filename, add "(%i++)" at the end the the filename
				path = [NSString stringWithFormat:@"%@/%@ (%i).%@", documentFolderPath, filename, index++, extension];// ex: "~/Documents/Countdown 1 and 2 more (2).ics"
				if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {// Break only when we've got a free filename
					break;
				}
			}
			
		}
		
		VCalendar * calendar = [[VCalendar alloc] initWithVersion:@"2.0"];
		for (Countdown * countdown in selectedCountdowns) {
			
			VEvent * event = [VEvent eventFromCountdown:countdown];
			[calendar addEvent:event];
		}
		
		[calendar writeToFile:path atomically:YES];
		
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"You can retreive the export file as \"%@.%@\" into iTunes Sharing.", nil), filename, extension];
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Succeed!", nil)
															 message:message
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"OK", nil)
												   otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)exportToCalendar
{
	BOOL success = YES;
	EKEventStore * eventStore = [[EKEventStore alloc] init];
	EKCalendar * defaultCalendar = [eventStore defaultCalendarForNewEvents];// Choose default calendar to put events
	for (Countdown * countdown in selectedCountdowns) {
		
		EKEvent * event = [EKEvent eventWithEventStore:eventStore];
		event.startDate = countdown.endDate;
		event.endDate = [countdown.endDate dateByAddingTimeInterval:kDefaultEventDuration];
		event.title = countdown.name;
		event.notes = countdown.message;
		
		event.calendar = defaultCalendar;
		
		NSError * error = nil;
		BOOL succeed = [eventStore saveEvent:event span:EKSpanThisEvent error:&error];
		if (!succeed && error) {
			NSLog(@"saveEvent:span:error: %@", [error localizedDescription]); // @TODO: Show errors
			success = NO;
		}
	}
	
	if (success) {
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"All countdowns have been added as event in the calendar app into the calendar named \"%@\".", nil), defaultCalendar.title];
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Export Succeed!", nil)
															 message:message
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"OK", nil)
												   otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)exportToWebsite
{
	ExportToWebsiteViewController * exportToWebsiteViewController = [[ExportToWebsiteViewController alloc] init];
	exportToWebsiteViewController.countdowns = selectedCountdowns;
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:exportToWebsiteViewController];
	
	navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentViewController:navigationController animated:YES completion:NULL];
}

@end
