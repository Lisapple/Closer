//
//  DurationsViewController.h
//  Closer
//
//  Created by Maxime Leroy on 6/18/13.
//
//

@interface DurationsViewController : UITableViewController

@property (nonatomic, strong) IBOutlet Countdown * countdown;

- (void)showAddDurationWithAnimation:(BOOL)animated;

@end
