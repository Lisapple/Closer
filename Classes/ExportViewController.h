//
//  ExportViewController.h
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import EventKit;

@interface ExportViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView * tableView;

- (IBAction)exportAction:(id)sender;
- (void)updateUI;

@end
