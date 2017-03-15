//
//  AppDelegate.h
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import AVFoundation;
@import Fabric;

@class MainViewController_Pad;

@interface CloserAppDelegate_Pad : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet MainViewController_Pad * viewController;

@end
