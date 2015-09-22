//
//  ImportViewController.m
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFromWebsiteViewController_Phone.h"
#import "Countdown.h"

@interface ImportFromWebsiteViewController_Phone ()

@property (nonatomic, strong) NSString * password1, * password2;
@property (nonatomic, strong) NSArray <Countdown *> * countdowns;
@property (nonatomic, strong) NSMutableArray <Countdown *> * selectedCountdowns;
@property (nonatomic, strong) NSRegularExpression * regex;
@property (nonatomic, strong) NSURLConnection * connection;
@property (nonatomic, assign) BOOL pushed, sent;

- (void)updateUI;

@end

@implementation ImportFromWebsiteViewController_Phone

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"Import", nil);
	
	self.navigationController.navigationBar.tintColor = [UIColor defaultTintColor];
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
																						  target:self action:@selector(cancel:)];
	
	UIPasteboard * pasteBoard = [UIPasteboard generalPasteboard];
	NSString * string = pasteBoard.string;
	if (string.length > 0) {
		
		NSError * error = nil;
		_regex = [[NSRegularExpression alloc] initWithPattern:@"^(\\d{4})\\s?\\-\\s?(\\d{4})$" // Match "dddd - dddd" (with or without spaces)
													 options:0 error:&error];
		if (error) {
			NSLog(@"regex error: %@", error.localizedDescription);
		}
		
		NSRange range = [_regex rangeOfFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
		if (range.location != NSNotFound) {
			self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Paste", nil)
																					  style:UIBarButtonItemStylePlain
																					 target:self action:@selector(pasteFromPasteboard:)];
		}
	}
	
	_instructionLabel.text = NSLocalizedString(@"Enter the First Password", nil);
	_passwordLabel1.text = _passwordLabel2.text = _passwordLabel3.text = _passwordLabel4.text = @"";
	
	_pushed = NO, _sent = NO;
	
	_tableView.dataSource = self;
	_tableView.delegate = self;
    
	[_hiddenTextField becomeFirstResponder];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:)
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
	NSString * password1 = [_regex stringByReplacingMatchesInString:string options:0
															  range:NSMakeRange(0, string.length) withTemplate:@"$1"];
	NSString * password2 = [_regex stringByReplacingMatchesInString:string options:0
															  range:NSMakeRange(0, string.length) withTemplate:@"$2"];
	if (password1 && password2) {
		_password1 = password1;
		_password2 = password2;
		
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Do you want to use\n %@ and %@\nas passwords to import?", nil), password1, password2];
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Paste Passwords", nil)
																		message:message
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Import", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[self send]; }]];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[alert dismissViewControllerAnimated:YES completion:nil]; }]];
		[self presentViewController:alert animated:YES completion:nil];
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
	
	NSData * data = [[NSString stringWithFormat:@"psw1=%@&psw2=%@", _password1, _password2] dataUsingEncoding:NSUTF8StringEncoding];
	
	request.HTTPBody = data;
	request.HTTPMethod = @"POST";
	
	_connection = [[NSURLConnection alloc] initWithRequest:request
												 delegate:self
										 startImmediately:YES];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	_selectedCountdowns = [[NSMutableArray alloc] initWithCapacity:3];
	
	NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
	
	NSLocale * locale = [NSLocale currentLocale];
	formatter.locale = locale;
	
	formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
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
			
			if (countdown.endDate.timeIntervalSinceNow > 0)
				[_selectedCountdowns addObject:countdown];
			
			[countdowns addObject:countdown];
		}
		
		_countdowns = (NSArray *)countdowns;
		
	} else if ([dictionary valueForKey:@"endDate"]) {// Else is we have just a countdown
		
		Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.endDate = [formatter dateFromString:dictionary[@"endDate"]];
		countdown.name = dictionary[@"name"];
		countdown.message = dictionary[@"message"];
		countdown.style = [dictionary[@"style"] integerValue];
		
		if (countdown.endDate.timeIntervalSinceNow > 0)
			[_selectedCountdowns addObject:countdown];
		
		_countdowns = @[ countdown ];
		
	} else {
		NSString * message = [NSString stringWithFormat:NSLocalizedString(@"Check that:\n%@ and %@\nare two correct passwords.", nil), _password1, _password2];
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"No Countdowns found", nil)
																		message:message
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
			[alert dismissViewControllerAnimated:YES completion:nil];
			[self dismissViewControllerAnimated:YES completion:NULL]; }]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	
	if (_countdowns.count > 0) {
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Import", nil)
																			  style:UIBarButtonItemStyleDone
																			 target:self action:@selector(import:)];
	}
	
	[self updateUI];
	
	_tableView.frame = self.view.bounds;
	_tableView.contentInset = UIEdgeInsetsMake(64., 0., 0., 0.);
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
	NSDebugLog(@"%li from current countdowns + %ld imported countdowns", (long)currentCount, (long)importedCount);
#endif
	
	[Countdown addCountdowns:_selectedCountdowns];
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (void)connection:(NSURLConnection *)aConnection didFailWithError:(NSError *)error
{
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Connection Error", nil)
																	message:error.localizedDescription
															 preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
		[alert dismissViewControllerAnimated:YES completion:nil]; }]];
	[self presentViewController:alert animated:YES completion:nil];
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
			if (!_pushed) {
				[self performSelector:@selector(push)
						   withObject:nil
						   afterDelay:0.5];
				
				_password1 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extre numbers
				_pushed = YES;
			}
		} else if ([_instructionLabel.text isEqualToString:NSLocalizedString(@"Enter the Second Password", nil)]) {
			if (!_sent) {
				[self performSelector:@selector(send)
						   withObject:nil
						   afterDelay:0.5];
				
				_password2 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extre numbers
				_sent = YES;
			}
		}
	}
}

#pragma mark -
#pragma mark Table view data source

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
		cell.detailTextLabel.text = countdown.endDate.description;
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

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	Countdown * countdown = _countdowns[indexPath.row];
	
	if (countdown.endDate.timeIntervalSinceNow > 0.) {// Change check state only for valid (not finished) countdowns
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

@end
