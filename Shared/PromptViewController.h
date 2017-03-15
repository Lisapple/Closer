//
//  PromptViewController.h
//  Closer
//
//  Created by Maxime Leroy on 7/3/13.
//
//

@interface PromptViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView * tableView;
@property (nonatomic, strong) Countdown * countdown;

@end
