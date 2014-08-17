//
//  ExportToWebsiteViewController.m
//  Closer
//
//  Created by Max on 07/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ExportToWebsiteViewController.h"

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
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	UIBarButtonItem * doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				 target:self
																				 action:@selector(done:)];
	if (!TARGET_IS_IOS7_OR_LATER())
		doneButton.tintColor = [UIColor doneButtonColor];
	
	self.navigationItem.rightBarButtonItem = doneButton;
	
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
    if (!TARGET_IS_IOS7_OR_LATER()) {
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
        _tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        _tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        self.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        
        UIView * backgroundView = [[UIView alloc] init];
        backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
        _tableView.backgroundView = backgroundView;
	}
    
	[self export:nil];
}

- (IBAction)done:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)export:(id)sender
{
	NSURL * url = [NSURL URLWithString:@"http://closer.lisacintosh.com/import.php"];
	NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
	
	NSData * JSONData = nil;
	if (_countdowns.count > 1) {
		
		/* If many countdowns into "_countdowns", create a dictionary for each countdown, put all dict into an array and create a dict with the array:
		 "group" = {
		 [ {"name" : "countdown 1", [...] } ],
		 [ {"name" : "countdown 2", [...] } ], etc.
		 }
		 */
		
		NSMutableArray * objects = [[NSMutableArray alloc] initWithCapacity:_countdowns.count];
		for (Countdown * countdown in _countdowns) {
			NSDictionary * attributes = @{@"name": countdown.name,
										 @"endDate": [countdown.endDate SQLDateTime],
                                         @"message": ((countdown.message)? countdown.message: @""),// If we don't have message (= nil), pass a empty string
										 @"style": @(countdown.style),
										 @"client": [UIDevice currentDevice].model};
			[objects addObject:attributes];
		}
		
		NSDictionary * outputDictionary = @{@"group": objects};
		JSONData = [NSJSONSerialization dataWithJSONObject:outputDictionary
												   options:0
													 error:NULL];
		
	} else if (_countdowns.count == 1) {
		/* If just one countdown into "_countdowns", create a dictionary with content of the countdown */
		
		Countdown * countdown = _countdowns[0];
		NSDictionary * attributes = @{@"name": countdown.name,
									 @"endDate": [countdown.endDate SQLDateTime],
									 @"message": countdown.message,
									 @"style": @(countdown.style),
									 @"client": [UIDevice currentDevice].model};
		
		JSONData = [NSJSONSerialization dataWithJSONObject:attributes
													 options:0
													   error:NULL];
		
	} else {
		/* The "_countdowns" should not be empty, but, in this case, quit the method */
		return ;
	}
	
	NSMutableData * data = [[NSMutableData alloc] initWithCapacity:(10 + JSONData.length)];
	[data appendData:[@"json_data=" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:JSONData];
	
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
	
	NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
	
	password1 = dictionary[@"password1"];
	password2 = dictionary[@"password2"];
	
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
		
		_tableView.frame = self.view.frame;
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
	cell.textLabel.textAlignment = NSTextAlignmentCenter;
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

@end
