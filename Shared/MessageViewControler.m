//
//  MessageViewControler.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MessageViewControler.h"

#import "UIColor+addition.h"
#import "UITableView+addition.h"

@implementation MyTextView

@synthesize undoManager = _undoManager;

@end

@implementation MessageViewControler

@synthesize tableView;
@synthesize cellTextView;

@synthesize messageCell;

@synthesize countdown;

@synthesize undoManager;

const CGFloat kHeightRowLandscape = 60.;
const CGFloat kHeightRowPortrait = 120.;

const CGFloat kKeyboardHeightPortrait = 216.;
const CGFloat kKeyboardHeightLandscape = 162.;

- (void)viewDidLoad
{
	self.title = NSLocalizedString(@"Message", nil);
	
	UIBarButtonItem * clearButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil)
																	 style:UIBarButtonItemStylePlain
																	target:self 
																	action:@selector(clear:)];
	self.navigationItem.rightBarButtonItem = clearButton;
	
	tableView.delegate = self;
	tableView.dataSource = self;
	
	tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	tableView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.alwaysBounceVertical = YES;
	
	UIView * backgroundView = [[UIView alloc] init];
	backgroundView.backgroundColor = [UIColor groupedTableViewBackgroundColor];
	tableView.backgroundView = backgroundView;
	
	cellTextView.text = countdown.message;
	cellTextView.delegate = self;
	cellTextView.scrollEnabled = NO;
	
	self.navigationItem.rightBarButtonItem.enabled = (countdown.message.length > 0);
	
	[tableView reloadData];
	
	[tableView setFooterText:NSLocalizedString(@"This message will be shown when countdown will be finished.", nil)];
	
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
	NSUndoManager * anUndomanager = [[NSUndoManager alloc] init];
	self.undoManager = anUndomanager;
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[self update];
	
	cellTextView.undoManager = self.undoManager;// Overwrite the cellTextView undo manager with the controller one since [cellTextView becomeFirstResponder] set the default undo manager from cellTextView undo manager (setActionName should not working with this method).
	
	[cellTextView becomeFirstResponder];
	
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	countdown.message = cellTextView.text;
	
	cellTextView.undoManager = nil;
	self.undoManager = nil;
	
	[super viewWillDisappear:animated];
}

- (void)setText:(NSString *)textString
{
	cellTextView.text = textString;
}

- (IBAction)clear:(id)sender
{
	if (cellTextView.text.length > 0) {
		[self.undoManager registerUndoWithTarget:self
										selector:@selector(setText:)
										  object:cellTextView.text];
		
		[self.undoManager setActionName:NSLocalizedString(@"UNDO_MESSAGE_ACTION", nil)];
		
		cellTextView.text = @"";
	}
}

#pragma mark -
#pragma mark Table view data source

- (CGFloat)keyboardHeight
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
		return kKeyboardHeightLandscape;
	
	return kKeyboardHeightPortrait;
}

- (CGFloat)rowHeight
{
	CGSize size = [cellTextView.text sizeWithFont:cellTextView.font 
								constrainedToSize:CGSizeMake(cellTextView.frame.size.width, INFINITY) 
									lineBreakMode:UILineBreakModeWordWrap];
	
	if (size.height < kHeightRowLandscape)
		return kHeightRowLandscape;
	else
		return size.height;
	
	/*
	 UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	 
	 if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
	 return kHeightRowLandscape;
	 
	 return kHeightRowPortrait;
	 */
}

- (void)update
{
	CGRect frame = messageCell.frame;
	messageCell.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [self rowHeight] + 40.);
	
	frame = tableView.tableFooterView.frame;
	CGFloat y = messageCell.frame.origin.x + messageCell.frame.size.height + 20.;
	tableView.tableFooterView.frame = CGRectMake(frame.origin.x, y, frame.size.width, frame.size.height);
	
	tableView.contentSize = CGSizeMake(0., tableView.tableFooterView.frame.origin.y + tableView.tableFooterView.frame.size.height);
	
	tableView.contentInset = UIEdgeInsetsMake(0., 0., [self keyboardHeight] + 20., 0);
	tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0., 0., [self keyboardHeight], 0);
	
	/* Update Clear button enable */
	self.navigationItem.rightBarButtonItem.enabled = (cellTextView.text.length > 0);
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [self rowHeight];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	UITableViewCell * cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
		cell.clipsToBounds = YES;
		cell.contentView.autoresizesSubviews = YES;
		[cell.contentView addSubview:cellTextView];
	}
	
	self.messageCell = cell;
	
	return cell;
}

#pragma mark -
#pragma mark Table view data source

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self update];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self update];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
	tableView.contentInset = UIEdgeInsetsZero;
	tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self update];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UIInterfaceOrientationIsPortrait(interfaceOrientation));
}

- (BOOL)canBecomeFirstResponder
{
	return YES;// Return YES to receive shake to undo gesture
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload
{
	self.cellTextView = nil;
	self.tableView = nil;
	
	self.messageCell = nil;
	
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}




@end
