//
//  ImportViewController.m
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImportFromWebsiteViewController_Pad.h"
#import "NSDate+addition.h"

@interface ImportFromWebsiteViewController_Pad ()

@property (nonatomic, strong) NSString * password1, * password2;
@property (nonatomic, strong) NSArray <Countdown *> * countdowns;
@property (nonatomic, strong) NSMutableArray <Countdown *> * selectedCountdowns;

@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, strong) NSRegularExpression * regex;

- (IBAction)reshowKeyboardAction:(id)sender;

- (void)updateUI;

@end

@implementation ImportFromWebsiteViewController_Pad

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Import", nil);
	self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.25 alpha:1.];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self action:@selector(cancel:)];
	
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
	// Add a gesture for the main view to re-show the keyboard
	UITapGestureRecognizer * gestureRecogninizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(reshowKeyboardAction:)];
	[self.view addGestureRecognizer:gestureRecogninizer];
	
	_password1Label1.text = _password1Label2.text = _password1Label3.text = _password1Label4.text = nil;
	_password2Label1.text = _password2Label2.text = _password2Label3.text = _password2Label4.text = nil;
	
	_hiddenTextField1.keyboardType = _hiddenTextField2.keyboardType = UIKeyboardTypeNumberPad;
	_hiddenTextField1.delegate = _hiddenTextField2.delegate = self;
	[_hiddenTextField1 becomeFirstResponder];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	_pasteButton.hidden = YES;
	UIPasteboard * pasteBoard = [UIPasteboard generalPasteboard];
	NSString * string = pasteBoard.string;
	if (string.length > 0 && !_password1 && !_password2) {
		NSError * error = nil;
		_regex = [[NSRegularExpression alloc] initWithPattern:@"^(\\d{4})[^\\d]*(\\d{4})?$" // Match 4 digits once and two times (separated with non-digits)
													  options:0 error:&error];
		NSAssert(_regex, error.localizedDescription);
		
		NSRange range = NSMakeRange(0, string.length);
		if ([_regex firstMatchInString:string options:0 range:range]) {
			NSString * string = [UIPasteboard generalPasteboard].string;
			NSString * password1 = [_regex stringByReplacingMatchesInString:string options:0 range:range withTemplate:@"$1"];
			NSString * password2 = [_regex stringByReplacingMatchesInString:string options:0 range:range withTemplate:@"$2"];
			if (password1.length && password2.length) {
				_pasteButton.hidden = NO;
				_password1 = password1;
				_password2 = password2;
				[_pasteButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Use %@ and %@", nil), password1, password2]
							  forState:UIControlStateNormal];
			} else if (password1.length) {
				_pasteButton.hidden = NO;
				_password1 = password1;
				_password2 = nil;
				[_pasteButton setTitle:[NSString stringWithFormat:NSLocalizedString(@"Use %@", nil), password1]
							  forState:UIControlStateNormal];
			}
		}
	}
}

- (IBAction)reshowKeyboardAction:(id)sender
{
	// If the keyboard if not shown
	if (!_hiddenTextField1.isFirstResponder && !_hiddenTextField2.isFirstResponder) {
		// If the first password field is not full, make it as first responder; else make "_hiddenTextField2" is first responder
		(_password1.length < 4)? [_hiddenTextField1 becomeFirstResponder] : [_hiddenTextField2 becomeFirstResponder];
	}
}

