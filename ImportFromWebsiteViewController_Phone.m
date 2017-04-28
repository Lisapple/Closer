//
//  ImportViewController.m
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "ImportFromWebsiteViewController_Phone.h"
#import "NSDate+addition.h"

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
	
	_pushed = NO, _sent = NO;
	
	_tableView.dataSource = self;
	_tableView.delegate = self;
	
	_instructionLabel.text = NSLocalizedString(@"Enter the First Password", nil);
	_passwordLabel1.text = _passwordLabel2.text = _passwordLabel3.text = _passwordLabel4.text = nil;
	
	[_hiddenTextField becomeFirstResponder];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:)
												 name:UITextFieldTextDidChangeNotification object:nil];
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

- (IBAction)cancel:(id)sender
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)pasteFromPasteboard:(id)sender
{
	if (_password1 && _password2) {
		[self send];
	} else if (_password1) {
		_passwordLabel1.text = [_password1 substringWithRange:NSMakeRange(0, 1)];
		_passwordLabel2.text = [_password1 substringWithRange:NSMakeRange(1, 1)];
		_passwordLabel3.text = [_password1 substringWithRange:NSMakeRange(2, 1)];
		_passwordLabel4.text = [_password1 substringWithRange:NSMakeRange(3, 1)];
		_pasteButton.hidden = YES;
		[self performSelector:@selector(pushSecondPassword) withObject:nil afterDelay:0.25];
	}
}

- (void)pushSecondPassword
{
	NSTimeInterval duration = 0.5;
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration / 2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		_instructionLabel.text = NSLocalizedString(@"Enter the Second Password", nil);
		_passwordLabel1.text = _passwordLabel2.text = _passwordLabel3.text = _passwordLabel4.text = nil;
		_hiddenTextField.text = nil;
	});
	[UIView animateKeyframesWithDuration:duration delay:0 options:0
							  animations:^{
								  [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
									  _contentView.transform = CGAffineTransformMakeTranslation(-self.view.frame.size.width / 2, 0); }];
								  [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0 animations:^{
									  _contentView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width / 2, 0); }];
								  [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
									  _contentView.transform = CGAffineTransformIdentity; }];
							  }
							  completion:^(BOOL finished) { }];
}

- (void)send
{
	self.navigationItem.rightBarButtonItem = nil;
	
	[_hiddenTextField resignFirstResponder];
	_hiddenTextField.hidden = YES;
	
	[_activityIndicator startAnimating];
	
	_instructionLabel.hidden = YES;
	_passwordLabel1.hidden = _passwordLabel2.hidden = _passwordLabel3.hidden = _passwordLabel4.hidden = YES;
	
	NSURL * url = [NSURL URLWithString:@"https://closer.lisacintosh.com/export.php"];
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
																		message:message preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
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
	[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel
											handler:^(UIAlertAction * action) { [alert dismissViewControllerAnimated:YES completion:nil]; }]];
	[self presentViewController:alert animated:YES completion:nil];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
	[_activityIndicator stopAnimating];
}

- (void)textFieldDidChange:(NSNotification *)notification
{
	NSString * string = _hiddenTextField.text;
	_passwordLabel1.text = (string.length >= 1) ? [string substringWithRange:NSMakeRange(0, 1)] : nil;
	_passwordLabel2.text = (string.length >= 2) ? [string substringWithRange:NSMakeRange(1, 1)] : nil;
	_passwordLabel3.text = (string.length >= 3) ? [string substringWithRange:NSMakeRange(2, 1)] : nil;
	_passwordLabel4.text = (string.length >= 4) ? [string substringWithRange:NSMakeRange(3, 1)] : nil;
	
	if (string.length >= 4) {
		if ([_instructionLabel.text isEqualToString:NSLocalizedString(@"Enter the First Password", nil)]) {
			if (!_pushed) {
				[self performSelector:@selector(pushSecondPassword) withObject:nil afterDelay:0.5];
				
				_password1 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extre numbers
				_pushed = YES;
			}
		} else if ([_instructionLabel.text isEqualToString:NSLocalizedString(@"Enter the Second Password", nil)]) {
			if (!_sent) {
				[self performSelector:@selector(send) withObject:nil afterDelay:0.5];
				
				_password2 = [string substringToIndex:4];// Just in case that we have more than 4 numbers on password, remove extre numbers
				_sent = YES;
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
		cell.textLabel.text = countdown.endDate.localizedDescription;
		cell.textLabel.textColor = [UIColor blackColor];
		
		cell.selectionStyle = UITableViewCellSelectionStyleGray;
		cell.accessoryType = ([_selectedCountdowns containsObject:countdown]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
	} else {
		cell.textLabel.text = NSLocalizedString(@"Countdown finished", nil);
		cell.textLabel.textColor = [UIColor grayColor];
		
		cell.detailTextLabel.text = countdown.endDate.localizedDescription;
		cell.detailTextLabel.textColor = [UIColor grayColor];
		
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
			if (![_selectedCountdowns containsObject:countdown]) { // Just check, there is probably no way to get duplicates, but in the case of...
				
				NSInteger currentCount = [Countdown allCountdowns].count;
				NSInteger toImportCount = _selectedCountdowns.count;
				
				// @TODO: show an alert when the limit have been reached the first time
				
				if ((toImportCount + currentCount) < 18) { // If the limit (of 18) have don't be reach, add countdown
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
