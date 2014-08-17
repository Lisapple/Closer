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

@implementation CloserAppDelegate_Phone


@synthesize window = _window;
@synthesize mainViewController;

#define kLastSelectedPageIndex @"last_selected_page_index"

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	application.applicationSupportsShakeToEdit = YES;// Enabled shake to undo
	
	if (TARGET_IS_IOS7_OR_LATER()) {
		_window.tintColor = [UIColor darkGrayColor];
		application.statusBarStyle = UIStatusBarStyleDefault;
		application.statusBarHidden = YES;
	} else {
		/* Set the background to have a nice animation effect (black background break this effect) */
		_window.backgroundColor = [UIColor colorWithWhite:0.13 alpha:1.];
		application.statusBarStyle = 2 /* UIStatusBarStyleBlackTranslucent */;
	}
	
	_window.rootViewController = mainViewController;
	[_window makeKeyAndVisible];
	
	/* Retreive the last slected page index and selected it */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSInteger index = [userDefaults integerForKey:kLastSelectedPageIndex];
	[mainViewController showPageAtIndex:index animated:NO];
	
	[[NSNotificationCenter defaultCenter] addObserverForName:UIDeviceOrientationDidChangeNotification
													  object:nil
													   queue:[NSOperationQueue currentQueue]
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
		
		NSLog(@"fileURL: %@", fileURL);
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

- (void)applicationWillResignActive:(UIApplication *)application
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:mainViewController.selectedPageIndex
					  forKey:kLastSelectedPageIndex];
	
	[mainViewController stopUpdateTimeLabels];
	
	[Countdown synchronize_async];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	[mainViewController startUpdateTimeLabels];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
	/* Save the last selected page */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:[mainViewController selectedPageIndex]
					  forKey:kLastSelectedPageIndex];
	
	[Countdown synchronize_async];
}

@end
