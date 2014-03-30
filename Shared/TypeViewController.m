//
//  TypeViewController.m
//  Closer
//
//  Created by Maxime Leroy on 6/17/13.
//
//

#import "TypeViewController.h"

#import "CheckTableViewCell.h"

#import "UIColor+addition.h"
#import "UITableView+addition.h"

@interface TypeViewController ()

@end

@implementation TypeViewController

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
	self.title = NSLocalizedString(@"Type", nil);
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	_tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.alwaysBounceVertical = YES;
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView = backgroundView;
	
	_tableView.footerText = NSLocalizedString(@"Countdowns allow you to watch the duration until a precise date, timers are used to measure small periods.", nil);
	
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
	/* Two for "Countdown" and "Timer" */
	return 2;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	CheckTableViewCell * cell = (CheckTableViewCell *)[_tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[CheckTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	switch (indexPath.row) {
		case 1:
			cell.textLabel.text = NSLocalizedString(@"Timer", nil);
			break;
		default:
			cell.textLabel.text = NSLocalizedString(@"Countdown", nil);
			break;
	}
	
	cell.accessoryType = (_countdown.type == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	
	return cell;
}

#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	_countdown.type = indexPath.row;
	
	if (indexPath.row == 0) {
		[_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:1 inSection:0]]
						  withRowAnimation:UITableViewRowAnimationNone];
	} else {
		[_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]]
						  withRowAnimation:UITableViewRowAnimationNone];
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
