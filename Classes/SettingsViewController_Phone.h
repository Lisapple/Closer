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
{
	NSObject <SettingsViewControllerDelegate> * __unsafe_unretained delegate;
	IBOutlet UITableView * tableView;
	IBOutlet UILabel * footerLabel;
	NSArray * cellTitles;
	
	Countdown * countdown;
	
	BOOL showsDeleteButton;
}

@property (nonatomic, unsafe_unretained) NSObject <SettingsViewControllerDelegate> * delegate;
@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) IBOutlet UILabel * footerLabel;

@property (nonatomic, strong) Countdown * countdown;

- (IBAction)done:(id)sender;
- (IBAction)editAllCountdowns:(id)sender;
- (IBAction)deleteAction:(id)sender;

// TODO: create PrivateMethods category
- (void)deleteCountdown;

@end


@protocol SettingsViewControllerDelegate

@optional
- (void)settingsViewControllerDidFinish:(SettingsViewController_Phone *)controller;

@end

