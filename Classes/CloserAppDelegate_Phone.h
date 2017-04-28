//
//  CloserAppDelegate.h
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@import UserNotifications;
@import Fabric;

@class MainViewController_Phone;

@interface CloserAppDelegate_Phone : UIResponder <UIApplicationDelegate, WCSessionDelegate, UNUserNotificationCenterDelegate>

@property (nonatomic, strong) IBOutlet UIWindow * window;
@property (nonatomic, strong) MainViewController_Phone * mainViewController;

@end

