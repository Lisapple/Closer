//
//  DurationPickerViewController.m
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import "DurationPickerViewController.h"

#import "DurationPickerTableViewCell.h"

#import "UIColor+addition.h"

@interface DurationPickerViewController ()

@end

@implementation DurationPickerViewController
@synthesize tableView = _tableView;
@synthesize countdown = _countdown;
@synthesize durationIndex = _durationIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Duration", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	_tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.alwaysBounceVertical = YES;
	
	_tableView.rowHeight = 82.;
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView = backgroundView;
	
	cellsTitle = @[NSLocalizedString(@"Days", nil), NSLocalizedString(@"Hours", nil), NSLocalizedString(@"Minutes", nil), NSLocalizedString(@"Seconds", nil)];
	durationPickers = [[NSMutableArray alloc] initWithCapacity:4];
	
    [super viewDidLoad];
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
		[pickerView reloadData];
		
		long seconds = [self.countdown.durations[_durationIndex] longValue];
		long days = seconds / (24 * 60 * 60); seconds -= days * (24 * 60 * 60);
		long hours = seconds / (60 * 60); seconds -= hours * (60 * 60);
		long minutes = seconds / 60; seconds -= minutes * 60;
		pickerView.selectedIndex = (indexPath.section == 0) ? days : ((indexPath.section == 1) ? hours : ((indexPath.section == 2) ? minutes : seconds));
		
		if ([durationPickers containsObject:pickerView])
			[durationPickers replaceObjectAtIndex:indexPath.section withObject:pickerView];
		else
			[durationPickers addObject:pickerView];
	}
	
	cell.label.text = cellsTitle[indexPath.section];
	
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
	NSInteger section = [durationPickers indexOfObject:durationPickers];
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
	NSDebugLog(@"Set value: %d at index: %d", index, [durationPickers indexOfObject:durationPickerView]);
	
	long duration = 0;
	int pickerIndex = 0;
	for (DurationPickerView * pickerView in durationPickers) {
		if (pickerIndex == 0) duration += pickerView.selectedIndex * 24. * 60 * 60;
		else if (pickerIndex == 1) duration += pickerView.selectedIndex * 60 * 60;
		else if (pickerIndex == 2) duration += pickerView.selectedIndex * 60;
		else if (pickerIndex == 3) duration += pickerView.selectedIndex;
		pickerIndex++;
	}
	
	[self.countdown setDuration:[NSNumber numberWithLong:duration]
						atIndex:_durationIndex];
	
	/* Stop the timer if we modify the current index used for the timer */
	if (_durationIndex == self.countdown.durationIndex)
		self.countdown.endDate = nil;
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
