//
//  EditViewController.m
//  Closer
//
//  Created by Maxime on 8/1/14.
//
//

#import "EditViewController.h"
#import "NSDate+addition.h"

@interface EditViewController ()

@property (nonatomic, strong) NSArray <Countdown *> * allCountdowns;
@property (nonatomic, strong) NSMutableArray <Countdown *> * includedCountdowns, * notIncludedCountdowns;

@end

@implementation EditViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.tableView.allowsSelectionDuringEditing = YES;
	self.tableView.editing = YES;
	[self reloadData];
}

- (void)reloadData
{
	_allCountdowns = [Countdown allCountdowns].copy;
	_includedCountdowns = [_allCountdowns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"notificationCenter == YES"]].mutableCopy;
	[_includedCountdowns sortUsingComparator:^NSComparisonResult(Countdown * countdown1, Countdown * countdown2) {
		return OrderComparisonResult([_allCountdowns indexOfObject:countdown1], [_allCountdowns indexOfObject:countdown2]); }];
	
	_notIncludedCountdowns = [_allCountdowns filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"notificationCenter == NO"]].mutableCopy;
	[_notIncludedCountdowns sortUsingComparator:^NSComparisonResult(Countdown * countdown1, Countdown * countdown2) {
		return OrderComparisonResult([_allCountdowns indexOfObject:countdown1], [_allCountdowns indexOfObject:countdown2]); }];
	
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData)
												 name:CountdownDidSynchronizeNotification object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CountdownDidSynchronizeNotification object:nil];
}

- (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index
{
	[[self.undoManager prepareWithInvocationTarget:self] removeCountdown:countdown index:index];
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_DELETE_COUNTDOWN_ACTION", nil)];
	
	[Countdown insertCountdown:countdown atIndex:index];
	/* Note: the tableView is automatically reloaded */
	// @TODO: animated the row insertion
}

- (void)removeCountdown:(Countdown *)countdown index:(NSInteger)index
{
	[[self.undoManager prepareWithInvocationTarget:self] insertCountdown:countdown atIndex:index];
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_INSERT_COUNTDOWN_ACTION", nil)];
	
	[Countdown removeCountdown:countdown];
	/* Note: the tableView is automatically reloaded */
	// @TODO: animated the row insertion
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2; // "Include in notification center" and "Do not include"
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if /**/ (section == 0)
		return NSLocalizedString(@"Include in notification center", nil);
	else if (section == 1)
		return NSLocalizedString(@"Do not include", nil);
	
	return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if /**/ (section == 0)
		return self.includedCountdowns.count;
	else if (section == 1)
		return self.notIncludedCountdowns.count;
	
	return 0;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * countdownCellIdentifier = @"countdownCellIdentifier";
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:countdownCellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:countdownCellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
	cell.textLabel.text = countdown.name;
	
	if (countdown.type == CountdownTypeTimer) {
		if (countdown.durations.count >= 2)
			cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld durations", nil), (long)countdown.durations.count];
		else if (countdown.durations.count == 1)
			cell.detailTextLabel.text = [countdown descriptionOfDurationAtIndex:0];
		else
			cell.detailTextLabel.text = NSLocalizedString(@"No durations", nil);
	} else
		cell.detailTextLabel.text = countdown.endDate.localizedDescription;
	
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)aTableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		Countdown * countdown = (indexPath.section == 0) ? _includedCountdowns[indexPath.row] : _notIncludedCountdowns[indexPath.row];
		[self removeCountdown:countdown index:indexPath.row];
		// @TODO: animated the row deletion
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return YES;
}

- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	NSUInteger newIncludedCount = _includedCountdowns.count - (!sourceIndexPath.section && destinationIndexPath.section);
	NSUInteger sourceIndex = sourceIndexPath.section * newIncludedCount + sourceIndexPath.row;
	NSUInteger destinationIndex = destinationIndexPath.section * newIncludedCount + destinationIndexPath.row;
	
	Countdown * countdown = (sourceIndexPath.section == 0) ? _includedCountdowns[sourceIndexPath.row] : _notIncludedCountdowns[sourceIndexPath.row];
	countdown.notificationCenter = (destinationIndexPath.section == 0);
	if (sourceIndex != destinationIndex)
		[Countdown moveCountdownAtIndex:CLIP(0, sourceIndex, _allCountdowns.count - 1)
								toIndex:CLIP(0, destinationIndex, _allCountdowns.count - 1)];
	
	[self reloadData];
	// @TODO: animated the row movement
}

@end
