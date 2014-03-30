//
//  ImportFromCalendarViewController.m
//  Closer
//
//  Created by Max on 09/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFromCalendarViewController.h"

#import "CheckTableViewCell.h"
#import "SectionCalendarTableViewCell.h"

#import "UIColor+addition.h"
#import "Countdown+addition.h"
#import "EKEventStore+additions.h"

@implementation ImportFromCalendarViewController

@synthesize tableView;
@synthesize activityIndicatorView = _activityIndicatorView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
	NSString * title = NSLocalizedString(@"Choose Events", nil);
	NSArray * components = [title componentsSeparatedByString:@"\n"];
	
	if (components.count == 1) {
		UILabel * titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., self.navigationController.navigationBar.frame.size.width, 40.)];
		titleLabel.backgroundColor = [UIColor clearColor];
		titleLabel.text = title;
		titleLabel.font = [UIFont boldSystemFontOfSize:20.];
		titleLabel.minimumFontSize = 14.;
		titleLabel.adjustsFontSizeToFitWidth = YES;
		titleLabel.textAlignment = UITextAlignmentCenter;
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
		upTitleLabel.text = [components objectAtIndex:0];
		upTitleLabel.font = [UIFont boldSystemFontOfSize:14.];
		upTitleLabel.textAlignment = UITextAlignmentCenter;
		upTitleLabel.textColor = [UIColor whiteColor];
		upTitleLabel.shadowOffset = CGSizeMake(0., -1);
		upTitleLabel.shadowColor = [UIColor blackColor];
		
		upTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		
		[titleView addSubview:upTitleLabel];
		
		UILabel * downTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., height * (1.5), self.navigationController.navigationBar.frame.size.width, height)];
		downTitleLabel.backgroundColor = [UIColor clearColor];
		downTitleLabel.text = [components objectAtIndex:1];
		downTitleLabel.font = [UIFont boldSystemFontOfSize:14.];
		downTitleLabel.textAlignment = UITextAlignmentCenter;
		downTitleLabel.textColor = [UIColor whiteColor];
		downTitleLabel.shadowOffset = CGSizeMake(0., -1);
		downTitleLabel.shadowColor = [UIColor blackColor];
		
		downTitleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		
		[titleView addSubview:downTitleLabel];
		
		titleView.autoresizesSubviews = YES;
		self.navigationItem.titleView = titleView;
	}
	
	
	UIBarButtonItem * importButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
																	  style:UIBarButtonItemStyleDone
																	 target:self
																	 action:@selector(import:)];
	if ([importButton respondsToSelector:@selector(setTintColor:)])
		importButton.tintColor = [UIColor doneButtonColor];
	
	self.navigationItem.rightBarButtonItem = importButton;
	
	UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																				   target:self
																				   action:@selector(cancel:)];
	self.navigationItem.leftBarButtonItem = cancelButton;
	
	/*
	 When eventStore is released, all events and calendars disapear, we loose all references
	 so eventStore is stored as ivar and manage memory manually.
	 Note: reference to event are created from the evenStore himself, they don't change until the event change.
	 */
	eventStore = [[EKEventStore alloc] init];
	
	if ([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
		
		/* Show the spinning wheel */
		_activityIndicatorView.hidden = NO;
		
		[eventStore requestAccessToEntityType:EKEntityTypeEvent
								   completion:^(BOOL granted, NSError *error) {
									   
									   /* Hide the spinning wheel */
									   _activityIndicatorView.hidden = YES;
									   
									   if (granted) {
										   [self reload];
									   } else if (!granted) {
										   
										   NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer have not access to events from calendar. Check privacy settings for calendar from your %@ settings.", nil), [UIDevice currentDevice].localizedModel];
										   UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Access Denied!", nil)
																								message:message
																							   delegate:nil
																					  cancelButtonTitle:NSLocalizedString(@"OK", nil)
																					  otherButtonTitles:nil];
										   [alertView show];
										   
									   } else if (error) {
										   /* Show an alert with the error */
										   UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", nil)
																								message:error.localizedDescription
																							   delegate:nil
																					  cancelButtonTitle:NSLocalizedString(@"OK", nil)
																					  otherButtonTitles:nil];
										   [alertView show];
									   }
								   }];
	}
	
	selectedEvents = [[NSMutableArray alloc] initWithCapacity:10];
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView = backgroundView;
	
	[tableView reloadData];
	
    [super viewDidLoad];
	
	[self reload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reload)
												 name:EKEventStoreChangedNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(deviceOrientationDidChange:)
												 name:UIDeviceOrientationDidChangeNotification
											   object:nil];
	
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:EKEventStoreChangedNotification
												  object:nil];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIDeviceOrientationDidChangeNotification
												  object:nil];
	
	[super viewWillDisappear:animated];
}

