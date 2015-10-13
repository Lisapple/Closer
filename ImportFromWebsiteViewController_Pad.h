//
//  ImportViewController.h
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportFromWebsiteViewController_Pad : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) IBOutlet UITextField * hiddenTextField1, * hiddenTextField2;

@property (nonatomic, strong) IBOutlet UIView * contentView1, * contentView2;
@property (nonatomic, strong) IBOutlet UILabel * password1Label1, * password1Label2, * password1Label3, * password1Label4;
@property (nonatomic, strong) IBOutlet UILabel * password2Label1, * password2Label2, * password2Label3, * password2Label4;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicator;

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@end
