//
//  PromptViewController.m
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import "PromptViewController.h"

#import "CheckTableViewCell.h"

#import "UIColor+addition.h"
#import "UITableView+addition.h"

@interface PromptViewController ()

@end

@implementation PromptViewController

@synthesize tableView = _tableView;
@synthesize countdown = _countdown;

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
	self.title = NSLocalizedString(@"Ask to Continue", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	_tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.alwaysBounceVertical = YES;
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView = backgroundView;
	
	_tableView.footerText = NSLocalizedString(@"An alert can be shown to ask you to continue the timer.", nil);
	
	cellsTitle = [[NSArray alloc] initWithObjects:NSLocalizedString(@"Never", nil), NSLocalizedString(@"At the end of each timer", nil), NSLocalizedString(@"When all timers are finished", nil), nil];
	
    [super viewDidLoad];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	/* Three for "Never", "At the end of each timer" and "When all timers are finished" */
	return cellsTitle.count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	CheckTableViewCell * cell = (CheckTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[CheckTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	cell.textLabel.text = cellsTitle[indexPath.row];
	
	switch (indexPath.row) {
		case 0:
			cell.accessoryType = (_countdown.promptState == PromptStateNone) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			break;
		case 1:
			cell.accessoryType = (_countdown.promptState == PromptStateEveryTimers) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			break;
		default:
			cell.accessoryType = (_countdown.promptState == PromptStateEnd) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
			break;
	}
	
	return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	_countdown.promptState = indexPath.row;
	
	for (NSInteger row = 0; row < cellsTitle.count; row++) {
		if (row != indexPath.row) {
			[_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:row inSection:0]]
							  withRowAnimation:UITableViewRowAnimationNone];
		}
	}
	
	CheckTableViewCell * cell = (CheckTableViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
	cell.accessoryType = UITableViewCellAccessoryCheckmark;
	
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
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
