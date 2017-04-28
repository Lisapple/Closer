//
//  CloserAppDelegate.m
//  Closer
//
//  Created by Max on 1/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import "CloserAppDelegate_Phone.h"
#import "MainViewController_Phone.h"
#import "DurationsViewController.h"
#import "TimerPageView.h"

#import "Countdown+addition.h"
#import "NSBundle+addition.h"
#import "NSString+addition.h"
#import "Countdown+addition.h"

@interface CloserAppDelegate_Phone ()

@end

@implementation CloserAppDelegate_Phone

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if TARGET_IPHONE_SIMULATOR
#else
	[Fabric with:@[ CrashlyticsKit ]];
#endif
	
	if ([WCSession isSupported]) {
		WCSession * session = [WCSession defaultSession];
		session.delegate = self;
		[session activateSession];
	}
	
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
	
	application.applicationSupportsShakeToEdit = YES; // Enabled shake to undo
	application.statusBarStyle = UIStatusBarStyleDefault;
	application.statusBarHidden = YES;
	
	self.window.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1];
	self.window.tintColor = [UIColor darkGrayColor];
	
	self.mainViewController = (MainViewController_Phone *)self.window.rootViewController;
	
	/* Retreive the last selected page index and selected it */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	NSString * const identifier = [userDefaults stringForKey:kLastSelectedCountdownIdentifierKey];
	const NSUInteger index = [Countdown.allCountdowns indexOfObject:[Countdown countdownWithIdentifier:identifier]];
	if (index != NSNotFound)
		[_mainViewController showPageAtIndex:index animated:NO];
	
	[Countdown buildingSpolightIndexWithCompletionHandler:nil];
	
	return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	Countdown * const countdown = [Countdown countdownAtIndex:_mainViewController.currentPageIndex];
	[userDefaults setObject:countdown.identifier forKey:kLastSelectedCountdownIdentifierKey];
	[userDefaults synchronize];
	
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
	[Countdown synchronize];
	
	/* Save the last selected page */
	NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
	Countdown * const countdown = [Countdown countdownAtIndex:_mainViewController.currentPageIndex];
	[userDefaults setObject:countdown.identifier forKey:kLastSelectedCountdownIdentifierKey];
	[userDefaults synchronize];
}

#pragma mark - Local Notification

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	NSString * const identifier = (notification.userInfo)[@"identifier"];
	Countdown * const countdown = [Countdown countdownWithIdentifier:identifier];
	NSDebugLog(@"Local notification received: %@ - %@ (will play %@)", identifier, countdown.name, notification.soundName);
	[countdown presentLocalNotification];
}

#pragma mark - Deeplink

- (void)openCountdownWithIdentifier:(NSString *)identifier animated:(BOOL)animated
{
	Countdown * const countdown = [Countdown countdownWithIdentifier:identifier];
	const NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound)
		[_mainViewController showPageAtIndex:index animated:animated];
}

- (void)showCountdownSettingsWithIdentifier:(NSString *)identifier animated:(BOOL)animated
{
	Countdown * const countdown = [Countdown countdownWithIdentifier:identifier];
	const NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound)
		[_mainViewController showSettingsForPageAtIndex:index animated:animated];
}

- (void)showAddDurationForCountdownWithIdentifier:(NSString *)identifier
{
	Countdown * const countdown = [Countdown countdownWithIdentifier:identifier];
	const NSInteger index = [Countdown indexOfCountdown:countdown];
	if (index != NSNotFound) {
		[_mainViewController showSettingsForPageAtIndex:index animated:YES];
		SettingsViewController * controller = _mainViewController.settingsViewController;
		DurationsViewController * durationController = (DurationsViewController *)[controller showSettingsType:SettingsTypeDurations animated:NO];
		[durationController showAddDurationWithAnimation:NO];
	}
}

- (BOOL)openDeeplinkURL:(NSURL *)url
{
	const BOOL animated = ([UIApplication sharedApplication].applicationState == UIApplicationStateActive);
	NSString * identifier = nil;
#define URL_STRING(X) @"^closer:\\/\\/countdown\\/"X
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

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString*, id> *)options // iOS 9+
{
	return [self openDeeplinkURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation // iOS 8
{
	return [self openDeeplinkURL:url];
}

#pragma mark - Shortcut

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler
{
	Countdown * countdown = nil;
	if /**/ ([shortcutItem.type isEqualToString:@"com.lisacintosh.closer.create.countdown"]) {
		countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.name = NSLocalizedString(@"New Countdown", nil);
	}
	else if ([shortcutItem.type isEqualToString:@"com.lisacintosh.closer.create.timer"]) {
		countdown = [[Countdown alloc] initWithIdentifier:nil];
		countdown.type = CountdownTypeTimer;
		countdown.name = NSLocalizedString(@"New Timer", nil);
	}
	
	if (countdown) {
		[Countdown addCountdown:countdown];
		const NSInteger index = [Countdown indexOfCountdown:countdown];
		[_mainViewController showPageAtIndex:index animated:NO];
		[_mainViewController showSettingsForPageAtIndex:index animated:NO];
		completionHandler(YES);
	} else {
		completionHandler(NO);
	}
}

#pragma mark - Spotlight

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *))restorationHandler
{
	if (NSClassFromString(@"CSSearchableIndex")) {
		NSString * const identifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
		[self openCountdownWithIdentifier:identifier animated:NO];
	}
	return YES;
}

#pragma mark - WCSessionDelegate

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error { }

- (void)sessionDidBecomeInactive:(WCSession *)session { }

- (void)sessionDidDeactivate:(WCSession *)session { }

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message
   replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler
{
	NSString * const identifier = message[@"identifier"];
	Countdown * countdown = [Countdown countdownWithIdentifier:identifier];
	NSString * const action = message[@"action"];
	
#if TARGET_IPHONE_SIMULATOR
	dispatch_async(dispatch_get_main_queue(), ^{
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:action message:message.description preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) { }]];
		[self.window.rootViewController presentViewController:alert animated:YES completion:NULL];
	});
#endif
	
	if /****/ ([action isEqualToString:@"pause"] && !countdown.isPaused) {
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
				if (!countdown) {
					countdown = [[Countdown alloc] initWithIdentifier:nil];
					[Countdown addCountdown:countdown];
				}
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
					for (int i = 0; i < countdown.durations.count; ++i)
						[countdown removeDurationAtIndex:i];
					
					[countdown addDurations:dictionary[@"durations"] withNames:nil]; // @TODO: support durations names on Apple Watch
				}
				if (dictionary[@"durationIndex"]) {
					countdown.durationIndex = [dictionary[@"durationIndex"] integerValue]; }
			}
		} else {
			NSString * const identifier = message[@"lastSelectedCountdownIdentifier"];
			Countdown * const countdown = [Countdown countdownWithIdentifier:identifier];
			if (identifier && countdown != nil) {
				NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
				[userDefaults setObject:identifier forKey:kLastSelectedCountdownIdentifierKey];
				[_mainViewController selectPageWithCountdown:countdown animated:NO];
			}
		}
	} else {
		replyHandler(@{ @"error" : [NSString stringWithFormat:@"Unknown Apple Watch request with action: \"%@\"", action] });
		return ;
	}
	replyHandler(@{ @"result" : @"OK" });
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
