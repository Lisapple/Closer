//
//  ExportToWebsiteViewController.h
//  Closer
//
//  Created by Max on 07/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExportToWebsiteViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>
{
	NSArray * countdowns;
	
	@private
	
	NSString * password1, * password2;
	
	IBOutlet UILabel * password1Label1, * password1Label2, * password1Label3, * password1Label4;
	IBOutlet UILabel * password2Label1, * password2Label2, * password2Label3, * password2Label4;
	
	IBOutlet UITableView * tableView;
	
	IBOutlet UIActivityIndicatorView * activityIndicator;
}

@property (nonatomic, strong) NSArray * countdowns;

// Private
@property (nonatomic, strong) IBOutlet UILabel * password1Label1, * password1Label2, * password1Label3, * password1Label4;
@property (nonatomic, strong) IBOutlet UILabel * password2Label1, * password2Label2, * password2Label3, * password2Label4;

@property (nonatomic, strong) IBOutlet UITableView * tableView;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView * activityIndicator;

- (IBAction)done:(id)sender;

@end
