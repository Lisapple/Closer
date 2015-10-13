//
//  ExportToWebsiteViewController.h
//  Closer
//
//  Created by Max on 07/09/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExportToWebsiteViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSArray <Countdown *> * countdowns;

- (IBAction)done:(id)sender;

@end
