//
//  DatePickerViewController.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "DatePickerViewController.h"

#import "Countdown.h"
#import "MyDatePicker.h"

#import "NSDate+addition.h"
#import "UIColor+addition.h"

@interface DatePickerViewController (PrivateMethods)

- (void)updatePickerMinimalDate;

- (void)updateWithOrientation:(UIInterfaceOrientation)orientation;

@end

@implementation DatePickerViewController

@synthesize tableView;
@synthesize datePicker;

@synthesize date;
@synthesize countdown;

@synthesize undoManager;

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Date & Time", nil);
	
	/*
	 UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
	 target:self
	 action:@selector(done:)];
	 self.navigationItem.rightBarButtonItem = doneButton;
	 [doneButton release];
	 
	 UIBarButtonItem * cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
	 target:self
	 action:@selector(cancel:)];
	 self.navigationItem.leftBarButtonItem = cancelButton;
	 [cancelButton release];
	 */
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	[tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
						   animated:NO 
					 scrollPosition:UITableViewScrollPositionNone];
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView = backgroundView;
	
	tableView.alwaysBounceVertical = NO;
	tableView.scrollEnabled = NO;
	
	[self reloadData];
	
	[super viewDidLoad];
	
	
	NSDebugLog(@"scheduledLocalNotifications: %i local notification(s)", [[UIApplication sharedApplication] scheduledLocalNotifications].count);
}

- (void)viewWillAppear:(BOOL)animated
{
	NSDate * endDate = countdown.endDate;
	hasTimeDate = (endDate != nil && ([endDate timeIntervalSinceNow] > 0));// If endDate is nil or passed, we don't have a valid date and consider time as invalid
	
	if (!endDate || ([endDate timeIntervalSinceNow] <= 0)) {
		self.date = [[NSDate date] dateByAddingTimeInterval:60];// date = now + 1 minute
	} else {
		self.date = endDate;
	}
	
	[datePicker setDate:date animated:NO];
	datePicker.minimumDate = [[NSDate date] dateByAddingTimeInterval:60];// minimumDate = now + 1 minute
	datePicker.maximumDate = [[NSDate date] dateByAddingTimeInterval:(100. * 365. * 24. * 60. * 60.)];// maximumDate = now + 100 years
	
	/*
	 if (![self.date isEqualToDate:datePicker.date]) {
	 [self datePickerDidChange:nil];// Force datePickerDidChange: call when datePicker set minimum date automatly (when date is earlier than datePicker minium date per example)
	 }
	 */
	
	[self reloadData];
	
	NSUndoManager * anUndomanager = [[NSUndoManager alloc] init];
	self.undoManager = anUndomanager;
	
	
	[self updateWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
	
	/* Compute the next time change (one minute - the actual number of second) */
	NSCalendar * calendar = [NSCalendar currentCalendar];
	NSDateComponents * components = [calendar components:NSSecondCalendarUnit fromDate:[NSDate date]];
	double delayInSeconds = 60. - components.second;
	
	/* Start -[DatePickerViewController updatePickerMinimalDate] to set minimum date at the next time change and call it every minutes */
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		updateDatePickerTimer = [NSTimer scheduledTimerWithTimeInterval:60.// Every minutes
																  target:self
																selector:@selector(updatePickerMinimalDate)
																userInfo:nil
																 repeats:YES];
	});
	
	[super viewWillAppear:animated];
	
	// Layout once here to ensure the current orientation is respected.
	//[self layoutPicker:[UIApplication sharedApplication].statusBarOrientation];
}

- (void)viewWillDisappear:(BOOL)animated
{
	if (hasTimeDate) {
		NSTimeInterval timeIntervalSince1970 = [date timeIntervalSince1970];
		NSTimeInterval seconds = (timeIntervalSince1970 - ((int)(timeIntervalSince1970 / 60) * 60.));
		self.countdown.endDate = [date dateByAddingTimeInterval:-seconds];// Fix seconds from date to zero to finish countdown at hh:mm:00 (and not hh:mm:ss)
	}
	
	self.undoManager = nil;
	
	if ([updateDatePickerTimer isValid]) {
		[updateDatePickerTimer invalidate];
		updateDatePickerTimer = nil;
	}
	
	[super viewWillDisappear:animated];
}

- (void)setDatePickerDate:(NSDate *)aDate
{
	datePicker.date = aDate;
	self.date = aDate;
	
	[self reloadData];
}

- (IBAction)datePickerDidChange:(id)sender
{
	[self.undoManager registerUndoWithTarget:self
									selector:@selector(setDatePickerDate:)
									  object:self.date];
	
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_DATE_ACTION", nil)];
	
	self.date = datePicker.date;
	[self reloadData];
}

- (void)updatePickerMinimalDate
{
	datePicker.minimumDate = [[NSDate date] dateByAddingTimeInterval:60];// minimumDate = now + 1 minute
	[self reloadData];// Force reload data to prevent change from datePicker
}

- (void)reloadData
{
	/* Reload tableView and retain the current selection */
	NSIndexPath * selectedCellIndexPath = [tableView indexPathForSelectedRow];
	[tableView reloadData];
	[tableView selectRowAtIndexPath:selectedCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	if (UIInterfaceOrientationIsPortrait(orientation))
		return @" ";
	else
		return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		cell.textLabel.textAlignment = UITextAlignmentCenter;
	}
	
	if (cell.isHighlighted) {
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.textLabel.shadowColor = [UIColor blackColor];
		cell.textLabel.shadowOffset = CGSizeMake(2., 2.);
	} else
		cell.textLabel.textColor = [UIColor blackColor];
	
	if (indexPath.row == 0)
		cell.textLabel.text = [date naturalDateString];
	else {
		if (hasTimeDate) {
			cell.textLabel.text = [date naturalTimeString];
		} else {
			cell.textLabel.text = @"-:--";
			cell.textLabel.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.];
		}
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	datePicker.date = date;
	
	if (indexPath.row == 0) {// Days
		datePicker.datePickerMode = UIDatePickerModeDate;
	} else {// Time
		datePicker.datePickerMode = UIDatePickerModeTime;
		
		if (!hasTimeDate) {
			[self datePickerDidChange:nil];// Force datePickerDidChange: call when datePicker set minimum date automatly (when date is earlier than datePicker minium date per example)
			hasTimeDate = YES;
		}
	}
	
	[self reloadData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}

// Use frame of containing view to work out the correct origin and size
// of the UIDatePicker. (=> http://niftybean.com/main/blog/21-rotating-uipickerview-between-landscape-and-portrait-orientations )
// And subclass of the UIDatePicker form http://www.llamagraphics.com/developer/using-uidatepicker-landscape-mode
- (void)updateWithOrientation:(UIInterfaceOrientation)orientation
{
	CGFloat newPickerHeight = UIInterfaceOrientationIsLandscape(orientation)? 162. : 216;
	datePicker.frame = CGRectMake(0., self.view.frame.size.height - newPickerHeight, self.view.frame.size.width, newPickerHeight);
	tableView.frame = CGRectMake(0., 0, self.view.frame.size.width, self.view.frame.size.height - newPickerHeight);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
	[self updateWithOrientation:orientation];
	[self reloadData];
	
	[super willAnimateRotationToInterfaceOrientation:orientation duration:duration];
}

- (BOOL)canBecomeFirstResponder
{
	return YES;// Return YES to receive shake to undo gesture
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	self.tableView = nil;
	self.datePicker = nil;
	
	[super viewDidUnload];
}




@end
