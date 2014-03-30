//
//  ExportViewController.h
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <EventKit/EventKit.h>

@interface ExportViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
	IBOutlet UITableView * tableView;
	
	NSArray * countdowns;
	NSMutableArray * selectedCountdowns;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

- (IBAction)export:(id)sender;

- (void)updateUI;

@end
