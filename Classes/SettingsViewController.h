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
/// User exits settings to go back to countdown pages.
- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller;

/// The user deletes the countdown from toolbar button (and has validated delete confirmation).
- (void)settingsViewController:(SettingsViewController *)controller willDeleteCountdown:(Countdown *)countdown;

@end

@interface SettingsViewController : UITableViewController

@property (nonatomic, weak) NSObject <SettingsViewControllerDelegate> * delegate;

@property (nonatomic, strong) Countdown * countdown;

- (UIViewController *)showSettingsType:(SettingsType)setting animated:(BOOL)animated;

@end

