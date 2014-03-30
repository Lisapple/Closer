//
//  AppDelegate.m
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "CloserAppDelegate_Pad.h"

#import "MainViewController_Pad.h"

@implementation CloserAppDelegate_Pad

@synthesize window = _window;
@synthesize viewController = _viewController;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.viewController = [[MainViewController_Pad alloc] initWithNibName:@"MainViewController_Pad" bundle:nil];
	self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	NSString * identifier = [notification.userInfo objectForKey:@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSDebugLog(@"Local notification received: %@ - %@ (will play %@)", identifier, countdown.name, notification.soundName);
	
	if (countdown.type == CountdownTypeDefault) {
		
		UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Countdown finished!", nil)
															 message:notification.alertBody
															delegate:nil
												   cancelButtonTitle:NSLocalizedString(@"OK", nil) // @TODO: Add a "Show" button to go to the settings of the countdown
												   otherButtonTitles:nil];
		[alertView show];
		
	} else {
		/* Show an alert if needed to show an alert (to show an alert at the end of each timer or at the end of the loop of timers) */
		if (countdown.promptState == PromptStateEveryTimers
			|| (countdown.promptState == PromptStateEnd && countdown.durationIndex == (countdown.durations.count - 1))) {
			UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Timer finished!", nil)
																 message:notification.alertBody
																delegate:self
													   cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
													   otherButtonTitles:NSLocalizedString(@"Continue", nil), nil];
			NSInteger index = [Countdown indexOfCountdown:countdown];
			alertView.tag = index;
			[alertView show];
		}
	}
	
	/* Play the sound */
	if (notification.soundName) {
		
		NSURL * fileURL = nil;
		if ([notification.soundName isEqualToString:UILocalNotificationDefaultSoundName] || [notification.soundName isEqualToString:@"default"]) {
			NSString * path = [NSString stringWithFormat:@"%@/Songs/complete.caf", [[NSBundle mainBundle] bundlePath]];
			fileURL = [NSURL fileURLWithPath:path];
		} else {
			NSString * path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], notification.soundName];
			fileURL = [NSURL fileURLWithPath:path];
		}
		
		if (fileURL) {
#if TARGET_IPHONE_SIMULATOR // Playing sound into the simulator is still buggy
			NSDebugLog(@"Sound played: %@ (%@)", notification.soundName, fileURL);
#else
			NSError * error = nil;
			player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
															error:&error];
			if (error)
				NSLog(@"Error on audio player: %@ for %@", error.localizedDescription, fileURL.path.lastPathComponent);
			
			[player play];
#endif
		}
	}
	/*
	 UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"Closer & Closer"
	 message:notification.alertBody
	 delegate:nil
	 cancelButtonTitle:NSLocalizedString(@"OK", nil)
	 otherButtonTitles:nil];
	 [alertView show];
	 
	 if (notification.soundName) {
	 
	 NSURL * fileURL = nil;
	 
	 if ([notification.soundName isEqualToString:UILocalNotificationDefaultSoundName] || [notification.soundName isEqualToString:@"default"]) {
	 NSString * path = [NSString stringWithFormat:@"%@/Songs/complete.caf", [[NSBundle mainBundle] bundlePath]];
	 fileURL = [NSURL fileURLWithPath:path];
	 } else {
	 NSString * path = [NSString stringWithFormat:@"%@/%@", [[NSBundle mainBundle] bundlePath], notification.soundName];
	 fileURL = [NSURL fileURLWithPath:path];
	 }
	 
	 if (fileURL) {
	 AVAudioPlayer * player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
	 [player prepareToPlay];
	 [player play];
	 }
	 }
	 */
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

@end
