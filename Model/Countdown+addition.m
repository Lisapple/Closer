//
//  Countdown+Countdown_addition.m
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "TimerPageView.h"

#import "Countdown+addition.h"
#import "NSBundle+addition.h"
#import "NSDate+addition.h"
#import "NSMutableAttributedString+addition.h"

static AVAudioPlayer * __player = nil;

@implementation Countdown (LocalNotification)

+ (void)removeInvalidLocalNotifications
{
	if (NSSelectorFromString(@"UNUserNotificationCenter")) { // iOS 10+
		UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
		[center getPendingNotificationRequestsWithCompletionHandler:^(NSArray<UNNotificationRequest *> * requests) {
			NSMutableArray * invalidIdentifiers = [[requests valueForKey:NSStringFromSelector(@selector(identifier))] mutableCopy];
			for (Countdown * countdown in [Countdown allCountdowns]) {
				if (countdown.endDate) // Countdown is valid
					[invalidIdentifiers removeObject:countdown.identifier];
			}
			[center removePendingNotificationRequestsWithIdentifiers:invalidIdentifiers];
		}];
	} else { // iOS 8-9
IGNORE_DEPRECATION_BEGIN
		NSArray * allLocalNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
		for (UILocalNotification * localNotif in allLocalNotifications) {
			NSString * anIdentifier = localNotif.userInfo[@"identifier"];
			Countdown * countdown = [Countdown countdownWithIdentifier:anIdentifier];
			if (!countdown || ![countdown.endDate isEqualToDate:localNotif.fireDate])
				[[UIApplication sharedApplication] cancelLocalNotification:localNotif];
		}
IGNORE_DEPRECATION_END
	}
}

IGNORE_DEPRECATION_BEGIN
- (UILocalNotification *)localNotification
{
	NSArray <UILocalNotification *> * notifications = [UIApplication sharedApplication].scheduledLocalNotifications;
	for (UILocalNotification * notification in notifications) {
		NSString * anIdentifier = notification.userInfo[@"identifier"];
		if ([anIdentifier isEqualToString:self.identifier])
			return notification;
	}
	
	return nil;
}

- (UILocalNotification *)createLocalNotification
{
	NSDebugLog(@"Create new local notification for countdown : %@ => %@", self.name, self.endDate.localizedDescription);
	
	UILocalNotification * notification = [[UILocalNotification alloc] init];
	notification.timeZone = [NSTimeZone localTimeZone];
	notification.userInfo = @{ @"identifier": self.identifier };
	notification.fireDate = self.endDate;
	notification.alertBody = self.alertBody;
	
	notification.repeatInterval = 0;
	notification.hasAction = YES;
	
	if ([self.songID isEqualToString:@"-1"]) { // Don't play any sound ("-1" means "none")
		
	} else if ([self.songID isEqualToString:CountdownDefaultSoundName]) { // Play default sound
		notification.soundName = UILocalNotificationDefaultSoundName;
		
	} else { // Play other sound from Songs folder
		NSString * songPath = [NSString stringWithFormat:@"Songs/%@", [[NSBundle mainBundle] filenameForSongWithID:self.songID]];
		notification.soundName = songPath;
	}
	
	/* localNotif.userInfo => don't change userInfo, it alrealdy contains identifier */
	NSDebugLog(@"Update local notification: (%@ %@)", notification.fireDate, notification.alertBody);
	
	return notification;
}
IGNORE_DEPRECATION_END

- (nullable NSString *)soundPath
{
	NSString * path = [NSBundle mainBundle].bundlePath;
	if /**/ ([self.songID isEqualToString:@"-1"])
		return nil;
	else if ([self.songID isEqualToString:CountdownDefaultSoundName])
		path = [path stringByAppendingString:@"/Songs/complete.caf"];
	else
		path = [path stringByAppendingFormat:@"/Songs/%@", [[NSBundle mainBundle] filenameForSongWithID:self.songID]];
	
	return path;
}

