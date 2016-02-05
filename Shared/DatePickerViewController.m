//
//  DatePickerViewController.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "DatePickerViewController.h"

#import "Countdown.h"

#import "NSDate+addition.h"
#import "NSObject+additions.h"

@interface DatePickerViewController ()
{
	NSUndoManager * _undoManager;
}

@property (nonatomic, assign) BOOL hasTimeDate;
@property (nonatomic, strong) NSTimer * updateDatePickerTimer;

- (void)updatePickerMinimalDate;
- (void)updateWithOrientation:(UIInterfaceOrientation)orientation;

@end

@implementation DatePickerViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Date & Time", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[_tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]
							animated:NO scrollPosition:UITableViewScrollPositionNone];
	_tableView.alwaysBounceVertical = NO;
	_tableView.scrollEnabled = NO;
	
	[self reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	NSDate * endDate = _countdown.endDate;
	_hasTimeDate = (endDate != nil && (endDate.timeIntervalSinceNow > 0)); // If endDate is nil or passed, we don't have a valid date and consider time as invalid
	
	if (!endDate || (endDate.timeIntervalSinceNow <= 0)) {
		NSDate * now = [NSDate date];
		NSCalendar * calendar = [NSCalendar currentCalendar];
		NSDateComponents * comps = [calendar components:NSCalendarUnitMinute fromDate:now];
		comps.minute = 60 - comps.minute;
		self.date = [calendar dateByAddingComponents:comps toDate:now options:0]; // date = today, next hour
	} else
		self.date = endDate;
	
	[_datePicker setDate:_date animated:NO];
	_datePicker.minimumDate = [[NSDate date] dateByAddingTimeInterval:60]; // minimumDate = now + 1 minute
	_datePicker.maximumDate = [[NSDate date] dateByAddingTimeInterval:(100. * 365. * 24. * 60. * 60.)]; // maximumDate = now + 100 years
	
	[self reloadData];
	
	_undoManager = [[NSUndoManager alloc] init];
	
	[self updateWithOrientation:[UIApplication sharedApplication].statusBarOrientation];
	
	// Compute the next time change (one minute - the actual number of second)
	NSCalendar * calendar = [NSCalendar currentCalendar];
	NSDateComponents * components = [calendar components:NSCalendarUnitSecond fromDate:[NSDate date]];
	double delayInSeconds = 60. - components.second;
	
	// Start -[DatePickerViewController updatePickerMinimalDate] to set minimum date at the next time change and call it every minutes
	[NSObject performBlock:^{
		_updateDatePickerTimer = [NSTimer scheduledTimerWithTimeInterval:60. // Every minutes
																  target:self selector:@selector(updatePickerMinimalDate)
																userInfo:nil repeats:YES];
	}
				afterDelay:delayInSeconds];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if (_hasTimeDate) {
		NSTimeInterval timeIntervalSince1970 = _date.timeIntervalSince1970;
		NSTimeInterval seconds = (timeIntervalSince1970 - ((int)(timeIntervalSince1970 / 60) * 60.));
		self.countdown.endDate = [_date dateByAddingTimeInterval:-seconds];// Fix seconds from date to zero to finish countdown at hh:mm:00 (and not hh:mm:ss)
	}
	
	_undoManager = nil;
	
	if (_updateDatePickerTimer.valid) {
		[_updateDatePickerTimer invalidate];
		_updateDatePickerTimer = nil;
	}
}

- (void)setDatePickerDate:(NSDate *)aDate
{
	_datePicker.date = aDate;
	self.date = aDate;
	
	[self reloadData];
}

- (IBAction)datePickerDidChange:(id)sender
{
	[_undoManager registerUndoWithTarget:self selector:@selector(setDatePickerDate:) object:self.date];
	[_undoManager setActionName:NSLocalizedString(@"UNDO_DATE_ACTION", nil)];
	
	self.date = _datePicker.date;
	[self reloadData];
}

- (void)updatePickerMinimalDate
{
	_datePicker.minimumDate = [[NSDate date] dateByAddingTimeInterval:60];// minimumDate = now + 1 minute
	[self reloadData];// Force reload data to prevent change from datePicker
}

- (void)reloadData
{
	/* Reload tableView and retain the current selection */
	NSIndexPath * selectedCellIndexPath = _tableView.indexPathForSelectedRow;
	[_tableView reloadData];
	[_tableView selectRowAtIndexPath:selectedCellIndexPath animated:NO scrollPosition:UITableViewScrollPositionTop];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	return (UIInterfaceOrientationIsPortrait(orientation)) ? @" " : @"";
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
	UITableViewCell * cell = [_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
	}
	
	cell.textLabel.textColor = (cell.isHighlighted) ? [UIColor whiteColor] : [UIColor blackColor];
	
	if (indexPath.row == 0)
		cell.textLabel.text = [_date naturalDateString];
	else {
		if (_hasTimeDate)
			cell.textLabel.text = [_date naturalTimeString];
		else {
			cell.textLabel.text = @"-:--";
			cell.textLabel.textColor = [UIColor colorWithRed:0.8 green:0.2 blue:0.2 alpha:1.];
		}
	}
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	_datePicker.date = _date;
	
	if (indexPath.row == 0) // Days
		_datePicker.datePickerMode = UIDatePickerModeDate;
	else {// Time
		_datePicker.datePickerMode = UIDatePickerModeTime;
		
		if (!_hasTimeDate) {
			[self datePickerDidChange:nil];// Force datePickerDidChange: call when datePicker set minimum date automatly (when date is earlier than datePicker minium date per example)
			_hasTimeDate = YES;
		}
	}
	
	[self reloadData];
}

// Use frame of containing view to work out the correct origin and size
// of the UIDatePicker. (=> http://niftybean.com/main/blog/21-rotating-uipickerview-between-landscape-and-portrait-orientations )
// And subclass of the UIDatePicker form http://www.llamagraphics.com/developer/using-uidatepicker-landscape-mode
- (void)updateWithOrientation:(UIInterfaceOrientation)orientation
{
	CGFloat newPickerHeight = UIInterfaceOrientationIsLandscape(orientation)? 162. : 216;
	_datePicker.frame = CGRectMake(0., self.view.frame.size.height - newPickerHeight, self.view.frame.size.width, newPickerHeight);
	_tableView.frame = CGRectMake(0., 0, self.view.frame.size.width, self.view.frame.size.height - newPickerHeight);
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation duration:(NSTimeInterval)duration
{
	[self updateWithOrientation:orientation];
	[self reloadData];
	
	[super willAnimateRotationToInterfaceOrientation:orientation duration:duration];
}

@end
