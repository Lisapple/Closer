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

@interface ImportFromCalendarViewController ()

@property (nonatomic, strong) UITableViewCell * checkedCell;

@property (nonatomic, strong) NSMutableArray <EKCalendar *> * calendars;
@property (nonatomic, strong) NSMutableArray <NSArray <EKEvent *> *> * calendarsEvents;
@property (nonatomic, strong) NSMutableArray <EKEvent *> * selectedEvents;
@property (nonatomic, strong) EKEventStore * eventStore;
@property (nonatomic, assign) NSInteger numberOfEvents;

@end

@implementation ImportFromCalendarViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Choose Events", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
																			  style:UIBarButtonItemStyleDone
																			 target:self action:@selector(import:)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self action:@selector(cancel:)];
	_selectedEvents = [[NSMutableArray alloc] initWithCapacity:10];
	_tableView.contentInset = UIEdgeInsetsMake(20., 0., 0., 0.);
	
	// Show the spinning wheel
	_activityIndicatorView.hidden = NO;
	
	/*
	 When eventStore is released, all events and calendars disapear, we loose all references
	 so eventStore is stored as ivar and manage memory manually.
	 Note: reference to event are created from the evenStore himself, they don't change until the event change.
	 */
	_eventStore = [[EKEventStore alloc] init];
	[_eventStore requestAccessToEntityType:EKEntityTypeEvent
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
				 UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Access Denied!", nil)
																				 message:message
																		  preferredStyle:UIAlertControllerStyleAlert];
				 [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
					 [alert dismissViewControllerAnimated:YES completion:nil]; }]];
				 [self presentViewController:alert animated:YES completion:nil];
				 
			 } else if (error) {
				 /* Show an alert with the error */
				 UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error!", nil)
																				 message:error.localizedDescription
																		  preferredStyle:UIAlertControllerStyleAlert];
				 [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
					 [alert dismissViewControllerAnimated:YES completion:nil]; }]];
				 [self presentViewController:alert animated:YES completion:nil];
			 }
		 });
	 }];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload)
												 name:EKEventStoreChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:EKEventStoreChangedNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)reload
{
	static BOOL reloading = NO;
	if (!reloading) {
		reloading = YES;
		
		[_eventStore refreshSourcesIfNecessary];
		
		NSArray * allCalendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
		NSInteger count = allCalendars.count;
		
		/* Order calendars depending of the number of events */
		NSArray * sortedCalendars = [allCalendars sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			NSUInteger count1 = [_eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj1 includingRecurrent:NO];
			NSUInteger count2 = [_eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj2 includingRecurrent:NO];
			return -OrderComparisonResult(count1, count2);// Add "minus" to reverser order (descending)
		}];
		
		_calendars = [[NSMutableArray alloc] initWithCapacity:count];
		_calendarsEvents = [[NSMutableArray alloc] initWithCapacity:count];
		
		NSMutableArray * allCalendarsEvents = [[NSMutableArray alloc] initWithCapacity:count];
		
		_numberOfEvents = 0;
		for (EKCalendar * calendar in sortedCalendars) {
			NSArray * events = nil;
			if (calendar.type == EKCalendarTypeBirthday) {
				NSDateComponents * comps = [[NSCalendar currentCalendar] components:(NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear)
																		  fromDate:[NSDate date]];
				comps.year = (comps.year + 1);
				events = [_eventStore eventsWithStartDate:[NSDate date]
												 endDate:[[NSCalendar currentCalendar] dateFromComponents:comps]
												calendar:calendar];
			} else // Get all future events from the current calendar
				events = [_eventStore futureEventsFromCalendar:calendar includingRecurrent:NO];
			
			if (events.count > 0) {
				[_calendars addObject:calendar];
				[allCalendarsEvents addObjectsFromArray:events];
				
				if (events) {
					[_calendarsEvents addObject:events];
					_numberOfEvents += events.count;
				}
			}
		}
		
		NSArray * selectedEventsCopy = _selectedEvents.copy;
		for (EKEvent * event in selectedEventsCopy) {
			if (![allCalendarsEvents containsObject:event])
				[_selectedEvents removeObject:event];
		}
		
		[self updateUI];
		[_tableView reloadData];
		
		reloading = NO;
	}
}

