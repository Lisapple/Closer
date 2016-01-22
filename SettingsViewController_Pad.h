//
//  SettingsViewController.h
//  test_iPad
//
//  Created by Max on 20/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SettingsViewController.h"

@class Countdown;
@interface SettingsViewController_Pad : UITableViewController
<UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate, SettingsControllerProtocol>

@property (nonatomic, strong) Countdown * countdown;

- (IBAction)close:(id)sender;

@end
