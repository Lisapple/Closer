//
//  AppDelegate.h
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

@class MainViewController_Pad;

@interface CloserAppDelegate_Pad : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) IBOutlet UIWindow *window;
@property (strong, nonatomic) IBOutlet MainViewController_Pad * viewController;

@end
