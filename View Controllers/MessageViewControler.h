//
//  MessageViewControler.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@interface MyTextView : UITextView

- (void)setUndoManager:(NSUndoManager *)undoManager;

@end


@interface MessageViewControler : UITableViewController <UITextViewDelegate>

@property (nonatomic, strong) MyTextView * textView;
@property (nonatomic, strong) Countdown * countdown;

- (IBAction)clear:(id)sender;

@end
