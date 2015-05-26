//
//  CloserAppDelegate.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CloserAppDelegate_Phone.h"
#import "MainViewController_Phone.h"

#import "Countdown.h"

#import "NSBundle+addition.h"

@interface CloserAppDelegate_Phone ()
{
    AVAudioPlayer * player;
}

@end

@implementation CloserAppDelegate_Phone

#define kLastSelectedPageIndex @"last_selected_page_index"

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeSound)
                                                                                        categories:[NSSet set]]];
    }
    
	application.applicationSupportsShakeToEdit = YES; // Enabled shake to undo
	
	/* Set the background to have a nice animation effect (black background break this effect) */
	_window.backgroundColor = [UIColor colorWithWhite:0.13 alpha:1.];
	application.statusBarStyle = 2 /* UIStatusBarStyleBlackTranslucent */;
	
	_window.rootViewController = _mainViewController;
	[_window makeKeyAndVisible];
	
	/* Retreive the last selected page index and selected it */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger index = [userDefaults integerForKey:kLastSelectedPageIndex];
	[_mainViewController showPageAtIndex:index animated:NO];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
													  object:nil queue:NSOperationQueue.currentQueue
												  usingBlock:^(NSNotification *note) {
													  /* Update the frame of the white view under the status bar */
													  UIView * statusBarView = [_window viewWithTag:4567];
													  statusBarView.frame = application.statusBarFrame;
												  }];
	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
#if TARGET_IPHONE_SIMULATOR
	NSString * stateString = @"unkown state application";
	if (application.applicationState == UIApplicationStateActive) {
		stateString = @"application active";
	} else if (application.applicationState == UIApplicationStateInactive) {
		stateString = @"application inactive";
	} else if (application.applicationState == UIApplicationStateBackground) {
		stateString = @"application background";
	}
	
	NSDebugLog(@"application:didReceiveLocalNotification: %@ with an %@.", notification.alertBody, stateString);
#endif
	
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
			alertView.tag = index; // Pass the index of the countdown
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
		
		NSDebugLog(@"fileURL: %@", fileURL);
		if (fileURL) {
#if TARGET_IPHONE_SIMULATOR // Playing sounds on simulator is still "buggy"
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ([alertView.title isEqualToString:NSLocalizedString(@"Timer finished!", nil)]
		&& buttonIndex == 1) { /* "1" for "Continue" */

		/* Start the next timer */
		Countdown * countdown = [Countdown countdownAtIndex:alertView.tag];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TimerDidContinueNotification"
															object:countdown];
	}
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([url.host isEqualToString:@"countdown"]) { // closer://countdown#[identifier]
        Countdown * countdown = [Countdown countdownWithIdentifier:url.fragment];
        NSInteger index = [Countdown indexOfCountdown:countdown];
        if (index != NSNotFound) {
            [_mainViewController showPageAtIndex:index animated:NO];
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *replyInfo))reply
{
	NSString * identifier = userInfo[@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSString * action = userInfo[@"action"];
	if /***/ ([action isEqualToString:@"pause"] && !countdown.isPaused) {
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
	reply(@{ @"result" : @"OK" });
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:_mainViewController.selectedPageIndex
					  forKey:kLastSelectedPageIndex];
	
	[_mainViewController stopUpdateTimeLabels];
	
	[Countdown synchronize];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[_mainViewController startUpdateTimeLabels];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
	/* Save the last selected page */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:[_mainViewController selectedPageIndex]
					  forKey:kLastSelectedPageIndex];
	
	[Countdown synchronize];
}

@end
