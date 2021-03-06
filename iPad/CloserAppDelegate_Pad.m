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
#import "TimerPageView.h"
#import "UserDataManager.h"

#import "Countdown+addition.h"
#import "NSString+addition.h"

@interface CloserAppDelegate_Pad ()

@property (nonatomic, strong) AVAudioPlayer * player;

@end

@implementation CloserAppDelegate_Pad

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_OS_SIMULATOR
#else
	[Fabric with:@[ CrashlyticsKit ]];
#endif
	
	if (NSSelectorFromString(@"UNUserNotificationCenter")) { // iOS 10+
		UNAuthorizationOptions options = (UNAuthorizationOptionAlert | UNAuthorizationOptionSound);
		UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
		center.delegate = self;
		[center requestAuthorizationWithOptions:options
							  completionHandler:^(BOOL granted, NSError * _Nullable error) {
								  if (error)
									  NSDebugLog(@"Error registering notification: %@", error.localizedDescription);
							  }];
	} else { // iOS 8-9
		IGNORE_DEPRECATION_BEGIN
		UIUserNotificationType type = (UIUserNotificationTypeAlert | UIUserNotificationTypeSound);
		[application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:type categories:nil]];
		IGNORE_DEPRECATION_END
	}
	
	self.window.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
	self.window.tintColor = [UIColor darkGrayColor];
	
	UINavigationController * navigationController = (UINavigationController *)self.window.rootViewController;
	self.viewController = (MainViewController_Pad *)navigationController.topViewController;
	
	navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:0.1 alpha:1.];
	navigationController.navigationBar.tintColor = [UIColor whiteColor];
	
	[Countdown updateSpotlightIndexWithCompletionHandler:nil];
	
	[[UserDataManager defaultManager] synchronize];
	
	return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	NSString * identifier = (notification.userInfo)[@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSDebugLog(@"Local notification received: %@ - %@ (will play %@)", identifier, countdown.name, notification.soundName);
	[countdown presentLocalNotification];
}

- (void)openCountdownWithIdentifier:(NSString *)identifier animated:(BOOL)animated
{
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound)
		[self.viewController showPageAtIndex:(index % 3) animated:animated];
}

- (void)showCountdownSettingsWithIdentifier:(NSString *)identifier animated:(BOOL)animated
{
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound)
		[self.viewController showSettingsForPageAtIndex:index animated:NO];
}

- (void)showAddDurationForCountdownWithIdentifier:(NSString *)identifier
{
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound) {
		[self.viewController showSettingsForPageAtIndex:index animated:NO];
		SettingsViewController * controller = self.viewController.settingsViewController;
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
	if /**/ ([url.absoluteString isMatchingWithPattern:URL_STRING(@"#([^\\/]+)$") firstMatch:&identifier]) { // DEPRECATED
		[self openCountdownWithIdentifier:identifier animated:animated];
		return YES;
	}
	// closer://countdown/[identifier]
	else if ([url.absoluteString isMatchingWithPattern:URL_STRING(@"([^\\/]+)$") firstMatch:&identifier]) {
		[self openCountdownWithIdentifier:identifier animated:animated];
		return YES;
	}
	// closer://countdown/[identifier]/settings
	else if ([url.absoluteString isMatchingWithPattern:URL_STRING(@"([^\\/]+)\\/settings$") firstMatch:&identifier]) {
		[self showCountdownSettingsWithIdentifier:identifier animated:animated];
		return YES;
	}
	// closer://countdown/[identifier]/settings/durations/add
	else if ([url.absoluteString isMatchingWithPattern:URL_STRING(@"([^\\/]+)\\/settings\\/durations\\/add$") firstMatch:&identifier]) {
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

// Even if iPad can't be used with AppleWatch implement this method for consistency
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
		NSDebugLog(@"Unknown Apple Watch request with action: \"%@\"", action);
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	[Countdown removeInvalidLocalNotifications];
	[Countdown synchronize];
	[[UserDataManager defaultManager] synchronize];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[Countdown synchronize];
	[[UserDataManager defaultManager] synchronize];
}

#pragma mark - UNUserNotificationCenterDelegate

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
	   willPresentNotification:(UNNotification *)notification
		 withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler
{
	NSString * const identifier = notification.request.identifier;
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	[countdown presentLocalNotification];
}

@end
