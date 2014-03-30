//
//  EditAllCountdownViewController.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingsViewController_Phone;

@interface EditAllCountdownViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>
{
	IBOutlet UITableView * tableView;
	NSArray * countdowns;
	
	SettingsViewController_Phone * settingsViewController;
}

@property (nonatomic, strong) SettingsViewController_Phone * settingsViewController;

- (void)reloadData;

@end
