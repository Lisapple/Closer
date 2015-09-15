//
//  EditAllCountdownViewController.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SettingsViewController_Phone;

@interface EditAllCountdownViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>
{
	IBOutlet UITableView * tableView;
}

@property (nonatomic, strong) SettingsViewController_Phone * settingsViewController;

- (IBAction)moreInfo:(id)sender;

- (void)reloadData;

@end
