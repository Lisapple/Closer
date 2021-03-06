//
//  PageThemeViewController.m
//  Closer
//
//  Created by Max on 11/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "PageThemeViewController.h"

@interface PageThemeViewController ()

@property (nonatomic, strong) UITableViewCell * checkedCell;

@end

@implementation PageThemeViewController

+ (UIImage *)imageForStyle:(CountdownStyle)style
{
	const CGFloat width = (style == CountdownStyleDay) ? 21. : 20.;
	CGRect frame = CGRectMake(0., 0., width, width);
	UIView * backgroundView = [[UIView alloc] initWithFrame:frame];
	backgroundView.backgroundColor = [UIColor backgroundColorForStyle:style];
	backgroundView.layer.cornerRadius = (width / 2.);
	if (style == CountdownStyleDay) {
		backgroundView.layer.borderWidth = 1.;
		backgroundView.layer.borderColor = [UIColor lightGrayColor].CGColor;
	}
	
	frame = CGRectMake((width / 4.), (width / 4.), (width / 2.), (width / 2.));
	UIView * textView = [[UIView alloc] initWithFrame:frame];
	textView.backgroundColor = [UIColor textColorForStyle:style];
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
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Theme", nil);
}

#pragma mark - Table view data source

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
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	
	if (_countdown.style == indexPath.row) {// Default style == 0
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
		_checkedCell = cell;
	}
	
	cell.textLabel.text = CountdownStyleDescription(indexPath.row);
	cell.imageView.image = [self.class imageForStyle:indexPath.row];
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
	
	if (cell != _checkedCell) {
		_checkedCell.accessoryType = UITableViewCellAccessoryNone;
		
		_checkedCell = cell;
		_checkedCell.accessoryType = UITableViewCellAccessoryCheckmark;
		_countdown.style = indexPath.row;
	}
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
