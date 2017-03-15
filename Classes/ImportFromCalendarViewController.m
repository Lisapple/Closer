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
#import "NSDate+addition.h"

@interface ImportResultsController : UITableViewController

@end

@implementation ImportResultsController

@end


@interface ImportFromCalendarViewController ()

@property (nonatomic, strong) ImportResultsController * resultsController;
@property (nonatomic, strong) UISearchController * searchController;
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicatorView;
@property (nonatomic, strong) UITableViewCell * checkedCell;

@property (nonatomic, strong) NSMutableArray <EKCalendar *> * calendars;
@property (nonatomic, strong) NSMutableArray <NSArray <EKEvent *> *> * calendarsEvents;
@property (nonatomic, strong) NSMutableArray <NSArray <EKEvent *> *> * filteredCalendarsEvents;
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
	
	_resultsController = [[ImportResultsController alloc] initWithStyle:UITableViewStyleGrouped];
	_resultsController.tableView.delegate = self;
	_resultsController.tableView.dataSource = self;
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:_resultsController];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
	[self.searchController.searchBar sizeToFit];
	self.tableView.tableHeaderView = self.searchController.searchBar;
	self.definesPresentationContext = YES;
	
	_activityIndicatorView = [[UIActivityIndicatorView alloc] initWithFrame:CGRectZero];
	_activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
	_activityIndicatorView.hidden = NO;
	[self.tableView addSubview:_activityIndicatorView];
	[self.tableView addConstraints:@[ [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual
																	  toItem:_activityIndicatorView attribute:NSLayoutAttributeCenterX multiplier:1 constant:0],
									  [NSLayoutConstraint constraintWithItem:self.tableView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual
																	  toItem:_activityIndicatorView attribute:NSLayoutAttributeCenterY multiplier:1 constant:0]]];
	
	/* When eventStore is released, all events and calendars disapear, we loose all references
	 *   so eventStore is stored as ivar and manage memory manually.
	 * Note: reference to event are created from the evenStore himself, they don't change until the event change.
	 */
	_eventStore = [[EKEventStore alloc] init];
	[_eventStore requestAccessToEntityType:EKEntityTypeEvent
								completion:^(BOOL granted, NSError *error)
	 {
		 dispatch_async(dispatch_get_main_queue(), ^{
			 if (granted) {
				 [self reload];
			 } else if (!granted) {
				 [self dismissViewControllerAnimated:true completion:nil];
			 } else if (error) {
				 _activityIndicatorView.hidden = YES;
				 // Show an alert with the error
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
	dispatch_async(dispatch_get_main_queue(), ^{
		self.tableView.contentOffset = CGPointMake(0, -20.); // Hide search bar
	});
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
	dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
		if (!reloading) {
			reloading = YES;
			
			[_eventStore refreshSourcesIfNecessary];
			
			NSArray * allCalendars = [_eventStore calendarsForEntityType:EKEntityTypeEvent];
			NSInteger count = allCalendars.count;
			
			// Order calendars depending of the number of events
			NSArray * sortedCalendars = [allCalendars sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
				NSUInteger count1 = [_eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj1 includingRecurrent:NO];
				NSUInteger count2 = [_eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj2 includingRecurrent:NO];
				return -OrderComparisonResult(count1, count2); // Descending order
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
			_filteredCalendarsEvents = _calendarsEvents.copy;
			
			NSArray * selectedEventsCopy = _selectedEvents.copy;
			for (EKEvent * event in selectedEventsCopy) {
				if (![allCalendarsEvents containsObject:event])
					[_selectedEvents removeObject:event];
			}
			
			dispatch_async(dispatch_get_main_queue(), ^{
				[self updateUI];
				[self.tableView reloadData];
				_activityIndicatorView.hidden = YES;
				reloading = NO;
			});
		}
	});
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
		label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
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
		if (self.navigationController.viewControllers.count > 1) { // iPhone
			[self.navigationController popViewControllerAnimated:YES];
		} else { // Modal presentation (iPad)
			[self dismissViewControllerAnimated:YES completion:NULL];
			// Send a notification to reload countdowns on main page
			[[NSNotificationCenter defaultCenter] postNotificationName:@"CountdownDidCreateNewNotification" object:nil];
		}
	}
}

- (IBAction)cancel:(id)sender
{
	if (self.navigationController.viewControllers.count > 1) // iPhone
		[self.navigationController popViewControllerAnimated:YES];
	else // Modal presentation (iPad)
		[self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return _calendars.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _filteredCalendarsEvents[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 36.;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	if (_filteredCalendarsEvents[section].count == 0)
		return nil;
	
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
	label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
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
	
	NSArray * events = _filteredCalendarsEvents[indexPath.section];
	EKEvent * event = events[indexPath.row];
	cell.textLabel.text = event.title;
	unsigned long days = event.startDate.daysFromNow;
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ - %@ %ld %@",
								 event.startDate.localizedDescription,
								 NSLocalizedString(@"IMPORT_CALENDAR_IN_DAYS", nil), days,
								 NSLocalizedString((days > 1) ? @"DAYS_MANY" : @"DAY_ONE", nil)];
	cell.accessoryType = ([_selectedEvents containsObject:event]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	EKEvent * event = _filteredCalendarsEvents[indexPath.section][indexPath.row];
	
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
		[_selectedEvents removeObject:event];
		cell.accessoryType = UITableViewCellAccessoryNone;
	} else {
		if (![_selectedEvents containsObject:event])
			[_selectedEvents addObject:event];
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	
	[self updateUI];
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Search results updating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	if (searchController.active && searchController.searchBar.text.length > 0) {
		_filteredCalendarsEvents = [[NSMutableArray alloc] initWithCapacity:_calendarsEvents.count];
		for (NSArray<EKEvent *> * events in _calendarsEvents) {
			NSPredicate * predicate = [NSPredicate predicateWithFormat:@"title CONTAINS[cd] %@", searchController.searchBar.text];
			[_filteredCalendarsEvents addObject:[events filteredArrayUsingPredicate:predicate]];
		}
		[_resultsController.tableView reloadData];
	} else {
		_filteredCalendarsEvents = _calendarsEvents.copy;
		[self.tableView reloadData];
	}
}

- (void)deviceOrientationDidChange:(NSNotification *)aNotification
{
	[self.tableView reloadData];
}

@end
