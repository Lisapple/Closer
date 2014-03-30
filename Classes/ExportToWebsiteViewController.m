//
//  ExportToWebsiteViewController.m
//  Closer
//
//  Created by Max on 07/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ExportToWebsiteViewController.h"

#import "JSONKit.h"

#import "UIColor+addition.h"
#import "NSDate+addition.h"

@interface ExportToWebsiteViewController (PrivateMethods)

- (IBAction)done:(id)sender;
- (IBAction)export:(id)sender;

- (NSURL *)countdownOnCloserWebsiteURL;

@end

@implementation ExportToWebsiteViewController

@synthesize countdowns = _countdowns;

@synthesize password1Label1 = _password1Label1, password1Label2 = _password1Label2, password1Label3 = _password1Label3, password1Label4 = _password1Label4;
@synthesize password2Label1 = _password2Label1, password2Label2 = _password2Label2, password2Label3 = _password2Label3, password2Label4 = _password2Label4;

@synthesize tableView = _tableView;

@synthesize activityIndicator = _activityIndicator;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString * nibName = (TARGET_IS_IPAD())? @"ExportToWebsiteViewController_Pad" : @"ExportToWebsiteViewController_Phone";
	if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) {
		
	}
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Exported to Website", nil);
	self.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				 target:self
																				 action:@selector(done:)];
	if ([doneButton respondsToSelector:@selector(setTintColor:)])
		doneButton.tintColor = [UIColor doneButtonColor];
	
	self.navigationItem.rightBarButtonItem = doneButton;
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	_tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	self.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	_tableView.backgroundView = backgroundView;
	
	[self export:nil];
}

- (IBAction)done:(id)sender
{
	[self dismissModalViewControllerAnimated:YES];
}

- (IBAction)export:(id)sender
{
	NSURL * url = [NSURL URLWithString:@"http://closer.lisacintosh.com/import.php"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	
	NSString * stringJSON = nil;
	if (_countdowns.count > 1) {
		
		/* If many countdowns into "_countdowns", create a dictionary for each countdown, put all dict into an array and create a dict with the array:
		 "group" = {
		 [ {"name" : "countdown 1", [...] } ],
		 [ {"name" : "countdown 2", [...] } ], etc.
		 }
		 */
		
		NSMutableArray * objects = [[NSMutableArray alloc] initWithCapacity:_countdowns.count];
		for (Countdown * countdown in _countdowns) {
			NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
										 countdown.name, @"name",
										 [countdown.endDate SQLDateTime], @"endDate",
										((countdown.message)? countdown.message: @""), @"message",// If we don't have message (= nil), pass a empty string
										 [NSNumber numberWithInteger:countdown.style], @"style",
										 [UIDevice currentDevice].model, @"client", nil];
			[objects addObject:attributes];
		}
		
		NSDictionary * outputDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:objects, @"group", nil];
		
		stringJSON = [outputDictionary JSONString];
		
	} else if (_countdowns.count == 1) {
		/* If just one countdown into "_countdowns", create a dictionary with content of the countdown */
		
		Countdown * countdown = [_countdowns objectAtIndex:0];
		NSDictionary * attributes = [[NSDictionary alloc] initWithObjectsAndKeys:
									 countdown.name, @"name",
									 [countdown.endDate SQLDateTime], @"endDate",
									 countdown.message, @"message",
									 [NSNumber numberWithInteger:countdown.style], @"style",
									 [UIDevice currentDevice].model, @"client", nil];
		
		stringJSON = [attributes JSONString];
		
	} else {
		/* The "_countdowns" should not be empty, but, in this case, quit the method */
		return ;
	}
	
	NSData * data = [[NSString stringWithFormat:@"json_data=%@", stringJSON] dataUsingEncoding:NSUTF8StringEncoding];
	
	[request setHTTPBody:data];
	[request setHTTPMethod:@"POST"];
	
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection start];
	
	[_activityIndicator startAnimating];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error!", nil)
														 message:error.localizedDescription
														delegate:nil
											   cancelButtonTitle:NSLocalizedString(@"OK", nil)
											   otherButtonTitles:nil];
	[alertView show];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_activityIndicator stopAnimating];
	
	NSDictionary * dictionary = [data objectFromJSONData];
	
	password1 = [dictionary objectForKey:@"password1"];
	password2 = [dictionary objectForKey:@"password2"];
	
	NSDebugLog(@"(%@|%@)", password1, password2);
	
	if (password1 && password2) {
		
		_password1Label1.text = [password1 substringWithRange:NSMakeRange(0, 1)];
		_password1Label2.text = [password1 substringWithRange:NSMakeRange(1, 1)];
		_password1Label3.text = [password1 substringWithRange:NSMakeRange(2, 1)];
		_password1Label4.text = [password1 substringWithRange:NSMakeRange(3, 1)];
		
		_password2Label1.text = [password2 substringWithRange:NSMakeRange(0, 1)];
		_password2Label2.text = [password2 substringWithRange:NSMakeRange(1, 1)];
		_password2Label3.text = [password2 substringWithRange:NSMakeRange(2, 1)];
		_password2Label4.text = [password2 substringWithRange:NSMakeRange(3, 1)];
		
		// @TODO: Find more possibilities with pasteboard
		UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
		pasteboard.URL = [self countdownOnCloserWebsiteURL];
		pasteboard.string = [NSString stringWithFormat:@"%@ - %@", password1, password2];
		
		[self.view addSubview:_tableView];
		[_tableView reloadData];
	} else {
		
	}
}

- (NSURL *)countdownOnCloserWebsiteURL
{
	if (password1 && password2) {
		NSString * urlString = [NSString stringWithFormat:@"http://closer.lisacintosh.com/(%@%%7C%@)", password1, password2];// "%7C" ("%%7C" for the format) for "|" (not reconized by -[NSURL URLWithString:] because this is not a valid character for URL)
		return [NSURL URLWithString:urlString];
	}
	
	[NSException raise:@"ExportToWebsiteViewControllerException" format:@"\"password1\" and \"password2\" must have been set."];
	return nil;
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellID = @"CellID";
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellID];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
	}
	
	cell.textLabel.text = NSLocalizedString(@"Show on Safari", nil);
	cell.textLabel.textAlignment = UITextAlignmentCenter;
	cell.selectionStyle = UITableViewCellSelectionStyleGray;
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[[UIApplication sharedApplication] openURL:[self countdownOnCloserWebsiteURL]];
	
	[_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	/* Allow landscape mode on iPad */
	if (TARGET_IS_IPAD())
		return (UIInterfaceOrientationIsPortrait(interfaceOrientation) || UIInterfaceOrientationIsLandscape(interfaceOrientation));
	else 
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	
	self.password1Label1 = nil;
	self.password1Label2 = nil;
	self.password1Label3 = nil;
	self.password1Label4 = nil;
	
	self.password2Label1 = nil;
	self.password2Label2 = nil;
	self.password2Label3 = nil;
	self.password2Label4 = nil;
	
	self.tableView = nil;
}

@end
