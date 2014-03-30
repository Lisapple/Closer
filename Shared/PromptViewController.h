//
//  PromptViewController.h
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

#import <UIKit/UIKit.h>

@interface PromptViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray * cellsTitle;
}

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) Countdown * countdown;

@end
