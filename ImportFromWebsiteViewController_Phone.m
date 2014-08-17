//
//  ImportViewController.m
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFromWebsiteViewController_Phone.h"

@interface ImportFromWebsiteViewController_Phone (PrivateMethods)

- (void)updateUI;

@end

@implementation ImportFromWebsiteViewController_Phone

@synthesize hiddenTextField = _hiddenTextField;
@synthesize instructionLabel = _instructionLabel, passwordLabel1 = _passwordLabel1, passwordLabel2 = _passwordLabel2, passwordLabel3 = _passwordLabel3, passwordLabel4 = _passwordLabel4;
@synthesize activityIndicator = _activityIndicator;
@synthesize tableView = _tableView;

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Import", nil);
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	UIBarButtonItem * cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																					   target:self
																					   action:@selector(cancel:)];
	
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	
	UIPasteboard * pasteBoard = [UIPasteboard generalPasteboard];
	NSString * string = pasteBoard.string;
	if (string.length > 0) {
		
		NSError * error = nil;
		regex = [[NSRegularExpression alloc] initWithPattern:@"^(\\d{4})\\s?\\-\\s?(\\d{4})$"// Match "dddd - dddd" (with or without spaces)
													 options:0
													   error:&error];
		if (error) {
			NSLog(@"regex error: %@", [error localizedDescription]);
		}
		
		
		NSRange range = [regex rangeOfFirstMatchInString:string
												 options:0
												   range:NSMakeRange(0, string.length)];
		
		if (range.location != NSNotFound) {
			UIBarButtonItem * pasteButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Paste", nil)
																				 style:UIBarButtonItemStylePlain
																				target:self
																				action:@selector(pasteFromPasteboard:)];
			
			self.navigationItem.rightBarButtonItem = pasteButtonItem;
		}
	}
	
	_instructionLabel.text = NSLocalizedString(@"Enter the First Password", nil);
	_passwordLabel1.text = _passwordLabel2.text = _passwordLabel3.text = _passwordLabel4.text = @"";
	
	pushed = NO, sended = NO;
	
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
    if (!TARGET_IS_IOS7_OR_LATER()) {
		_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
		_tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		
		self.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	}
    
	[_hiddenTextField becomeFirstResponder];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
}

- (IBAction)cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)pasteFromPasteboard:(id)sender
{
	NSString * string = [UIPasteboard generalPasteboard].string;
	NSString * _password1 = [regex stringByReplacingMatchesInString:string
															options:0
															  range:NSMakeRange(0, string.length)
													   withTemplate:@"$1"];
	
	NSString * _password2 = [regex stringByReplacingMatchesInString:string
															options:0
															  range:NSMakeRange(0, string.length)
													   withTemplate:@"$2"];
	
	if (_password1 && _password2) {
		password1 = _password1;
		
		password2 = _password2;
		
		pasteAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Paste", nil)
													message:[NSString stringWithFormat:NSLocalizedString(@"Do you want to use\n %@ and %@\nas passwords to import?", nil), password1, password2]
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										  otherButtonTitles:NSLocalizedString(@"Import", nil), nil];
		[pasteAlertView show];
	} else {
		// @TODO: show that failure
	}
}

- (void)push
{
	_instructionLabel.text = NSLocalizedString(@"Enter the Second Password", nil);
	_passwordLabel1.text = _passwordLabel2.text = _passwordLabel3.text = _passwordLabel4.text = @"";
	_hiddenTextField.text = @"";
}

- (void)send
{
	self.navigationItem.rightBarButtonItem = nil;
	
	[_hiddenTextField resignFirstResponder];
	_hiddenTextField.hidden = YES;
	
	[_activityIndicator startAnimating];
	
	_instructionLabel.hidden = YES;
	
	_passwordLabel1.hidden = YES;
	_passwordLabel2.hidden = YES;
	_passwordLabel3.hidden = YES;
	_passwordLabel4.hidden = YES;
	
	NSURL * url = [NSURL URLWithString:@"http://closer.lisacintosh.com/export.php"];
	NSMutableURLRequest * request = [[NSMutableURLRequest alloc] initWithURL:url];
	
	NSData * data = [[NSString stringWithFormat:@"psw1=%@&psw2=%@", password1, password2] dataUsingEncoding:NSUTF8StringEncoding];
	
	[request setHTTPBody:data];
	[request setHTTPMethod:@"POST"];
	
	connection = [[NSURLConnection alloc] initWithRequest:request
												 delegate:self
										 startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	selectedCountdowns = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	
	NSLocale * locale = [NSLocale currentLocale];
	[formatter setLocale:locale];
	
	[formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	[formatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
	
	NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
	
	if ([dictionary valueForKey:@"group"]) {// If we have a group (many countdowns)
		
		NSMutableArray * _countdowns = [[NSMutableArray alloc] initWithCapacity:10];
		
		NSArray * array = [dictionary valueForKey:@"group"];
		for (NSDictionary * attributes in array) {
			Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
			countdown.endDate = [formatter dateFromString:attributes[@"endDate"]];
			countdown.name = attributes[@"name"];
			countdown.message = attributes[@"message"];
			countdown.style = [attributes[@"style"] integerValue];
			
			if ([countdown.endDate timeIntervalSinceNow] > 0)
				[selectedCountdowns addObject:countdown];
			
			[_countdowns addObject:countdown];
		}
		
		countdowns = (NSArray *)_countdowns;
		
	} else if ([dictionary valueForKey:@"endDate"]) {// Else is we have just a countdown
		
		Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.endDate = [formatter dateFromString:dictionary[@"endDate"]];
		countdown.name = dictionary[@"name"];
		countdown.message = dictionary[@"message"];
		countdown.style = [dictionary[@"style"] integerValue];
		
		if ([countdown.endDate timeIntervalSinceNow] > 0)
			[selectedCountdowns addObject:countdown];
		
		countdowns = @[countdown];
		
	} else {
		noCountdownFoundAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"No Countdowns found", nil)
															   message:[NSString stringWithFormat:NSLocalizedString(@"Check that:\n%@ and %@\nare two correct passwords.", nil), password1, password2]
															  delegate:self
													 cancelButtonTitle:NSLocalizedString(@"OK", nil)
													 otherButtonTitles:nil];
		[noCountdownFoundAlertView show];
	}
	
	
	if (countdowns.count > 0) {
		UIBarButtonItem * importButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
																			  style:UIBarButtonItemStyleDone
																			 target:self
																			 action:@selector(import:)];
		if (!TARGET_IS_IOS7_OR_LATER())
			importButtonItem.tintColor = [UIColor doneButtonColor];
		
		self.navigationItem.rightBarButtonItem = importButtonItem;
	}
	
	[self updateUI];
	
	_tableView.contentInset = UIEdgeInsetsMake(64., 0., 0., 0.);
	[self.view addSubview:_tableView];
	[_tableView reloadData];
}