- (NSString *)alertBody
{
	NSString * messageString = self.message;
	if (!self.message || [self.message isEqualToString:@""]) { // If no message, show the default message
		if (self.type == CountdownTypeTimer) {
			if (self.name) // If name was set, add it to default message
				messageString = [NSString localizedUserNotificationStringForKey:@"TIMER_FINISHED_MESSAGE %@" arguments:@[ self.name ]];
			else // Else if wasn't set, just show the default message
				messageString = [NSString localizedUserNotificationStringForKey:@"TIMER_FINISHED_DEFAULT_MESSAGE" arguments:nil];
		} else {
			if (self.name)
				messageString = [NSString localizedUserNotificationStringForKey:@"COUNTDOWN_FINISHED_MESSAGE %@" arguments:@[ self.name ]];
			else
				messageString = [NSString localizedUserNotificationStringForKey:@"COUNTDOWN_FINISHED_DEFAULT_MESSAGE" arguments:nil];
		}
	}
	return messageString;
}

- (UNNotificationContent *)notificationContent
{
	UNMutableNotificationContent * content = [[UNMutableNotificationContent alloc] init];
	content.title = @"Closer & Closer";
	content.body = self.alertBody;
	
	if ([self.songID isEqualToString:@"-1"])
		{ } // Don't play any sound
	else if ([self.songID isEqualToString:CountdownDefaultSoundName])
		content.sound = [UNNotificationSound defaultSound];
	else { // Play other sound from Songs folder
		content.sound = [UNNotificationSound soundNamed:self.soundPath];
	}
	
	/* localNotif.userInfo => don't change userInfo, it alrealdy contains identifier */
	//NSDebugLog(@"Update local notification: (%@ %@)", notification.fireDate, notification.alertBody);
	
	return content;
}

- (void)updateLocalNotification
{
	if (self.isActive) {
		dispatch_async(dispatch_get_main_queue(), ^{
			[self removeLocalNotification];
			
			if (self.endDate && self.endDate.timeIntervalSinceNow > 0.) {
				
				if (NSSelectorFromString(@"UNUserNotificationCenter")) { // iOS 10+
					NSCalendarUnit units = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute);
					if (self.type == CountdownTypeTimer)
						units |= NSCalendarUnitSecond;
					
					NSDateComponents * const components = [[NSCalendar currentCalendar] components:units fromDate:self.endDate];
					UNCalendarNotificationTrigger * trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];
					UNNotificationRequest * request = [UNNotificationRequest requestWithIdentifier:self.identifier
																						   content:self.notificationContent
																						   trigger:trigger];
					
					UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
					[center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
						if (error)
							NSDebugLog(@"Error registering local notification: %@", error.localizedDescription);
					}];
					
				} else { // iOS 8-9
IGNORE_DEPRECATION_BEGIN
					UILocalNotification * notification = [self createLocalNotification];
					[[UIApplication sharedApplication] scheduleLocalNotification:notification];
IGNORE_DEPRECATION_END
				}
			}
			// Send a notification from the countdown/timer
			[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidUpdateNotification
																object:self];
		});
	}
}

- (void)removeLocalNotification
{
	if (NSSelectorFromString(@"UNUserNotificationCenter")) { // iOS 10+
		UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
		[center removePendingNotificationRequestsWithIdentifiers:@[ self.identifier ]];
		
	} else { // iOS 8-9
IGNORE_DEPRECATION_BEGIN
		UILocalNotification * notification = [self localNotification];
		if (notification)
			[[UIApplication sharedApplication] cancelLocalNotification:notification];
IGNORE_DEPRECATION_END
	}
}

- (void)presentLocalNotification
{
	UIViewController * controller = UIApplication.sharedApplication.keyWindow.rootViewController;
	
	if (self.type == CountdownTypeCountdown) {
		
		UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"COUNTDOWN_FINISHED_DEFAULT_MESSAGE", nil)
																		message:self.alertBody
																 preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"generic.ok", nil) style:UIAlertActionStyleDefault handler:nil]];
		[controller presentViewController:alert animated:YES completion:nil];
		
	} else {
		/* Show an alert if needed to show an alert (to show an alert at the end of each timer or at the end of the loop of timers) */
		if (self.promptState == PromptStateEveryTimers
			|| (self.promptState == PromptStateEnd && self.durationIndex == (self.durations.count - 1))) {
			UIAlertController * alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"TIMER_FINISHED_DEFAULT_MESSAGE", nil)
																			message:self.alertBody
																	 preferredStyle:UIAlertControllerStyleAlert];
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil) style:UIAlertActionStyleDefault
													handler:^(UIAlertAction * action)
							  { [[NSNotificationCenter defaultCenter] postNotificationName:TimerDidContinueNotification object:self]; }]]; // Start the next timer
			[alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil]];
			[controller presentViewController:alert animated:YES completion:nil];
		}
	}
	
	// Play the sound
	NSString * const path = self.soundPath;
	if (path) {
		NSURL * const fileURL = [NSURL fileURLWithPath:path];
		if (fileURL) {
#if TARGET_IPHONE_SIMULATOR
			// Playing sounds on simulator is still "buggy"
#else
			NSError * error = nil;
			__player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
			if (error)
				NSLog(@"Error on audio player: %@ for %@", error.localizedDescription, fileURL.path.lastPathComponent);
			
			[__player play];
#endif
		}
	}
}

