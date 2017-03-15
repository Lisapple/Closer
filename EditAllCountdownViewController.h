//
//  EditAllCountdownViewController.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@class SettingsViewController;

@interface EditAllCountdownViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) SettingsViewController * settingsViewController;
@property (nonatomic, assign) IBOutlet UITableView * tableView;

- (void)reloadData;

@end