- (void)updateUI
{
	self.navigationItem.rightBarButtonItem.enabled = (selectedCountdowns.count > 0);
}

- (IBAction)import:(id)sender
{
#if TARGET_IPHONE_SIMULATOR
	NSInteger currentCount = [Countdown allCountdowns].count;
	NSInteger importedCount = selectedCountdowns.count;
	NSDebugLog(@"%i from current countdowns + %i imported countdowns", currentCount, importedCount);
#endif
	
	[Countdown addCountdowns:selectedCountdowns];
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection Error", nil)
														 message:[error localizedDescription]
														delegate:self
											   cancelButtonTitle:nil
											   otherButtonTitles:nil];
	[alertView show];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	[_activityIndicator stopAnimating];
}

- (void)textFieldDidChange:(NSNotification *)notification
{
	NSString * string = _hiddenTextField.text;
	_passwordLabel1.text = (string.length >= 1)? [string substringWithRange:NSMakeRange(0, 1)] : @"";
	_passwordLabel2.text = (string.length >= 2)? [string substringWithRange:NSMakeRange(1, 1)] : @"";
	_passwordLabel3.text = (string.length >= 3)? [string substringWithRange:NSMakeRange(2, 1)] : @"";
	_passwordLabel4.text = (string.length >= 4)? [string substringWithRange:NSMakeRange(3, 1)] : @"";
	
	if (string.length >= 4) {
		if ([_instructionLabel.text isEqualToString:NSLocalizedString(@"Enter the First Password", nil)]) {
			if (!pushed) {
				[self performSelector:@selector(push)
						   withObject:nil
						   afterDelay:0.5];
				
				password1 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extre numbers
				pushed = YES;
			}
		} else if ([_instructionLabel.text isEqualToString:NSLocalizedString(@"Enter the Second Password", nil)]) {
			if (!sended) {
				[self performSelector:@selector(send)
						   withObject:nil
						   afterDelay:0.5];
				
				password2 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extre numbers
				sended = YES;
			}
		}
	}
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return countdowns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * identifier = @"CellID";
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	
	Countdown * countdown = countdowns[indexPath.row];
	cell.textLabel.text = countdown.name;
	
	if ([countdown.endDate timeIntervalSinceNow] > 0) {
		cell.detailTextLabel.text = [countdown.endDate description];
		cell.textLabel.textColor = [UIColor blackColor];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		cell.accessoryType = ([selectedCountdowns containsObject:countdown])? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
		
	} else {
		cell.detailTextLabel.text = NSLocalizedString(@"Countdown finished", nil);
		cell.textLabel.textColor = [UIColor grayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Countdown * countdown = countdowns[indexPath.row];
	
	if ([countdown.endDate timeIntervalSinceNow] > 0.) {// Change check state only for valid (not finished) countdowns
		UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			
			[selectedCountdowns removeObject:countdown];
			cell.accessoryType = UITableViewCellAccessoryNone;
			
		} else {
			
			if (![selectedCountdowns containsObject:countdown]) {// Just check, there is probably no way to get duplicates, but in the case of...
				
				NSInteger currentCount = [Countdown allCountdowns].count;
				NSInteger toImportCount = selectedCountdowns.count;
				
				// @TODO: show an alert when the limit have been reached the first time
				
				if ((toImportCount + currentCount) < 18) {// If the limit (of 18) have don't be reach, add countdown
					[selectedCountdowns addObject:countdown];
					cell.accessoryType = UITableViewCellAccessoryCheckmark;
				} else {
					// If the limit have been reached, don't show the checkmark and don't add to "selectedCountdowns"
				}
			}
		}
		
		[self updateUI];
		
		[aTableView deselectRowAtIndexPath:indexPath animated:YES];
	}
}

#pragma mark -
#pragma mark Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (alertView == pasteAlertView) {
		if (buttonIndex == 1) // Import
			[self send];
		// else, it's for Cancel, do nothing
		
	} else if (alertView == noCountdownFoundAlertView) {
		[self dismissViewControllerAnimated:YES completion:NULL];
	} else {// On error alert view
		[self dismissViewControllerAnimated:YES completion:NULL];
	}
}

@end
