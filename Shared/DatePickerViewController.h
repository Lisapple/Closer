//
//  DatePickerViewController.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Countdown;
@class MyDatePicker;

@interface DatePickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView * tableView;
	IBOutlet MyDatePicker * datePicker;
	
	NSDate * date;
	BOOL hasTimeDate;
	Countdown * countdown;
	
	NSUndoManager * undoManager;
	
	@private
	NSTimer * updateDatePickerTimer;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet MyDatePicker * datePicker;

@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) Countdown * countdown;

@property (nonatomic, strong) NSUndoManager * undoManager;

/*
- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;
*/

- (IBAction)datePickerDidChange:(id)sender;

- (void)reloadData;

- (void)updateWithOrientation:(UIInterfaceOrientation)orientation;

@end
