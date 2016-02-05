//
//  MessageViewControler.m
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "MessageViewControler.h"

@interface MyTextView ()
{
	NSUndoManager * _undoManager;
}

@end

@implementation MyTextView

- (NSUndoManager *)undoManager
{
	return _undoManager;
}

- (void)setUndoManager:(NSUndoManager *)undoManager
{
	_undoManager = undoManager;
}

@end


@interface MessageViewControler ()
{
	NSUndoManager * _undoManager;
}
@end

@implementation MessageViewControler

const CGFloat kHeightRowLandscape = 60.;
const CGFloat kHeightRowPortrait = 120.;

const CGFloat kKeyboardHeightPortrait = 216.;
const CGFloat kKeyboardHeightLandscape = 162.;

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Message", nil);
	self.tableView.backgroundColor = [UIColor groupTableViewBackgroundColor]; // Doesn't work into IB (maybe a Xcode 7 bug)
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil)
																			  style:UIBarButtonItemStylePlain
																			 target:self action:@selector(clear:)];
	self.navigationItem.rightBarButtonItem.enabled = (_countdown.message.length > 0);
	
	_cellTextView.text = _countdown.message;
	_cellTextView.delegate = self;
	_cellTextView.scrollEnabled = NO;
	
	[self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	_undoManager = [[NSUndoManager alloc] init];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[self update];
	
	_cellTextView.undoManager = _undoManager; // Overwrite the cellTextView undo manager with the controller one since [cellTextView becomeFirstResponder] set the default undo manager from cellTextView undo manager (setActionName should not working with this method).
	
	[_cellTextView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
	_countdown.message = _cellTextView.text;
	
	_cellTextView.undoManager = nil;
	_undoManager = nil;
	
	[super viewWillDisappear:animated];
}

- (void)setText:(NSString *)textString
{
	_cellTextView.text = textString;
}

- (IBAction)clear:(id)sender
{
	if (_cellTextView.text.length > 0) {
		[_undoManager registerUndoWithTarget:self selector:@selector(setText:) object:_cellTextView.text];
		[_undoManager setActionName:NSLocalizedString(@"UNDO_MESSAGE_ACTION", nil)];
		
		_cellTextView.text = @"";
		[self update];
	}
}

#pragma mark - Table view data source

- (CGFloat)keyboardHeight
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	
	if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight)
		return kKeyboardHeightLandscape;
	
	return kKeyboardHeightPortrait;
}

- (CGFloat)rowHeight
{
	CGSize size = [_cellTextView sizeThatFits:CGSizeMake(_cellTextView.frame.size.width, INFINITY)];
	
	if (size.height < kHeightRowLandscape)
		return kHeightRowLandscape;
	else
		return size.height;
}

- (void)update
{
	[self.tableView beginUpdates];
	{
		CGRect frame = _messageCell.frame;
		_messageCell.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, [self rowHeight]);
		self.tableView.rowHeight = [self rowHeight];
	}
	[self.tableView endUpdates];
	
	/* Update Clear button enable */
	self.navigationItem.rightBarButtonItem.enabled = (_cellTextView.text.length > 0);
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
		if (!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			
			cell.clipsToBounds = YES;
			cell.contentView.autoresizesSubviews = YES;
			[cell.contentView addSubview:_cellTextView];
		}
		
		self.messageCell = cell;
	}
	
	return self.messageCell;
}

#pragma mark - Table view data source

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self update];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self update];
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
