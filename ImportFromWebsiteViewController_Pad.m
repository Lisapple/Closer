//
//  ImportViewController.m
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImportFromWebsiteViewController_Pad.h"

@interface ImportFromWebsiteViewController_Pad (PrivateMethods)

- (IBAction)reshowKeyboardAction:(id)sender;

- (void)updateLayout;
- (void)updateUI;

@end

@implementation ImportFromWebsiteViewController_Pad

@synthesize hiddenTextField1 = _hiddenTextField1, hiddenTextField2 = _hiddenTextField2;
@synthesize contentView1 = _contentView1, contentView2 = _contentView2;
@synthesize password1Label1 = _password1Label1, password1Label2 = _password1Label2, password1Label3 = _password1Label3, password1Label4 = _password1Label4;
@synthesize password2Label1 = _password2Label1, password2Label2 = _password2Label2, password2Label3 = _password2Label3, password2Label4 = _password2Label4;
@synthesize activityIndicator = _activityIndicator;
@synthesize tableView = _tableView;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Import", nil);
	self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.25 alpha:1.];
	
	UIBarButtonItem * cancelButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																					   target:self
																					   action:@selector(cancel:)];
	
	self.navigationItem.leftBarButtonItem = cancelButtonItem;
	
	/* Add a gesture for the main view to re-show the keyboard */
	UITapGestureRecognizer * gestureRecogninizer = [[UITapGestureRecognizer alloc] initWithTarget:self
																						   action:@selector(reshowKeyboardAction:)];
	[self.view addGestureRecognizer:gestureRecogninizer];
	
	
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
	
	_password1Label1.text = _password1Label2.text = _password1Label3.text = _password1Label4.text = @"";
	_password2Label1.text = _password2Label2.text = _password2Label3.text = _password2Label4.text = @"";
	
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
    if (!TARGET_IS_IOS7_OR_LATER()) {
		_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
		_tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		_tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		self.view.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		
		UIView * backgroundView = [[UIView alloc] init];
		backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
		_tableView.backgroundView = backgroundView;
	}
    
	_hiddenTextField1.keyboardType = _hiddenTextField2.keyboardType = UIKeyboardTypeNumberPad;
	_hiddenTextField1.delegate = _hiddenTextField2.delegate = self;
	
	[_hiddenTextField1 becomeFirstResponder];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
	[self updateLayout];
}

- (IBAction)reshowKeyboardAction:(id)sender
{
	/* If the keyboard if not shown */
	if (!_hiddenTextField1.isFirstResponder && !_hiddenTextField2.isFirstResponder) {
		/* If the first password field is not full, make it as first responder; else make "_hiddenTextField2" is first responder */
		(password1.length < 4)? [_hiddenTextField1 becomeFirstResponder] : [_hiddenTextField2 becomeFirstResponder];
	}
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
		
		pasteAlertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Paste Passwords", nil)
													message:[NSString stringWithFormat:NSLocalizedString(@"Do you want to use\n %@ and %@\nas passwords to import?", nil), password1, password2]
												   delegate:self
										  cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
										  otherButtonTitles:NSLocalizedString(@"Import", nil), nil];
		[pasteAlertView show];
	} else {
		// @TODO: show that failure
	}
}

- (void)send
{
	self.navigationItem.rightBarButtonItem = nil;
	
	[_hiddenTextField1 resignFirstResponder];
	[_hiddenTextField2 resignFirstResponder];
	
	_contentView1.hidden = _contentView2.hidden = YES;
	
	_password1Label1.hidden = _password1Label2.hidden = _password1Label2.hidden = _password1Label2.hidden = YES;
	_password2Label1.hidden = _password2Label2.hidden = _password2Label2.hidden = _password2Label2.hidden = YES;
	
	[_activityIndicator startAnimating];
	
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
	
	[formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
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
	
	[self.view addSubview:_tableView];
	[_tableView reloadData];
}

- (void)updateLayout
{
	CGFloat x = (self.view.frame.size.width - _contentView1.frame.size.width) / 2.;
	CGRect rect = _contentView1.frame;
	rect.origin.x = x;
	_contentView1.frame = rect;
	
	x = (self.view.frame.size.width - _contentView2.frame.size.width) / 2.;
	rect = _contentView2.frame;
	rect.origin.x = x;
	_contentView2.frame = rect;
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
	
	/* Send a notification to reload countdowns on main page */
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CountdownDidCreateNewNotification" object:nil];
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
	//_activityIndicator.hidden = YES;
	[_activityIndicator stopAnimating];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	/* If user press delete on the second hidden textField and this textField is empty, give focus to the first textField */
	if (textField != _hiddenTextField1 &&
		string.length == 0 &&
		textField.text.length == 0) {
		[_hiddenTextField1 becomeFirstResponder];
	}
	return (string.length == 0) || ([string rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location != NSNotFound);
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	return YES;
}

- (void)textFieldDidChange:(NSNotification *)notification
{
	if (notification.object == _hiddenTextField1 &&
		[_hiddenTextField1 isFirstResponder]) {// Only catch the change is the field has the focus
		
		NSString * string = _hiddenTextField1.text;
		_password1Label1.text = (string.length >= 1)? [string substringWithRange:NSMakeRange(0, 1)] : @"";
		_password1Label2.text = (string.length >= 2)? [string substringWithRange:NSMakeRange(1, 1)] : @"";
		_password1Label3.text = (string.length >= 3)? [string substringWithRange:NSMakeRange(2, 1)] : @"";
		_password1Label4.text = (string.length >= 4)? [string substringWithRange:NSMakeRange(3, 1)] : @"";
		
		if (string.length >= 4) {
			
			password1 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extra numbers
			
			_hiddenTextField2.text = @" ";// Add an space caracter to catch the "delete" button pressing
			[_hiddenTextField2 becomeFirstResponder];
		}
		
	} else if (notification.object == _hiddenTextField2 &&
			   [_hiddenTextField2 isFirstResponder]) {// Only catch the change is the field has the focus
		
		if (_hiddenTextField2.text.length <= 1) {// If the first number have been deleted
			[_hiddenTextField1 becomeFirstResponder];// Switch to the first field (before changing the second field content, to not catch the notification)
			_hiddenTextField2.text = @" ";// Make sure that we have always the space caracter
			_password2Label1.text = _password2Label2.text = _password2Label3.text = _password2Label4.text = @"";// Clean up labels
		} else {
			
			NSString * string = [_hiddenTextField2.text substringFromIndex:1];// Trim the first extra space caracter (if exists)
			_password2Label1.text = (string.length >= 1)? [string substringWithRange:NSMakeRange(0, 1)] : @"";
			_password2Label2.text = (string.length >= 2)? [string substringWithRange:NSMakeRange(1, 1)] : @"";
			_password2Label3.text = (string.length >= 3)? [string substringWithRange:NSMakeRange(2, 1)] : @"";
			_password2Label4.text = (string.length >= 4)? [string substringWithRange:NSMakeRange(3, 1)] : @"";
			
			if (string.length >= 4) {// If the password field (without the first space caracter) contains 4 numbers (or more)
				
				password2 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extra numbers
				
				[self send];
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
