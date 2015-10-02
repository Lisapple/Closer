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
#import "Countdown+addition.h"

#import "NSBundle+addition.h"

@interface CloserAppDelegate_Phone ()

@property (nonatomic, strong) AVAudioPlayer * player;

@end

@implementation CloserAppDelegate_Phone

#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	if ([WCSession isSupported]) {
		WCSession * session = [WCSession defaultSession];
		session.delegate = self;
		[session activateSession];
	}
	
    if ([application respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeAlert | UIUserNotificationTypeSound)
                                                                                        categories:[NSSet set]]];
    }
    
	application.applicationSupportsShakeToEdit = YES; // Enabled shake to undo
	application.statusBarStyle = UIStatusBarStyleDefault;
	application.statusBarHidden = YES;
	
	_window.tintColor = [UIColor darkGrayColor];
	_window.rootViewController = _mainViewController;
	[_window makeKeyAndVisible];
	
	/* Retreive the last selected page index and selected it */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *identifier = [userDefaults stringForKey:kLastSelectedCountdownIdentifierKey];
	NSUInteger index = [Countdown.allCountdowns indexOfObject:[Countdown countdownWithIdentifier:identifier]];
	if (index != NSNotFound) {
		[_mainViewController showPageAtIndex:index animated:NO];
	}
	
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
		
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"COUNTDOWN_FINISHED_DEFAULT_MESSAGE", nil)
																		message:notification.alertBody
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
			[alert dismissViewControllerAnimated:YES completion:nil]; }]];
		[self.window.rootViewController presentViewController:alert animated:YES completion:nil];
		
	} else {
		/* Show an alert if needed to show an alert (to show an alert at the end of each timer or at the end of the loop of timers) */
		if (countdown.promptState == PromptStateEveryTimers
			|| (countdown.promptState == PromptStateEnd && countdown.durationIndex == (countdown.durations.count - 1))) {
			UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"TIMER_FINISHED_DEFAULT_MESSAGE", nil)
																			message:notification.alertBody
																	 preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
				// Start the next timer
				[[NSNotificationCenter defaultCenter] postNotificationName:@"TimerDidContinueNotification" object:countdown]; }]];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
				[alert dismissViewControllerAnimated:YES completion:nil]; }]];
			[self.window.rootViewController presentViewController:alert animated:YES completion:nil];
		}
	}
	
	/* Play the sound */
	if (notification.soundName) {
		
		NSURL * fileURL = nil;
		if ([notification.soundName isEqualToString:UILocalNotificationDefaultSoundName] || [notification.soundName isEqualToString:@"default"]) {
			NSString * path = [NSString stringWithFormat:@"%@/Songs/complete.caf", [NSBundle mainBundle].bundlePath];
			fileURL = [NSURL fileURLWithPath:path];
		} else {
			NSString * path = [NSString stringWithFormat:@"%@/%@", [NSBundle mainBundle].bundlePath, notification.soundName];
			fileURL = [NSURL fileURLWithPath:path];
		}
		
		NSDebugLog(@"fileURL: %@", fileURL);
		if (fileURL) {
#if TARGET_IPHONE_SIMULATOR // Playing sounds on simulator is still "buggy"
			NSDebugLog(@"Sound played: %@ (%@)", notification.soundName, fileURL);
#else
			NSError * error = nil;
			_player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL
																			error:&error];
			if (error)
				NSLog(@"Error on audio player: %@ for %@", error.localizedDescription, fileURL.path.lastPathComponent);
			
			[_player play];
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
            [_mainViewController showPageAtIndex:index animated:NO];
        }
    }
    
    return YES;
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
{
	NSString * identifier = message[@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSString * action = message[@"action"];
	
#if TARGET_IPHONE_SIMULATOR
	UIAlertController * alert = [UIAlertController alertControllerWithTitle:action message:message.description preferredStyle:UIAlertControllerStyleAlert];
	[alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) { }]];
	[self.window.rootViewController presentViewController:alert animated:YES completion:NULL];
#endif
	
	if /***/ ([action isEqualToString:@"pause"] && !countdown.isPaused) {
		[countdown pause];
	} else if ([action isEqualToString:@"resume"] && countdown.isPaused) {
		[countdown resume];
	} else if ([action isEqualToString:@"reset"]) {
		[countdown reset];
	} else if ([action isEqualToString:@"delete"]) {
		[Countdown removeCountdown:countdown];
	} else if ([action isEqualToString:@"update"]) {
		NSData * data = message[@"data"];
		if (data) {
			NSDictionary * dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
			if (dictionary) {
				if (dictionary[@"name"]) {
					countdown.name = dictionary[@"name"]; }
				if (dictionary[@"message"]) {
					countdown.name = dictionary[@"message"]; }
				if (dictionary[@"endDate"]) {
					NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
					formatter.dateStyle = NSDateFormatterMediumStyle;
					formatter.timeStyle = NSDateFormatterMediumStyle;
					countdown.endDate = [formatter dateFromString:dictionary[@"endDate"]]; }
				if (dictionary[@"durations"]) {
					for (int i = 0; i < countdown.durations.count; ++i) {
						[countdown removeDurationAtIndex:i];
					}
					[countdown addDurations:dictionary[@"durations"]];
				}
				if (dictionary[@"durationIndex"]) {
					countdown.durationIndex = dictionary[@"durationIndex"]; }
			}
		} else {
			NSString * identifier = message[@"lastSelectedCountdownIdentifier"];
			if (identifier && [Countdown countdownWithIdentifier:identifier] != nil) {
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				[userDefaults setObject:identifier forKey:kLastSelectedCountdownIdentifierKey];
			}
		}
	} else {
		replyHandler(@{ @"error" : [NSString stringWithFormat:@"Unknown Apple Watch request with action: \"%@\"", action] });
		return ;
	}
	replyHandler(@{ @"result" : @"OK" });
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setInteger:_mainViewController.selectedPageIndex
					  forKey:kLastSelectedPageIndex];
	
	[_mainViewController stopUpdateTimeLabels];
	
	[Countdown removeInvalidLocalNotifications];
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
	[userDefaults setInteger:_mainViewController.selectedPageIndex
					  forKey:kLastSelectedPageIndex];
	
	[Countdown synchronize];
}

@end
