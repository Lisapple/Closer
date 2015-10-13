//
//  NameViewController.h
//  Closer
//
//  Created by Max on 3/2/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NameViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, assign) IBOutlet UITextField * cellTextField;
@property (nonatomic, assign) IBOutlet UITableView * tableView;

@property (nonatomic, strong) Countdown * countdown;

@end
