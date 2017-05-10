//
//  DatePickerViewController.h
//  Closer
//
//  Created by Max on 1/16/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//



@class Countdown;
@class MyDatePicker;

@interface DatePickerViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) IBOutlet UITableView * tableView;
@property (nonatomic, assign) IBOutlet UIDatePicker * datePicker;

@property (nonatomic, strong) NSDate * date;
@property (nonatomic, strong) Countdown * countdown;

- (IBAction)datePickerDidChange:(id)sender;

- (void)reloadData;

- (void)updateWithOrientation:(UIInterfaceOrientation)orientation;

@end
