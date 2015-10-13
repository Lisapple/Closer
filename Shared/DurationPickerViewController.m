//
//  DurationPickerViewController.m
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import "DurationPickerViewController.h"

#import "DurationPickerTableViewCell.h"


@interface DurationPickerViewController ()

@property (nonatomic, strong) NSArray <NSString *> * cellsTitle;
@property (nonatomic, strong) NSMutableArray <DurationPickerView *> * durationPickers;

@end

@implementation DurationPickerViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Duration", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.alwaysBounceVertical = YES;
	_tableView.rowHeight = 82.;
	
	_cellsTitle = @[NSLocalizedString(@"Days", nil), NSLocalizedString(@"Hours", nil), NSLocalizedString(@"Minutes", nil), NSLocalizedString(@"Seconds", nil)];
	_durationPickers = [[NSMutableArray alloc] initWithCapacity:4];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	/* Four for "Days", "Hours" "Minutes" and "Seconds" */
	return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"DurationCellID";
	
	DurationPickerTableViewCell * cell = (DurationPickerTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[DurationPickerTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		DurationPickerView * pickerView = cell.pickerView;
		pickerView.delegate = self;
		pickerView.dataSource = self;
		
		if ([_durationPickers containsObject:pickerView])
			_durationPickers[indexPath.section] = pickerView;
		else
			[_durationPickers addObject:pickerView];
		
		[pickerView reloadData];
		
		long seconds = self.countdown.durations[_durationIndex].longValue;
		long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
		long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
		long minutes = seconds / 60; seconds -= minutes * 60;
		pickerView.selectedIndex = (indexPath.section == 0) ? days : ((indexPath.section == 1) ? hours : ((indexPath.section == 2) ? minutes : seconds));
	}
	
	cell.label.text = _cellsTitle[indexPath.section];
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Duration view delegate

- (NSInteger)numberOfNumbersInDurationPickerView:(DurationPickerView *)durationPickerView
{
	NSInteger section = [_durationPickers indexOfObject:durationPickerView];
	if (section == 0)
		return 7;
	else if (section == 1)
		return 24;
	
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
		if (pickerIndex == 0) duration += pickerView.selectedIndex * 24. * 60 * 60;
		else if (pickerIndex == 1) duration += pickerView.selectedIndex * 60 * 60;
		else if (pickerIndex == 2) duration += pickerView.selectedIndex * 60;
		else if (pickerIndex == 3) duration += pickerView.selectedIndex;
		pickerIndex++;
	}
	
	[self.countdown setDuration:@(duration)
						atIndex:_durationIndex];
	
	/* Stop the timer if we modify the current index used for the timer */
	if (_durationIndex == self.countdown.durationIndex)
		self.countdown.endDate = nil;
}

@end