- (IBAction)cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)pasteFromPasteboard:(id)sender
{
	[self send];
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
	request.HTTPBody = [[NSString stringWithFormat:@"psw1=%@&psw2=%@", _password1, _password2] dataUsingEncoding:NSUTF8StringEncoding];
	request.HTTPMethod = @"POST";
	_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	_selectedCountdowns = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	formatter.locale = [NSLocale currentLocale];
	formatter.dateFormat = @"YYYY-MM-dd HH:mm:ss";
	formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	
	NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
	
	if ([dictionary valueForKey:@"group"]) {// If we have a group (many countdowns)
		
		NSMutableArray * countdowns = [[NSMutableArray alloc] initWithCapacity:10];
		
		NSArray * array = [dictionary valueForKey:@"group"];
		for (NSDictionary * attributes in array) {
			Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
			countdown.endDate = [formatter dateFromString:attributes[@"endDate"]];
			countdown.name = attributes[@"name"];
			countdown.message = attributes[@"message"];
			countdown.style = [attributes[@"style"] integerValue];
			[countdowns addObject:countdown];
			
			if (countdown.endDate.timeIntervalSinceNow > 0)
				[_selectedCountdowns addObject:countdown];
		}
		
		_countdowns = (NSArray *)countdowns;
		
	} else if ([dictionary valueForKey:@"endDate"]) {// Else is we have just a countdown
		
		Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.endDate = [formatter dateFromString:dictionary[@"endDate"]];
		countdown.name = dictionary[@"name"];
		countdown.message = dictionary[@"message"];
		countdown.style = [dictionary[@"style"] integerValue];
		
		if ((countdown.endDate).timeIntervalSinceNow > 0)
			[_selectedCountdowns addObject:countdown];
		
		_countdowns = @[ countdown ];
		
	} else {
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Check that:\n%@ and %@\nare two correct passwords.", nil), _password1, _password2];
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Countdowns found", nil)
																		message:message
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
			[alert dismissViewControllerAnimated:YES completion:nil];
			[self dismissViewControllerAnimated:YES completion:nil]; }]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	
	if (_countdowns.count > 0) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
																			  style:UIBarButtonItemStyleDone
																			 target:self action:@selector(import:)];
	}
	
	[self updateUI];
	
	[self.view addSubview:_tableView];
	[_tableView reloadData];
}

- (void)updateUI
{
	self.navigationItem.rightBarButtonItem.enabled = (_selectedCountdowns.count > 0);
}

- (IBAction)import:(id)sender
{
#if TARGET_IPHONE_SIMULATOR
	NSInteger currentCount = [Countdown allCountdowns].count;
	NSInteger importedCount = _selectedCountdowns.count;
	NSDebugLog(@"%ld from current countdowns + %ld imported countdowns", (long)currentCount, (long)importedCount);
#endif
	
	[Countdown addCountdowns:_selectedCountdowns];
	[self dismissViewControllerAnimated:YES completion:NULL];
	
	/* Send a notification to reload countdowns on main page */
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CountdownDidCreateNewNotification" object:nil];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection Error", nil)
																	message:error.localizedDescription
															 preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
		[alert dismissViewControllerAnimated:YES completion:nil];
		[self dismissViewControllerAnimated:YES completion:nil]; }]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
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
			_password1 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extra numbers
			
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
				_password2 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extra numbers
				[self send];
			}
		}
	}
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _countdowns.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * identifier = @"CellID";
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:identifier];
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier];
	
	Countdown * countdown = _countdowns[indexPath.row];
	cell.textLabel.text = countdown.name;
	
	if (countdown.endDate.timeIntervalSinceNow > 0) {
		cell.detailTextLabel.text = countdown.endDate.localizedDescription;
		cell.textLabel.textColor = [UIColor blackColor];
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		
		cell.accessoryType = ([_selectedCountdowns containsObject:countdown])? UITableViewCellAccessoryCheckmark: UITableViewCellAccessoryNone;
		
	} else {
		cell.detailTextLabel.text = NSLocalizedString(@"Countdown finished", nil);
		cell.textLabel.textColor = [UIColor grayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	
	return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Countdown * countdown = _countdowns[indexPath.row];
	
	if (countdown.endDate.timeIntervalSinceNow > 0.) { // Change check state only for valid (not finished) countdowns
		UITableViewCell * cell = [aTableView cellForRowAtIndexPath:indexPath];
		if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
			
			[_selectedCountdowns removeObject:countdown];
			cell.accessoryType = UITableViewCellAccessoryNone;
			
		} else {
			
			if (![_selectedCountdowns containsObject:countdown]) {// Just check, there is probably no way to get duplicates, but in the case of...
				
				NSInteger currentCount = [Countdown allCountdowns].count;
				NSInteger toImportCount = _selectedCountdowns.count;
				
				// @TODO: show an alert when the limit have been reached the first time
				
				if ((toImportCount + currentCount) < 18) {// If the limit (of 18) have don't be reach, add countdown
					[_selectedCountdowns addObject:countdown];
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

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
