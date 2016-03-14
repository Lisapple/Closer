//
//  AboutViewController.m
//  Closer
//
//  Created by Max on 03/03/16.
//
//

#import "AboutViewController.h"
#import <SafariServices/SafariServices.h>
#import <Crashlytics/Crashlytics.h>

#import "NSDate+addition.h"

@implementation AboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"About", nil);
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																						  target:self action:@selector(doneAction:)];
}

- (void)doneAction:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	if (section == 0) {
		NSDictionary * infoDictionary = [NSBundle mainBundle].infoDictionary;
		return [NSString stringWithFormat:NSLocalizedString(@"Closer & Closer %@\nCopyright © %lu, Lis@cintosh", nil),
				infoDictionary[@"CFBundleShortVersionString"], [NSDate date].year];
	}
	else if (section == tableView.numberOfSections - 1) {
		return NSLocalizedString(@"Closer & Closer is an open-source projet, under MIT license.", nil);
	}
	return nil;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
	NSString * title = [tableView cellForRowAtIndexPath:indexPath].textLabel.text;
	NSURL * url = [NSURL URLWithString:[@"http://" stringByAppendingString:title]];
	if (!url)
		return ;
	
	if (NSClassFromString(@"SFSafariViewController")) {
		SFSafariViewController * viewController = [[SFSafariViewController alloc] initWithURL:url];
		[self presentViewController:viewController animated:YES completion:nil];
	} else {
		[[UIApplication sharedApplication] openURL:url];
	}
	
	[Answers logCustomEventWithName:@"open-about-url"
				   customAttributes:@{ @"url" : url }];
}

@end
