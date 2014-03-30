//
//  MessageViewControler.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MyTextView : UITextView

@property (nonatomic, strong) NSUndoManager * undoManager;
	
@end

@interface MessageViewControler : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextViewDelegate>
{
	IBOutlet MyTextView * cellTextView;
	IBOutlet UITableView * tableView;
	
	UITableViewCell * messageCell;
	
	Countdown * countdown;
	
	NSUndoManager * undoManager;
}

@property (nonatomic, strong) IBOutlet UITextView * cellTextView;
@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) UITableViewCell * messageCell;

@property (nonatomic, strong) Countdown * countdown;

@property (nonatomic, strong) NSUndoManager * undoManager;

- (IBAction)clear:(id)sender;
- (CGFloat)rowHeight;
- (void)update;

@end