- (void)reload
{
	NSArray * allCalendars = nil;
	if ([eventStore respondsToSelector:@selector(calendarsForEntityType:)])
		allCalendars = [eventStore calendarsForEntityType:EKEntityTypeEvent];
	else
		allCalendars = [eventStore calendars];
	
	NSInteger count = allCalendars.count;
	
	/* Order calendars depending of the number of events */
	NSArray * sortedCalendars = [allCalendars sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
		NSUInteger count1 = [eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj1 includingRecurrent:NO];
		NSUInteger count2 = [eventStore numberOfFutureEventsFromCalendar:(EKCalendar *)obj2 includingRecurrent:NO];
		return -OrderComparisonResult(count1, count2);// Add "minus" to reverser order (descending)
	}];
	
	if (!calendars)
		calendars = [[NSMutableArray alloc] initWithCapacity:count];
	else [calendars removeAllObjects];
	
	if (!calendarsEvents)
		calendarsEvents = [[NSMutableArray alloc] initWithCapacity:count];
	else [calendarsEvents removeAllObjects];
	
	NSMutableArray * allCalendarsEvents = [[NSMutableArray alloc] initWithCapacity:count];
	
	numberOfEvents = 0;
	for (EKCalendar * calendar in sortedCalendars) {
		
		[calendars addObject:calendar];
		
		/* Get all future events from the current calendar */
		NSArray * events = [eventStore futureEventsFromCalendar:calendar includingRecurrent:NO];
		
		[allCalendarsEvents addObjectsFromArray:events];
		
		if (events) {
			[calendarsEvents addObject:events];
			numberOfEvents += events.count;
		}
	}
	
	NSArray * selectedEventsCopy = [selectedEvents copy];
	for (EKEvent * event in selectedEventsCopy) {
		if (![allCalendarsEvents containsObject:event]) {
			[selectedEvents removeObject:event];
		}
	}
	
	/* Show "No Future Events" if no future events (for all calendars) */
	if (numberOfEvents == 0) {
		CGRect frame = CGRectMake(0., 0., self.tableView.frame.size.width, self.tableView.frame.size.height);
		UILabel * label = [[UILabel alloc] initWithFrame:frame];
		label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		label.backgroundColor = [UIColor clearColor];
		label.lineBreakMode = UILineBreakModeWordWrap;
		label.numberOfLines = 0;// Infinite number of line
		label.textColor = [UIColor darkGrayColor];
		label.textAlignment = UITextAlignmentCenter;
		label.font = [UIFont boldSystemFontOfSize:18.];
		label.shadowColor = [UIColor colorWithWhite:1. alpha:0.7];
		label.shadowOffset = CGSizeMake(0., 1.);
		
		label.text = NSLocalizedString(@"No Future Events", nil);
		
		self.tableView.tableHeaderView = label;
	} else {
		self.tableView.tableHeaderView = nil;
	}
	
	[self updateUI];
	[tableView reloadData];
}

