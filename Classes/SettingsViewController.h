//
//  SettingsViewController.h
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "SettingsViewController.h"
#import "Countdown.h"

typedef NS_ENUM(NSInteger, SettingsType) {
	SettingsTypeName,
	SettingsTypeDateAndTime,
	SettingsTypeMessage,
	SettingsTypeDurations,
	SettingsTypeSong,
	SettingsTypeTheme
};

@class SettingsViewController;
@protocol SettingsViewControllerDelegate

@optional
- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller;

@end

@interface SettingsViewController : UITableViewController

@property (nonatomic, weak) NSObject <SettingsViewControllerDelegate> * delegate;

@property (nonatomic, strong) Countdown * countdown;

- (UIViewController *)showSettingsType:(SettingsType)setting animated:(BOOL)animated;

@end

