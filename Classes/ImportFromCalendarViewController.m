//
//  ImportFromCalendarViewController.m
//  Closer
//
//  Created by Max on 09/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFromCalendarViewController.h"

#import "SectionCalendarTableViewCell.h"

#import "Countdown+addition.h"
#import "EKEventStore+additions.h"

@implementation ImportFromCalendarViewController

@synthesize tableView;
@synthesize activityIndicatorView = _activityIndicatorView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Choose Events", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(import:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self
																						  action:@selector(cancel:)];
	
	selectedEvents = [[NSMutableArray alloc] initWithCapacity:10];
	
	tableView.delegate = self;
	tableView.dataSource = self;
	tableView.contentInset = UIEdgeInsetsMake(20., 0., 0., 0.);
	[tableView reloadData];
	
	/* Show the spinning wheel */
	_activityIndicatorView.hidden = NO;
	
	/*
	 When eventStore is released, all events and calendars disapear, we loose all references
	 so eventStore is stored as ivar and manage memory manually.
	 Note: reference to event are created from the evenStore himself, they don't change until the event change.
	 */
	eventStore = [[EKEventStore alloc] init];
	[eventStore requestAccessToEntityType:EKEntityTypeEvent
							   completion:^(BOOL granted, NSError *error)
	 {
		 dispatch_async(dispatch_get_main_queue(), ^{
			 
			 /* Hide the spinning wheel */
			 _activityIndicatorView.hidden = YES;
			 
			 NSDebugLog(@"Granted: %@", (granted) ? @"Yes" : @"No");
			 
			 if (granted) {
				 [self reload];
				 
			 } else if (!granted) {
				 NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer have not access to events from calendar. Check privacy settings for calendar from your %@ settings.", nil), [UIDevice currentDevice].localizedModel];
				 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied!", nil)
											 message:message
											delegate:nil
								   cancelButtonTitle:NSLocalizedString(@"OK", nil)
								   otherButtonTitles:nil] show];
				 
			 } else if (error) {
				 /* Show an alert with the error */
				 [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", nil)
											 message:error.localizedDescription
											delegate:nil
								   cancelButtonTitle:NSLocalizedString(@"OK", nil)
								   otherButtonTitles:nil] show];
			 }
		 });
	 }];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reload)
												 name:EKEventStoreChangedNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:EKEventStoreChangedNotification
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIDeviceOrientationDidChangeNotification
												  object:nil];
}

- (void)reload
{
	static BOOL reloading = NO;
	if (!reloading) {
		reloading = YES;
		
		[eventStore refreshSourcesIfNecessary];
		
		NSArray * allCalendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
		NSInteger count = allCalendars.count;
		
		/* Order calendars depending of the number of events */
		NSArray * sortedCalendars = [allCalendars sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSUInteger count1 = [eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj1 includingRecurrent:NO];
			NSUInteger count2 = [eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj2 includingRecurrent:NO];
			return -OrderComparisonResult(count1, count2);// Add "minus" to reverser order (descending)
		}];
		
		calendars = [[NSMutableArray alloc] initWithCapacity:count];
		calendarsEvents = [[NSMutableArray alloc] initWithCapacity:count];
		
		NSMutableArray * allCalendarsEvents = [[NSMutableArray alloc] initWithCapacity:count];
		
		numberOfEvents = 0;
		for (EKCalendar * calendar in sortedCalendars) {
			NSArray * events = nil;
			if (calendar.type == EKCalendarTypeBirthday) {
				NSDateComponents * comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear)
																		  fromDate:[NSDate date]];
				comps.year = (comps.year + 1);
				events = [eventStore eventsWithStartDate:[NSDate date]
												 endDate:[[NSCalendar currentCalendar] dateFromComponents:comps]
												calendar:calendar];
			} else {
				/* Get all future events from the current calendar */
				events = [eventStore futureEventsFromCalendar:calendar includingRecurrent:NO];
			}
			
			if (events.count > 0) {
				[calendars addObject:calendar];
				[allCalendarsEvents addObjectsFromArray:events];
				
				if (events) {
					[calendarsEvents addObject:events];
					numberOfEvents += events.count;
				}
			}
		}
		
		NSArray * selectedEventsCopy = selectedEvents.copy;
		for (EKEvent * event in selectedEventsCopy) {
			if (![allCalendarsEvents containsObject:event])
				[selectedEvents removeObject:event];
		}
		
		[self updateUI];
		[tableView reloadData];
		
		reloading = NO;
	}
}