@end


@implementation Countdown (Event)

+ (Countdown *)countdownWithEvent:(EKEvent *)event
{
	Countdown * countdown = [[Countdown alloc] initWithIdentifier:nil];
	countdown.name = event.title;
	countdown.endDate = event.startDate;
	countdown.message = event.notes;
	return countdown;
}

@end


@implementation Countdown (Spotlight)

+ (void)updateSpotlightIndexWithCompletionHandler:(void (^)(NSError * error))completionHandler
{
	if (NSClassFromString(@"CSSearchableIndex")) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableArray <CSSearchableItem *> * searchableItems = [[NSMutableArray alloc] initWithCapacity:self.allCountdowns.count];
			for (Countdown * countdown in self.allCountdowns) {
				if (countdown.type == CountdownTypeCountdown) {
					CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];
					attributeSet.title = countdown.name;
					attributeSet.relatedUniqueIdentifier = countdown.identifier;
					attributeSet.keywords = @[ countdown.name, countdown.message ];
					
					NSString * const endDescription = [NSString stringWithFormat:@"%@ - %@", countdown.endDate.naturalDateString, countdown.message];
					attributeSet.contentDescription = (countdown.endDate) ? endDescription : countdown.message;
					[searchableItems addObject:[[CSSearchableItem alloc] initWithUniqueIdentifier:countdown.identifier
																				 domainIdentifier:@"countdown"
																					 attributeSet:attributeSet]];
					NSUserActivity * activity = [[NSUserActivity alloc] initWithActivityType:@"com.lisacintosh.closer.show-countdown"];
					activity.contentAttributeSet = attributeSet;
				}
			}
			[[CSSearchableIndex defaultSearchableIndex] indexSearchableItems:searchableItems completionHandler:completionHandler];
		});
	}
}

@end


@implementation Countdown (Name)

+ (NSString *)proposedNameForType:(CountdownType)type
{
	NSString * name = (type == CountdownTypeTimer) ? NSLocalizedString(@"New Timer", nil) : NSLocalizedString(@"New Countdown", nil);
	const NSArray * names = [[Countdown allCountdowns] valueForKeyPath:@"name"];
	int index = 2;
	while (1) {
		if (![names containsObject:name])
			return name;
		
		if (type == CountdownTypeTimer)
			name = [NSString stringWithFormat:NSLocalizedString(@"New Timer %i", nil), index];
		else
			name = [NSString stringWithFormat:NSLocalizedString(@"New Countdown %i", nil), index];
		++index;
	}
}

- (NSString * _Nullable)nextDurationName
{
	NSInteger nextIndex = self.durationIndex + 1;
	if (nextIndex < self.durations.count) {
		NSString * nextName = self.names[nextIndex];
		if (nextName.length > 0)
			return nextName;
	}
	return nil;
}

