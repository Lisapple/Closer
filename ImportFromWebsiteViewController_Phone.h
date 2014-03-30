//
//  ImportViewController.h
//  test_closer_service
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ImportFromWebsiteViewController_Phone : UIViewController <UITableViewDataSource, UITableViewDelegate>
{
	NSString * password1, * password2;
	NSArray * countdowns;
	
	NSURLConnection * connection;
	
	NSMutableArray * selectedCountdowns;
	
	@private
	NSRegularExpression * regex;
	UIAlertView * pasteAlertView, * noCountdownFoundAlertView;
	
	BOOL pushed, sended;
}

@property (nonatomic, strong) IBOutlet UITextField * hiddenTextField;
@property (nonatomic, strong) IBOutlet UILabel * instructionLabel, * passwordLabel1, * passwordLabel2, * passwordLabel3, * passwordLabel4;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicator;

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@end
