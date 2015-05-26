//
//  AppDelegate.m
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "CloserAppDelegate_Pad.h"

#import "MainViewController_Pad.h"

@interface CloserAppDelegate_Pad ()
{
    AVAudioPlayer * player;
}

@end

@implementation CloserAppDelegate_Pad

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeSound)
                                                                                        categories:[NSSet set]]];
    }
    
	self.viewController = [[MainViewController_Pad alloc] initWithNibName:@"MainViewController_Pad" bundle:nil];
	UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
	navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:0.1 alpha:1.];
	navigationController.navigationBar.tintColor = [UIColor whiteColor];
	self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
	
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	NSString * identifier = (notification.userInfo)[@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSDebugLog(@"Local notification received: %@ - %@ (will play %@)", identifier, countdown.name, notification.soundName);
	
	if (countdown.type == CountdownTypeCountdown) {
		
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
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.host isEqualToString:@"countdown"]) { // closer://countdown#[identifier]
        Countdown * countdown = [Countdown countdownWithIdentifier:url.fragment];
        NSInteger index = [Countdown indexOfCountdown:countdown];
        if (index != NSNotFound) {
            [self.viewController showPageAtIndex:(index % 3) animated:NO];
        }
    }
    
    return YES;
}

// Even if iPad can be used with AppleWatch implement this method for consistency
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *replyInfo))reply
{
	NSString * identifier = userInfo[@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSString * action = userInfo[@"action"];
	if /***/ ([action isEqualToString:@"play"] && !countdown.isPaused) {
		[countdown pause];
	} else if ([action isEqualToString:@"resume"] && countdown.isPaused) {
		[countdown resume];
	} else if ([action isEqualToString:@"reset"]) {
		[countdown reset];
	} else if ([action isEqualToString:@"delete"]) {
		[Countdown removeCountdown:countdown];
	} else {
		NSLog(@"Unknown Apple Watch request with action: \"%@\"", action);
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[Countdown synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[Countdown synchronize];
}

@end
