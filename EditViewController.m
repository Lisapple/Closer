//
//  EditViewController.m
//  Closer
//
//  Created by Maxime on 8/1/14.
//
//

#import "EditViewController.h"

@interface EditViewController ()

@end

@implementation EditViewController

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	UIBarButtonItem * doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																					 target:self
																					 action:@selector(done:)];
	if (!TARGET_IS_IOS7_OR_LATER())
		doneButtonItem.tintColor = [UIColor doneButtonColor];
	
	self.navigationItem.rightBarButtonItem = doneButtonItem;
	
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    if (!TARGET_IS_IOS7_OR_LATER()) {
		self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
		self.tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        
        UIView * backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        self.tableView.backgroundView = backgroundView;
    }
    
	self.tableView.allowsSelectionDuringEditing = YES;
	self.tableView.editing = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(reloadData)
												 name:CountdownDidSynchronizeNotification
											   object:nil];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:CountdownDidSynchronizeNotification
												  object:nil];
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
	[self.undoManager setActionName:NSLocalizedString(@"UNDO_DELETE_COUNTDOWN_ACTION", nil)];
	
	[Countdown removeCountdown:countdown];
	/* Note: the tableView is automatically reloaded */
	// @TODO: animated the row insertion
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [Countdown allCountdowns].count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = nil;
	
	if (indexPath.section == 0) {
		static NSString * countdownCellIdentifier = @"countdownCellIdentifier";
		cell = [self.tableView dequeueReusableCellWithIdentifier:countdownCellIdentifier];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:countdownCellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		
		Countdown * countdown = [Countdown allCountdowns][indexPath.row];
		cell.textLabel.text = countdown.name;
		
		if (countdown.type == CountdownTypeTimer) {
			if (countdown.durations.count >= 2) {
				cell.detailTextLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%ld timers", nil), (long)countdown.durations.count]; // @TODO: replace "%ld timers" with "%ld durations"
			} else if (countdown.durations.count == 1) {
				cell.detailTextLabel.text = [countdown descriptionOfDurationAtIndex:0];
			} else {
				cell.detailTextLabel.text = NSLocalizedString(@"No timers", nil); // @TODO: replace "No timers" with "No durations"
			}
		} else {
			cell.detailTextLabel.text = [countdown.endDate description];
		}
	}
	
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
		
		NSInteger index = indexPath.row;
		[self removeCountdown:[Countdown countdownAtIndex:index]
						index:index];
		// @TODO: animated the row deletion
	}
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return (indexPath.section == 0);
}

- (void)tableView:(UITableView *)aTableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	[Countdown moveCountdownAtIndex:sourceIndexPath.row toIndex:destinationIndexPath.row];
	//[self reloadData];
	// @TODO: animated the row movement
}

@end
