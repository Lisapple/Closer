//
//  TodayViewController.m
//  CloserWidget
//
//  Created by Max on 31/01/15.
//
//

#import "TodayViewController.h"
#import "TimerTableViewCell.h"
#import "CountdownTableViewCell.h"

@interface TodayViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSArray <NSDictionary *> * countdowns;
@property (strong, nonatomic) NSTimer * timer;

@end

@implementation TodayViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.rowHeight = 37.;
	_tableView.separatorInset = UIEdgeInsetsZero;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	_timer = [NSTimer scheduledTimerWithTimeInterval:1.
											  target:_tableView selector:@selector(reloadData)
											userInfo:nil repeats:YES];
	
	NSUserDefaults * widgetDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.closer"];
	_countdowns = [widgetDefaults arrayForKey:@"countdowns"];
	_tableView.estimatedRowHeight = 44.;
	_tableView.rowHeight = UITableViewAutomaticDimension;
	[_tableView reloadData];
	
	if ([self.extensionContext respondsToSelector:@selector(widgetLargestAvailableDisplayMode)]) { // iOS 10+
		NCWidgetDisplayMode mode = (_countdowns.count > 2) ? NCWidgetDisplayModeExpanded : NCWidgetDisplayModeCompact;
		self.extensionContext.widgetLargestAvailableDisplayMode = mode;
	} else {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			self.preferredContentSize = CGSizeMake(_tableView.contentSize.width, _tableView.contentSize.height);
		});
	}
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	[_timer invalidate];
	_timer = nil;
}

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize
{
	self.preferredContentSize = CGSizeMake(_tableView.contentSize.width,
										   MIN(maxSize.height, _tableView.contentSize.height + 8.));
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
	NSUserDefaults * widgetDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.closer"];
	NSArray * countdowns = [widgetDefaults arrayForKey:@"countdowns"];
	NCUpdateResult result = (countdowns.count > 0) ? NCUpdateResultNewData : NCUpdateResultNoData;
	completionHandler(result);
}

#pragma mark - TableView data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _countdowns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSDictionary * countdown = _countdowns[indexPath.row];
	if ([countdown[@"type"] integerValue] == 1) { // Timer
		TimerTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"TimerCellID" forIndexPath:indexPath];
		cell.name = countdown[@"name"];
		NSInteger index = [countdown[@"durationIndex"] integerValue];
		NSArray * durations = countdown[@"durations"];
		cell.duration = (durations.count > index) ? [countdown[@"durations"][index] integerValue] : 0;
		cell.remaining = [countdown[@"endDate"] timeIntervalSinceNow];
		return cell;
	}
	else { // Countdown
		CountdownTableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:@"CountdownCellID" forIndexPath:indexPath];
		cell.name = countdown[@"name"];
		cell.endDate = countdown[@"endDate"];
		return cell;
	}
}

#pragma mark - TableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString * identifier = _countdowns[indexPath.row][@"identifier"];
	NSURL * appURL = [NSURL URLWithString:[NSString stringWithFormat:@"closer://countdown/%@", identifier]];
	[self.extensionContext openURL:appURL completionHandler:NULL];
}

@end
