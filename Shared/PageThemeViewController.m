//
//  PageThemeViewController.m
//  Closer
//
//  Created by Max on 11/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "PageThemeViewController.h"

#import "Countdown.h"

@implementation PageThemeViewController

@synthesize tableView;
@synthesize countdown;

+ (UIImage *)imageForStyle:(PageViewStyle)style
{
	const CGFloat width = (style == PageViewStyleDay) ? 21. : 20.;
	CGRect frame = CGRectMake(0., 0., width, width);
	UIView * backgroundView = [[UIView alloc] initWithFrame:frame];
	backgroundView.backgroundColor = [UIColor backgroundColorForPageStyle:style];
	backgroundView.layer.cornerRadius = (width / 2.);
	if (style == PageViewStyleDay) {
		backgroundView.layer.borderWidth = 1.;
		backgroundView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	}
	
	frame = CGRectMake((width / 4.), (width / 4.), (width / 2.), (width / 2.));
	UIView * textView = [[UIView alloc] initWithFrame:frame];
	textView.backgroundColor = [UIColor textColorForPageStyle:style];
	textView.layer.cornerRadius = (width / 4.);
	[backgroundView addSubview:textView];
	
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, 0.);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[backgroundView.layer renderInContext:context];
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Theme", nil);
	
	tableView.delegate = self;
	tableView.dataSource = self;
    
	[super viewDidLoad];
}

#pragma mark -
#pragma mark Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [Countdown styles].count;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	if (countdown.style == indexPath.row) {// Default style == 0
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		checkedCell = cell;
	}
	
	cell.textLabel.text = [Countdown styles][indexPath.row];
	cell.imageView.image = [self.class imageForStyle:indexPath.row];
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	
	if (cell != checkedCell) {
		checkedCell.accessoryType = UITableViewCellAccessoryNone;
		
		checkedCell = cell;
		checkedCell.accessoryType = UITableViewCellAccessoryCheckmark;
		
		countdown.style = indexPath.row;
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