- (void)updateUI
{
	self.navigationItem.rightBarButtonItem.enabled = (selectedEvents.count > 0);
	
	/* Show "No Future Events" if no future events (for all calendars) */
	if (numberOfEvents == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, self.tableView.frame.size.height - 84.);
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		label.backgroundColor = [UIColor clearColor];
		label.lineBreakMode = NSLineBreakByCharWrapping;
		label.numberOfLines = 0;// Infinite number of line
		label.textAlignment = NSTextAlignmentCenter;
		label.textColor = [UIColor blackColor];
		label.font = [UIFont systemFontOfSize:17.];
		label.text = NSLocalizedString(@"No Future Events", nil);
		self.tableView.tableHeaderView = label;
	}
}

- (IBAction)import:(id)sender
{
	BOOL limitReached = NO;
	NSInteger index = 0;
	for (EKEvent * event in selectedEvents) {
		
		if ([Countdown allCountdowns].count > 18) {// If we reach the limit (18 for all countdowns), show an alertView and stop importing
			limitReached = YES;
			break;
		} else {
			Countdown * countdown = [Countdown countdownWithEvent:event];
			[Countdown addCountdown:countdown];
			index++;
		}
	}
	
	if (limitReached) {
		EKEvent * event = selectedEvents[index];// Get the first event that is not imported (event at index "index")
		NSInteger remainingCount = selectedEvents.count - index - 1;// Number of event that remaining excluding "event"
		
		NSString * andMoreString = NSLocalizedString(@"and one more", nil);
		if (remainingCount > 1) {
			andMoreString = [NSString stringWithFormat:NSLocalizedString(@"and %i more", nil), remainingCount];
		}
		
		NSString * message = nil;
		if (remainingCount == 0) {
			message = [NSString stringWithFormat:NSLocalizedString(@"Event named \"%@\" could not be imported because the limit of countdown have been reach. %@", nil),
					   event.title, NSLocalizedString(@"Delete some countdowns and retry to import these event.", nil)];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString(@"Events named \"%@\" %@ could not be imported because the limit of countdown have been reach. %@", nil),
					   event.title, andMoreString, NSLocalizedString(@"Delete some countdowns and retry to import these events.", nil)];
		}
		
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Countdown Limit Reached!", nil)
															 message:message
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"OK", nil)
												   otherButtonTitles:nil];
		[alertView show];
		
		[selectedEvents removeAllObjects];
		[tableView reloadData];
		[self updateUI];
	} else {
		if (self.navigationController.viewControllers.count > 1) {// If the view controller has been pop intot the navigationController (iPhone)
			[self.navigationController popViewControllerAnimated:YES];
		} else {// Else, it has been show as modal
			[self dismissViewControllerAnimated:YES completion:NULL];
			/* Send a notification to reload countdowns on main page */
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CountdownDidCreateNewNotification" object:nil];
		}
	}
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
	return calendars.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return ((NSArray *)calendarsEvents[section]).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 36.;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	EKCalendar * calendar = calendars[section];
	
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 200., 36.)];
	
	if (calendar.type == EKCalendarTypeBirthday) {
		UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(8., 11., 16., 16.)];
		imageView.image = [UIImage imageNamed:@"birthdays-iOS7"];
		[headerView addSubview:imageView];
	} else {
		UIView * pinView = [[UIView alloc] initWithFrame:CGRectMake(15., 15., 10., 10.)];
		pinView.backgroundColor = [UIColor colorWithCGColor:calendar.CGColor];
		pinView.layer.cornerRadius = 5.;
		[headerView addSubview:pinView];
	}
	
	UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(30., 10., 160., 20.)];
	label.backgroundColor = [UIColor clearColor];
	label.text = calendar.title.uppercaseString;
	label.textColor = [UIColor grayColor];
	label.font = [UIFont systemFontOfSize:14.];
	[headerView addSubview:label];
	
	return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSArray * events = calendarsEvents[indexPath.section];
	
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	EKEvent * event = events[indexPath.row];// Offset the row by one to count the section adding on tableView:numberOfRowsInSection:
	cell.textLabel.text = event.title;
	cell.detailTextLabel.text = [event.startDate description];
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	if ([selectedEvents containsObject:event]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	EKEvent * event = calendarsEvents[indexPath.section][indexPath.row];
	
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		[selectedEvents removeObject:event];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
	} else {
		if (![selectedEvents containsObject:event]) // Just check, ther is probably no way to get duplicates, but in the case of...
			[selectedEvents addObject:event];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	[self updateUI];
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)deviceOrientationDidChange:(NSNotification *)aNotification
{
	[tableView reloadData];
}


@end
