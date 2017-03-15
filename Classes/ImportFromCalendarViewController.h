//
//  ImportFromCalendarViewController.h
//  Closer
//
//  Created by Max on 09/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import EventKit;

@interface ImportFromCalendarViewController : UITableViewController <UISearchResultsUpdating>

- (IBAction)import:(id)sender;

- (void)reload;

- (void)updateUI;

@end
