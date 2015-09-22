//
//  TypeViewController.h
//  Closer
//
//  Created by Maxime Leroy on 6/17/13.
//
//

#import <UIKit/UIKit.h>

@interface TypeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) IBOutlet UITableView * tableView;
@property (nonatomic, strong) Countdown * countdown;

@end
