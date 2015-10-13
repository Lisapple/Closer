//
//  FlipsideViewController.h
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SettingsViewControllerDelegate;

@class Countdown;

@interface SettingsViewController_Phone : UIViewController <UITableViewDelegate, UITableViewDataSource, UIActionSheetDelegate>

@property (nonatomic, unsafe_unretained) NSObject <SettingsViewControllerDelegate> * delegate;
@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UILabel * footerLabel;

@property (nonatomic, strong) Countdown * countdown;

@end


@protocol SettingsViewControllerDelegate

@optional
- (void)settingsViewControllerDidFinish:(SettingsViewController_Phone *)controller;

@end

