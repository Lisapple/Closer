//
//  ImportViewController.h
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@interface ImportFromWebsiteViewController_Phone : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITextField * hiddenTextField;
@property (nonatomic, strong) IBOutlet UILabel * instructionLabel, * passwordLabel1, * passwordLabel2, * passwordLabel3, * passwordLabel4;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicator;

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@end
