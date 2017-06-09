//
//  DurationPickerViewController.m
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import "DurationPickerViewController.h"

#import "DurationPickerTableViewCell.h"


@interface DurationPickerViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSArray <NSString *> * cellsTitle;
@property (nonatomic, strong) NSMutableArray <DurationPickerView *> * durationPickers;
@property (nonatomic, strong) UITextField * cellTextField;

@end

@implementation DurationPickerViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Duration", nil);
	
	self.tableView.alwaysBounceVertical = YES;
	
	_cellTextField = [[UITextField alloc] init];
	_cellTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
	_cellTextField.delegate = self;
	_cellTextField.placeholder = NSLocalizedString(@"Name", nil);
	_cellTextField.returnKeyType = UIReturnKeyDone;
	if (_durationIndex < _countdown.names.count)
		_cellTextField.text = _countdown.names[_durationIndex];
	
	_cellsTitle = @[NSLocalizedString(@"Days", nil), NSLocalizedString(@"Hours", nil), NSLocalizedString(@"Minutes", nil), NSLocalizedString(@"Seconds", nil)];
	_durationPickers = [[NSMutableArray alloc] initWithCapacity:4];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillShowNotification
													  object:nil queue:nil
												  usingBlock:^(NSNotification * note)
	 {
		 CGRect keyboardFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
		 self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, keyboardFrame.size.height, 0);
		 self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
	 }];
	[[NSNotificationCenter defaultCenter] addObserverForName:UIKeyboardWillHideNotification
													  object:nil queue:nil
												  usingBlock:^(NSNotification * note)
	 {
		 self.tableView.contentInset = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, 0, 0);
		 self.tableView.scrollIndicatorInsets = self.tableView.contentInset; }];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	NSArray * durationsCopy = _countdown.durations.copy;
	for (NSNumber * duration in durationsCopy) {
		if (duration.integerValue == 0) { // Remove empty durations
			NSInteger index = [_countdown.durations indexOfObject:duration];
			if (index != NSNotFound)
				[_countdown removeDurationAtIndex:index];// @FIXME: This may crashes "*** -[__NSArrayM removeObjectAtIndex:]: index 0 beyond bounds for empty array"
		}
	}
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1 /* name field */ + _cellsTitle.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) { // Name field
		static NSString * nameCellIdentifier = @"NameCellID";
		
		UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:nameCellIdentifier];
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nameCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			[cell.contentView addSubview:_cellTextField];
			_cellTextField.translatesAutoresizingMaskIntoConstraints = NO;
			
			NSMutableArray * constraints = [[NSMutableArray alloc] initWithCapacity:4];
			NSDictionary * views = @{ @"textField" : _cellTextField };
			[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-[textField]-|"
																					 options:NSLayoutFormatAlignAllCenterX
																					 metrics:nil views:views]];
			[constraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[textField]-|"
																					 options:NSLayoutFormatAlignAllCenterY
																					 metrics:nil views:views]];
			[cell.contentView addConstraints:constraints];
		}
		return cell;
		
	} else { // Duration picker
		NSUInteger newSection = indexPath.section - 1;
		static NSString * cellIdentifier = @"DurationCellID";
		DurationPickerTableViewCell * cell = (DurationPickerTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		if (!cell) {
			cell = [[DurationPickerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			DurationPickerView * pickerView = cell.pickerView;
			pickerView.delegate = self;
			pickerView.dataSource = self;
			
			if ([_durationPickers containsObject:pickerView])
				_durationPickers[newSection] = pickerView;
			else
				[_durationPickers addObject:pickerView];
			
			[pickerView reloadData];
			
			long seconds = self.countdown.durations[_durationIndex].longValue;
			long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
			long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
			long minutes = seconds / 60; seconds -= minutes * 60;
			pickerView.selectedIndex = ((long []) {days, hours, minutes, seconds})[newSection];
		}
		cell.label.text = _cellsTitle[newSection];
		return cell;
	}
	return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section == 0) ? 44. : 82.;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Text field delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	[self.countdown setDurationName:textField.text atIndex:_durationIndex];
}

#pragma mark - Duration view delegate

- (NSInteger)numberOfNumbersInDurationPickerView:(DurationPickerView *)durationPickerView
{
	NSInteger section = [_durationPickers indexOfObject:durationPickerView];
	switch (section) {
		case 0: return 7;
		case 1: return 24;
		default: break;
	}
	return 60;
}

- (NSInteger)durationPickerView:(DurationPickerView *)durationPickerView numberForIndex:(NSInteger)index
{
	return index;
}

- (void)durationPickerView:(DurationPickerView *)durationPickerView didSelectIndex:(NSInteger)index
{
	NSDebugLog(@"Set value: %ld at index: %ld", (long)index, (long)[_durationPickers indexOfObject:durationPickerView]);
	
	long duration = 0;
	int pickerIndex = 0;
	for (DurationPickerView * pickerView in _durationPickers) {
		switch (pickerIndex) {
			case 0: duration += pickerView.selectedIndex * 24 * 60 * 60; break;
			case 1: duration += pickerView.selectedIndex * 60 * 60; break;
			case 2: duration += pickerView.selectedIndex * 60; break;
			case 3: duration += pickerView.selectedIndex; break;
			default: break;
		}
		pickerIndex++;
	}
	
	[self.countdown setDuration:@(duration) atIndex:_durationIndex];
	
	/* Stop the timer if we modify the current index used for the timer */
	if (_durationIndex == self.countdown.durationIndex)
		self.countdown.endDate = nil;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
