//
//  AppDelegate.m
//  test_iPad
//
//  Created by Max on 28/08/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "CloserAppDelegate_Pad.h"
#import "MainViewController_Pad.h"
#import "DurationsViewController.h"

#import "Countdown+addition.h"
#import "NSString+addition.h"

@interface CloserAppDelegate_Pad ()

@property (nonatomic, strong) AVAudioPlayer * player;

@end

@implementation CloserAppDelegate_Pad

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_IPHONE_SIMULATOR
#else
	[Fabric with:@[ CrashlyticsKit ]];
#endif
	
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
	
	[Countdown buildingSpolightIndexWithCompletionHandler:nil];
	
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
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
		
		if (fileURL) {
#if TARGET_IPHONE_SIMULATOR // Playing sound into the simulator is still buggy
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

- (void)openCountdownWithIdentifier:(NSString *)identifier animated:(BOOL)animated
{
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound) {
		[self.viewController showPageAtIndex:(index % 3) animated:animated];
	}
}

- (void)showCountdownSettingsWithIdentifier:(NSString *)identifier animated:(BOOL)animated
{
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound) {
	}
}

- (void)showAddDurationForCountdownWithIdentifier:(NSString *)identifier
{
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound) {
		[self.viewController showSettingsForPageAtIndex:index animated:NO];
		SettingsViewController_Pad * controller = self.viewController.settingsViewController;
		DurationsViewController * durationController = (DurationsViewController *)[controller showSettingsType:SettingsTypeDurations animated:NO];
		[durationController showAddDurationWithAnimation:NO];
	}
}

- (BOOL)openDeeplinkURL:(NSURL *)url
{
	BOOL animated = ([UIApplication sharedApplication].applicationState == UIApplicationStateActive);
	NSString * identifier = nil;
#define URL_STRING(X) @"closer:\\/\\/countdown\\/"X
	// closer://countdown#[identifier]
	if /**/ ([url.absoluteString matchesWithPattern:URL_STRING(@"#([^\\/]+)$") firstMatch:&identifier]) { // DEPRECATED
		[self openCountdownWithIdentifier:identifier animated:animated];
		return YES;
	}
	// closer://countdown/[identifier]
	else if ([url.absoluteString matchesWithPattern:URL_STRING(@"([^\\/]+)$") firstMatch:&identifier]) {
		[self openCountdownWithIdentifier:identifier animated:animated];
		return YES;
	}
	// closer://countdown/[identifier]/settings
	else if ([url.absoluteString matchesWithPattern:URL_STRING(@"([^\\/]+)\\/settings$") firstMatch:&identifier]) {
		[self showCountdownSettingsWithIdentifier:identifier animated:animated];
		return YES;
	}
	// closer://countdown/[identifier]/settings/durations/add
	else if ([url.absoluteString matchesWithPattern:URL_STRING(@"([^\\/]+)\\/settings\\/durations\\/add$") firstMatch:&identifier]) {
		[self showAddDurationForCountdownWithIdentifier:identifier];
		return YES;
	}
#undef URL_STRING
	return NO;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler
{
	if (NSClassFromString(@"CSSearchableIndex")) {
		NSString * identifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
		[self openCountdownWithIdentifier:identifier animated:NO];
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
	[Countdown removeInvalidLocalNotifications];
	[Countdown synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[Countdown synchronize];
}

@end