- (void)updateUI
{
	self.navigationItem.rightBarButtonItem.enabled = (selectedEvents.count > 0);
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
		EKEvent * event = [selectedEvents objectAtIndex:index];// Get the first event that is not imported (event at index "index")
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
			[self dismissModalViewControllerAnimated:YES];
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
		[self dismissModalViewControllerAnimated:YES];
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (numberOfEvents > 0)
		return calendars.count;
	return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (numberOfEvents > 0) {
		NSInteger count = ((NSArray *)[calendarsEvents objectAtIndex:section]).count;
		if (count == 0) {
			count++;// Add one row if no events for this section to show "No Events"
		}
		return count + 1;// Add one row per section for the section title (custom cell)
	} else {
		return 0;
	}
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	if (indexPath.row == 0) {// Section cells
		
		static NSString * sectionCellIdentifier = @"SectionCellID";
		
		cell = (SectionCalendarTableViewCell *)[tableView dequeueReusableCellWithIdentifier:sectionCellIdentifier];
		
		if (cell == nil) {
			cell = [[SectionCalendarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:sectionCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		EKCalendar * calendar = [calendars objectAtIndex:indexPath.section];
		cell.textLabel.text = calendar.title;
		cell.textLabel.font = [UIFont boldSystemFontOfSize:14.];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.shadowColor = [UIColor colorWithWhite:0. alpha:0.5];
		cell.textLabel.shadowOffset = CGSizeMake(0., -1.);
		
		/* Show a present icon when this is the brithday calendar */
		if (calendar.type == EKCalendarTypeBirthday) {
			cell.imageView.image = [UIImage imageNamed:@"birthdays"];
			cell.textLabel.text = NSLocalizedString(@"Birthdays", nil);
		} else {
			cell.imageView.image = nil;
		}
		
		[cell setNeedsDisplay];// Force the -drawRect: method to re-fix the position of imageView and textLabel views and fix all the section layout
		
		if (calendar.CGColor) {
			((SectionCalendarTableViewCell *)cell).CGColor = calendar.CGColor;
		} else {
			((SectionCalendarTableViewCell *)cell).CGColor = [UIColor redColor].CGColor;// Set the color of the section with red by default
		}
		
	} else {// Event cells
		
		NSArray * events = [calendarsEvents objectAtIndex:indexPath.section];
		
		if (events.count == 0) {
			
			static NSString * noResultsIdentifier = @"NoResultsIdentifier";
			
			cell = [tableView dequeueReusableCellWithIdentifier:noResultsIdentifier];
			
			if (cell == nil) {
				cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:noResultsIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleNone;
				cell.textLabel.textAlignment = UITextAlignmentCenter;
			}
			
			cell.textLabel.text = NSLocalizedString(@"No Future Events", nil);
			cell.textLabel.textColor = [UIColor grayColor];
			
		} else {
			
			static NSString * cellIdentifier = @"CellID";
			
			cell = (CheckTableViewCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
			
			if (cell == nil) {
				cell = [[CheckTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
				cell.selectionStyle = UITableViewCellSelectionStyleGray;
			}
			
			EKEvent * event = [events objectAtIndex:(indexPath.row - 1)];// Offset the row by one to count the section adding on tableView:numberOfRowsInSection:
			cell.textLabel.text = event.title;
			cell.detailTextLabel.text = [event.startDate description];
			
			cell.accessoryType = UITableViewCellAccessoryNone;
			if ([selectedEvents containsObject:event]) {
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			[cell.accessoryView setNeedsDisplay];
		}
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row == 0)
		return 22.;// 22 px height for section cells
	
	return 44.;// 44 px height for other cells
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.row > 0) {// Don't select first rows, there are section cells
		
		NSArray * events = [calendarsEvents objectAtIndex:indexPath.section];
		
		/* Check events count to know if we are in regular event cell or a "No Future Event" cell (in this case, don't do anything) */
		if (events.count > 0) {// Regular event cell
			
			EKEvent * event = [events objectAtIndex:(indexPath.row - 1)];
			
			UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
			if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
				
				[selectedEvents removeObject:event];
				cell.accessoryType = UITableViewCellAccessoryNone;
				
			} else {
				
				if (![selectedEvents containsObject:event]) {// Just check, ther is probably no way to get duplicates, but in the case of...
					[selectedEvents addObject:event];
				}
				cell.accessoryType = UITableViewCellAccessoryCheckmark;
			}
			
			[self updateUI];
			
		} else {// "No Future Events" cell
			// Do nothing
		}
		
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientationIsPortrait(interfaceOrientation) || UIInterfaceOrientationIsLandscape(interfaceOrientation));
}

- (void)deviceOrientationDidChange:(NSNotification *)aNotification
{
	[tableView reloadData];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	self.tableView = nil;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


@end
