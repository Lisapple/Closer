//
//  PageThemeViewController.h
//  Closer
//
//  Created by Max on 11/04/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Countdown;
@class PageThemeTableViewCell;

@interface PageThemeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	UITableView * tableView;
	
	Countdown * countdown;
	
	@private
	UITableViewCell * checkedCell;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) Countdown * countdown;

@end
