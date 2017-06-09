//
//  EditAllCountdownViewController.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@class SettingsViewController;

@interface EditAllCountdownViewController : UITableViewController <UIViewControllerPreviewingDelegate>

@property (nonatomic, strong) SettingsViewController * settingsViewController;

- (void)reloadData;

@end
