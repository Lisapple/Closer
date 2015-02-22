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
@property (strong, nonatomic) NSArray * countdowns;
@property (strong, nonatomic) NSTimer * timer;

@end

@implementation TodayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults * widgetDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.closer"];
    _countdowns = [widgetDefaults arrayForKey:@"countdowns"];
  
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.rowHeight = 37.;
    _tableView.separatorInset = UIEdgeInsetsZero;
    
    self.preferredContentSize = CGSizeMake(_tableView.contentSize.width,
                                           _tableView.rowHeight * _countdowns.count);
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.
                                              target:_tableView
                                            selector:@selector(reloadData)
                                            userInfo:nil
                                             repeats:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_timer invalidate];
    _timer = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler
{
    NSUserDefaults * widgetDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.lisacintosh.closer"];
    _countdowns = [widgetDefaults arrayForKey:@"countdowns"];
    [_tableView reloadData];
    
    completionHandler(NCUpdateResultNewData);
}

#pragma mark - TableView Datasource

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
        cell.duration = [countdown[@"durations"][index] integerValue];
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

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString * identifier = _countdowns[indexPath.row][@"identifier"];
    NSURL * appURL = [NSURL URLWithString:[NSString stringWithFormat:@"closer://countdown#%@", identifier]];
    [self.extensionContext openURL:appURL completionHandler:NULL];
}

@end
