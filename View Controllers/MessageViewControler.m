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

- (instancetype)init
{
	if ((self = [super initWithStyle:UITableViewStyleGrouped])) { }
	return self;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = NSLocalizedString(@"Message", nil);
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Clear", nil)
																			  style:UIBarButtonItemStylePlain
																			 target:self action:@selector(clear:)];
	_textView = [[MyTextView alloc] init];
	_textView.translatesAutoresizingMaskIntoConstraints = NO;
	_textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	_textView.delegate = self;
	_textView.text = _countdown.message;
	
	self.tableView.rowHeight = _textView.font.lineHeight * 5; // ~4 lines
	
	[self updateUI];
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
	[self updateUI];
	
	_textView.undoManager = _undoManager; // Overwrite the cellTextView undo manager with the controller one since [cellTextView becomeFirstResponder] set the default undo manager from cellTextView undo manager (setActionName should not working with this method).
	
	[_textView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	_countdown.message = _textView.text;
	
	_textView.undoManager = nil;
	_undoManager = nil;
}

- (void)setText:(NSString *)textString
{
	_textView.text = textString;
}

- (IBAction)clear:(id)sender
{
	if (_textView.text.length > 0) {
		[_undoManager registerUndoWithTarget:self selector:@selector(setText:) object:_textView.text];
		[_undoManager setActionName:NSLocalizedString(@"UNDO_MESSAGE_ACTION", nil)];
		
		_textView.text = nil;
		[self updateUI];
	}
}

- (void)updateUI
{
	self.navigationItem.rightBarButtonItem.enabled = (_textView.text.length > 0);
}

#pragma mark - Table view data source

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
	UITableViewCell * cell = [self.tableView dequeueReusableCellWithIdentifier:cellIdentifier];
	if (!cell) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell.contentView addSubview:_textView];
		[cell addConstraints:
		 @[ [NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeTopMargin relatedBy:NSLayoutRelationEqual
											toItem:_textView attribute:NSLayoutAttributeTopMargin multiplier:1 constant:0],
			[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeLeftMargin relatedBy:NSLayoutRelationEqual
											toItem:_textView attribute:NSLayoutAttributeLeftMargin multiplier:1 constant:0],
			[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeRightMargin relatedBy:NSLayoutRelationEqual
											toItem:_textView attribute:NSLayoutAttributeRightMargin multiplier:1 constant:0],
			[NSLayoutConstraint constraintWithItem:cell attribute:NSLayoutAttributeBottomMargin relatedBy:NSLayoutRelationEqual
											toItem:_textView attribute:NSLayoutAttributeBottomMargin multiplier:1 constant:0] ]];
	}
	return cell;
}

#pragma mark - Table view data source

- (void)textViewDidBeginEditing:(UITextView *)textView
{
	[self updateUI];
}

- (void)textViewDidChange:(UITextView *)textView
{
	[self updateUI];
}

- (BOOL)canBecomeFirstResponder
{
	return YES; // Return YES to receive shake to undo gesture
}

@end
