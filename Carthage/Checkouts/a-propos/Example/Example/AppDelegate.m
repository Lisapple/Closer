//
//  AppDelegate.m
//
//  Created by Lisacintosh on 10/01/2017.
//
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	
	CGRect bounds = [UIScreen mainScreen].bounds;
	_window = [[UIWindow alloc] initWithFrame:bounds];
	_window.rootViewController = [[ViewController alloc] init];
	_window.tintColor = [UIColor purpleColor];
	[_window makeKeyAndVisible];
	
	return YES;
}

@end