- (NSAttributedString *)attributedName
{
	UIColor * textColor = [UIColor textColorForStyle:self.style];
	UIFont * font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
	NSMutableParagraphStyle * paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.alignment = NSTextAlignmentCenter;
	paragraphStyle.paragraphSpacing = -2.5;
	NSDictionary * attributes = @{ NSForegroundColorAttributeName : textColor,
								   NSParagraphStyleAttributeName : paragraphStyle,
								   NSFontAttributeName : font };
	NSMutableAttributedString * string = [[NSMutableAttributedString alloc] initWithString:self.name
																				attributes:attributes];
	
	NSMutableDictionary * detailsAttrs = attributes.mutableCopy;
	detailsAttrs[NSForegroundColorAttributeName] = [textColor colorWithAlphaComponent:0.5];
	
	NSInteger nextIndex = (self.durationIndex ?: 0) + 1;
	if (self.promptState == PromptStateNone)
		nextIndex %= (self.durations.count ?: 1);
	
	if (self.promptState != PromptStateEveryTimers && nextIndex < self.durations.count) { // Show next duration details under title
		if (self.currentName.length > 0) {
			NSString * name = [NSString stringWithFormat:@" %@", self.currentName];
			[string appendString:name attributes:detailsAttrs];
		}
		NSString * subtitle = [NSString stringWithFormat:@"\n%@%@", NSLocalizedString(@"Next: ", nil),
							   self.nextDurationName ?: [self descriptionOfDurationAtIndex:nextIndex]];
		NSMutableDictionary * subtitleAttrs = detailsAttrs.mutableCopy;
		subtitleAttrs[NSFontAttributeName] = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
		[string appendString:subtitle attributes:subtitleAttrs];
		
	} else if (self.currentName.length > 0) { // Only show current duration name under title
		NSString * name = [NSString stringWithFormat:@"\n%@", self.currentName];
		[string appendString:name attributes:detailsAttrs];
	}
	return string;
}

@end


@implementation Countdown (Answers)

+ (void)tagInsert
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"insert-countdown"
				   customAttributes:nil];
#endif
}

+ (void)tagChangeType:(CountdownType)type
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"change-countdown-type"
				   customAttributes:@{ @"new type" : (type == CountdownTypeTimer) ? @"timer" : @"countdown" }];
#endif
}

+ (void)tagChangeName
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"change-countdown-name"
				   customAttributes:nil];
#endif
}

+ (void)tagChangeMessage
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"change-countdown-message"
				   customAttributes:nil];
#endif
}

+ (void)tagEndDate:(NSDate *)date
{
#if ANALYTICS_ENABLED
	NSDictionary * attrs = nil;
	if (date.localizedDescription) {
		attrs = @{ @"end date" : date.localizedDescription };
	}
	[Answers logCustomEventWithName:@"change-countdown-end-date"
				   customAttributes:attrs];
#endif
}

+ (void)tagChangeDuration
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"change-countdown-duration"
				   customAttributes:@{ }];
#endif
}

+ (void)tagChangeTheme:(CountdownStyle)style
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"change-countdown-theme"
				   customAttributes:@{ @"theme" : CountdownStyleDescription(style) }];
#endif
}

+ (void)tagDelete
{
#if ANALYTICS_ENABLED
	[Answers logCustomEventWithName:@"delete-countdown"
				   customAttributes:nil];
#endif
}

@end


@implementation Countdown (Thumbnail)

+ (UIImage *)thumbnailForStyle:(CountdownStyle)style
{
	const CGFloat border = (style == CountdownStyleDay) ? 1 : 0;
	return [self.class imageWithBackgroundColor:[UIColor backgroundColorForStyle:style]
								foregroundColor:[UIColor textColorForStyle:style]
										 border:border];
}

+ (UIImage *)imageWithBackgroundColor:(UIColor *)backgroundColor foregroundColor:(UIColor *)color
{
	return [self.class imageWithBackgroundColor:backgroundColor foregroundColor:color border:0];
}

+ (UIImage *)imageWithBackgroundColor:(UIColor *)backgroundColor foregroundColor:(UIColor *)color border:(CGFloat)border
{
	const CGFloat width = 20.;
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, width), NO, 0.);
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	CGRect frame = CGRectMake(0, 0, width, width);
	CGContextSetFillColorWithColor(context, backgroundColor.CGColor);
	CGContextFillEllipseInRect(context, frame);
	
	if (border > 0) {
		CGRect frame = CGRectMake(border / 2., border / 2., width - border, width - border);
		CGContextSetLineWidth(context, border);
		CGContextSetStrokeColorWithColor(context, backgroundColor.darken.CGColor);
		CGContextStrokeEllipseInRect(context, frame);
	}
	
	frame = CGRectMake(width / 4., width / 4., width / 2., width / 2.);
	CGContextSetFillColorWithColor(context, color.CGColor);
	CGContextFillEllipseInRect(context, frame);
	
	UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

@end

