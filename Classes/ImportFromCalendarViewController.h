//
//  ImportFromCalendarViewController.h
//  Closer
//
//  Created by Max on 09/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface ImportFromCalendarViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	IBOutlet UITableView * tableView;
	
	UITableViewCell * checkedCell;
	
	NSMutableArray * calendars, * calendarsEvents;
	NSMutableArray * selectedEvents;
	
	EKEventStore * eventStore;
	
	NSInteger numberOfEvents;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicatorView;

- (IBAction)import:(id)sender;

- (void)reload;

- (void)updateUI;

@end
