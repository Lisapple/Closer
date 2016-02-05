//
//  ExportToWebsiteViewController.m
//  Closer
//
//  Created by Max on 07/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ExportToWebsiteViewController.h"

#import "NSDate+addition.h"

@interface ExportToWebsiteViewController ()

@property (nonatomic, strong) NSString * password1, * password2;

@property (nonatomic, strong) IBOutlet UILabel * password1Label1, * password1Label2, * password1Label3, * password1Label4;
@property (nonatomic, strong) IBOutlet UILabel * password2Label1, * password2Label2, * password2Label3, * password2Label4;
@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicator;

- (IBAction)done:(id)sender;
- (IBAction)export:(id)sender;

- (NSURL *)countdownOnCloserWebsiteURL;

@end

@implementation ExportToWebsiteViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	NSString * nibName = (TARGET_IS_IPAD())? @"ExportToWebsiteViewController_Pad" : @"ExportToWebsiteViewController_Phone";
	if ((self = [super initWithNibName:nibName bundle:[NSBundle mainBundle]])) { }
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Exported to Website", nil);
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
																				 target:self action:@selector(done:)];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	
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
			NSDictionary * attributes = @{ @"name": countdown.name,
										   @"endDate": countdown.endDate.SQLDateTime,
										   @"message": ((countdown.message)? countdown.message: @""),// If we don't have message (= nil), pass a empty string
										   @"style": @(countdown.style),
										   @"client": [UIDevice currentDevice].model };
			[objects addObject:attributes];
		}
		
		NSDictionary * outputDictionary = @{@"group": objects};
		JSONData = [NSJSONSerialization dataWithJSONObject:outputDictionary options:0 error:NULL];
		
	} else if (_countdowns.count == 1) {
		/* If just one countdown into "_countdowns", create a dictionary with content of the countdown */
		
		Countdown * countdown = _countdowns[0];
		NSDictionary * attributes = @{ @"name": countdown.name,
									   @"endDate": countdown.endDate.SQLDateTime,
									   @"message": countdown.message,
									   @"style": @(countdown.style),
									   @"client": [UIDevice currentDevice].model };
		
		JSONData = [NSJSONSerialization dataWithJSONObject:attributes options:0 error:NULL];
		
	} else {
		/* The "_countdowns" should not be empty, but, in this case, quit the method */
		return ;
	}
	
	NSMutableData * data = [[NSMutableData alloc] initWithCapacity:(10 + JSONData.length)];
	[data appendData:[@"json_data=" dataUsingEncoding:NSUTF8StringEncoding]];
	[data appendData:JSONData];
	
	request.HTTPBody = data;
	request.HTTPMethod = @"POST";
	
	NSURLConnection * connection = [NSURLConnection connectionWithRequest:request delegate:self];
	[connection start];
	
	[_activityIndicator startAnimating];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error!", nil)
																	message:error.localizedDescription
															 preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		[alert dismissViewControllerAnimated:YES completion:nil]; }]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	[_activityIndicator stopAnimating];
	
	NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
	
	_password1 = dictionary[@"password1"];
	_password2 = dictionary[@"password2"];
	
	NSDebugLog(@"(%@|%@)", _password1, _password2);
	
	if (_password1 && _password2) {
		
		_password1Label1.text = [_password1 substringWithRange:NSMakeRange(0, 1)];
		_password1Label2.text = [_password1 substringWithRange:NSMakeRange(1, 1)];
		_password1Label3.text = [_password1 substringWithRange:NSMakeRange(2, 1)];
		_password1Label4.text = [_password1 substringWithRange:NSMakeRange(3, 1)];
		
		_password2Label1.text = [_password2 substringWithRange:NSMakeRange(0, 1)];
		_password2Label2.text = [_password2 substringWithRange:NSMakeRange(1, 1)];
		_password2Label3.text = [_password2 substringWithRange:NSMakeRange(2, 1)];
		_password2Label4.text = [_password2 substringWithRange:NSMakeRange(3, 1)];
		
		// @TODO: Find more possibilities with pasteboard
		UIPasteboard * pasteboard = [UIPasteboard generalPasteboard];
		pasteboard.URL = [self countdownOnCloserWebsiteURL];
		pasteboard.string = [NSString stringWithFormat:@"%@ - %@", _password1, _password2];
		
		_tableView.frame = self.view.frame;
		[self.view addSubview:_tableView];
		[_tableView reloadData];
	}
}

- (NSURL *)countdownOnCloserWebsiteURL
{
	if (_password1 && _password2) {
		NSString * urlString = [NSString stringWithFormat:@"http://closer.lisacintosh.com/(%@%%7C%@)", _password1, _password2];// "%7C" ("%%7C" for the format) for "|" (not reconized by -[NSURL URLWithString:] because this is not a valid character for URL)
		return [NSURL URLWithString:urlString];
	}
	
	[NSException raise:@"ExportToWebsiteViewControllerException" format:@"\"password1\" and \"password2\" must have been set."];
	return nil;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellID = @"CellID";
	UITableViewCell * cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
		cell.textLabel.textAlignment = NSTextAlignmentCenter;
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
	}
	cell.textLabel.text = NSLocalizedString(@"Show on Safari", nil);
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[[UIApplication sharedApplication] openURL:[self countdownOnCloserWebsiteURL]];
	
	[aTableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