- (void)updateUI
{
	self.navigationItem.rightBarButtonItem.enabled = (_selectedEvents.count > 0);
	
	// Show "No Future Events" if no future events (for all calendars)
	if (_numberOfEvents == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, self.tableView.frame.size.height - 84.);
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		label.backgroundColor = [UIColor clearColor];
		label.lineBreakMode = NSLineBreakByCharWrapping;
		label.numberOfLines = 0; // Infinite number of line
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
	for (EKEvent * event in _selectedEvents) {
		if ([Countdown allCountdowns].count > 18) { // If we reach the limit (18 for all countdowns), show an alertView and stop importing
			limitReached = YES;
			break;
		} else {
			Countdown * countdown = [Countdown countdownWithEvent:event];
			[Countdown addCountdown:countdown];
			++index;
		}
	}
	
	if (limitReached) {
		EKEvent * event = _selectedEvents[index]; // Get the first event that is not imported (event at index "index")
		NSInteger remainingCount = _selectedEvents.count - index - 1; // Number of event that remaining excluding "event"
		
		NSString * andMoreString = NSLocalizedString(@"and one more", nil);
		if (remainingCount > 1)
			andMoreString = [NSString stringWithFormat:NSLocalizedString(@"and %i more", nil), remainingCount];
		
		NSString * message = nil;
		if (remainingCount == 0) {
			message = [NSString stringWithFormat:NSLocalizedString(@"Event named \"%@\" could not be imported because the limit of countdown have been reach. %@", nil),
					   event.title, NSLocalizedString(@"Delete some countdowns and retry to import these event.", nil)];
		} else {
			message = [NSString stringWithFormat:NSLocalizedString(@"Events named \"%@\" %@ could not be imported because the limit of countdown have been reach. %@", nil),
					   event.title, andMoreString, NSLocalizedString(@"Delete some countdowns and retry to import these events.", nil)];
		}
		
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Countdown Limit Reached!", nil)
																		message:message
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault
												handler:^(UIAlertAction * action) { [alert dismissViewControllerAnimated:YES completion:nil]; }]];
		[self presentViewController:alert animated:YES completion:nil];
		
		[_selectedEvents removeAllObjects];
		[self.tableView reloadData];
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
	if (self.navigationController.viewControllers.count > 1) // If the view controller has been pop intot the navigationController (iPhone)
		[self.navigationController popViewControllerAnimated:YES];
	else // Else, it has been show as modal
		[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return _calendars.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return (_calendarsEvents[section]).count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 36.;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	CGFloat x = 15.;
	UIView * headerView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 200., 36.)];
	EKCalendar * calendar = _calendars[section];
	if (calendar.type == EKCalendarTypeBirthday) {
		UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(x, 11., 16., 16.)];
		imageView.image = [UIImage imageNamed:@"birthdays"];
		[headerView addSubview:imageView];
		x += imageView.frame.size.width;
	} else {
		UIView * pinView = [[UIView alloc] initWithFrame:CGRectMake(x, 15., 10., 10.)];
		pinView.backgroundColor = [UIColor colorWithCGColor:calendar.CGColor];
		pinView.layer.cornerRadius = 5.;
		[headerView addSubview:pinView];
		x += pinView.frame.size.width;
	}
	
	UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(x + 8., 10., 160., 20.)];
	label.backgroundColor = [UIColor clearColor];
	label.text = calendar.title.uppercaseString;
	label.textColor = [UIColor grayColor];
	label.font = [UIFont systemFontOfSize:14.];
	[headerView addSubview:label];
	
	return headerView;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	NSArray * events = _calendarsEvents[indexPath.section];
	EKEvent * event = events[indexPath.row];// Offset the row by one to count the section adding on tableView:numberOfRowsInSection:
	cell.textLabel.text = event.title;
	cell.detailTextLabel.text = event.startDate.description;
	
	cell.accessoryType = UITableViewCellAccessoryNone;
	if ([_selectedEvents containsObject:event]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	EKEvent * event = _calendarsEvents[indexPath.section][indexPath.row];
	
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		[_selectedEvents removeObject:event];
		cell.accessoryType = UITableViewCellAccessoryNone;
		
	} else {
		if (![_selectedEvents containsObject:event]) // Just check, ther is probably no way to get duplicates, but in the case of...
			[_selectedEvents addObject:event];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	[self updateUI];
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)deviceOrientationDidChange:(NSNotification *)aNotification
{
	[self.tableView reloadData];
}

@end
