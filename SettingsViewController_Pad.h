//
//  SettingsViewController.h
//  test_iPad
//
//  Created by Max on 20/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Countdown;
@interface SettingsViewController_Pad : UIViewController <UITableViewDelegate, UITableViewDataSource, UINavigationControllerDelegate>
{
	IBOutlet UITableView * tableView;
	Countdown * countdown;
	
	@private
	NSArray * cellTitles;
	NSMutableArray * _viewControllers;
}

@property (nonatomic, strong) Countdown * countdown;

- (IBAction)close:(id)sender;

@end
