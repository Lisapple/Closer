//
//  MessageViewControler.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MessageViewControler.h"

@implementation MyTextView

@synthesize undoManager = _undoManager;

@end

@implementation MessageViewControler

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
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Message", nil);
	
	UIBarButtonItem * clearButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil)
																	 style:UIBarButtonItemStylePlain
																	target:self
																	action:@selector(clear:)];
	self.navigationItem.rightBarButtonItem = clearButton;
	
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
	self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor];
	
	cellTextView.text = countdown.message;
	cellTextView.delegate = self;
	cellTextView.scrollEnabled = NO;
	
	self.navigationItem.rightBarButtonItem.enabled = (countdown.message.length > 0);
	
	[self.tableView reloadData];
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
		[self update];
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
	CGSize size = [cellTextView sizeThatFits:CGSizeMake(cellTextView.frame.size.width, INFINITY)];
	
	if (size.height < kHeightRowLandscape)
		return kHeightRowLandscape;
	else
		return size.height;
}

- (void)update
{
	[self.tableView beginUpdates];
	{
		CGRect frame = messageCell.frame;
		messageCell.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [self rowHeight]);
		self.tableView.rowHeight = [self rowHeight];
	}
	[self.tableView endUpdates];
	
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	return NSLocalizedString(@"This message will be shown when countdown will be finished.", nil);
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString * cellIdentifier = @"CellID";
	
	if (!self.messageCell) {
		UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			cell.clipsToBounds = YES;
			cell.contentView.autoresizesSubviews = YES;
			[cell.contentView addSubview:cellTextView];
		}
		
		self.messageCell = cell;
	}
	
	return self.messageCell;
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
	/*
	 self.tableView.contentInset = UIEdgeInsetsZero;
	 self.tableView.scrollIndicatorInsets = UIEdgeInsetsZero;
	 */
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self update];
}

- (BOOL)canBecomeFirstResponder
{
	return YES;// Return YES to receive shake to undo gesture
}

@end
