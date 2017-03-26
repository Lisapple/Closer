//
//  Countdown+Countdown_addition.m
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Countdown+addition.h"
#import "NSBundle+addition.h"
#import "NSDate+addition.h"
#import "NSMutableAttributedString+addition.h"

@implementation Countdown (LocalNotification)

+ (void)removeInvalidLocalNotifications
{
	NSArray * allLocalNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
	for (UILocalNotification * localNotif in allLocalNotifications) {
		NSString * anIdentifier = localNotif.userInfo[@"identifier"];
		Countdown * countdown = [Countdown countdownWithIdentifier:anIdentifier];
		if (!countdown || ![countdown.endDate isEqualToDate:localNotif.fireDate]) {
			[[UIApplication sharedApplication] cancelLocalNotification:localNotif];
			NSDebugLog(@"Remove local notification: name = %@, endDate = %@", countdown.name, localNotif.fireDate);
		}
	}
}

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
	return notification;
}

- (void)updateLocalNotification
{
	if (self.isActive) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (self.endDate && self.endDate.timeIntervalSinceNow > 0.) {
				
				UILocalNotification * notification = [self localNotification];
				if (notification)
					[self removeLocalNotification];
				else
					notification = [self createLocalNotification];
				
				notification.fireDate = self.endDate;
				
				NSString * messageString = self.message;
				if (!self.message || [self.message isEqualToString:@""]) {// If no message, show the default message
					if (self.type == CountdownTypeTimer) {
						if (self.name)// If name was set, add it to default message
							messageString = [NSString stringWithFormat:NSLocalizedString(@"TIMER_FINISHED_MESSAGE %@", nil), self.name];
						else // Else if wasn't set, just show the default message
							messageString = NSLocalizedString(@"TIMER_FINISHED_DEFAULT_MESSAGE", nil);
					} else {
						if (self.name) messageString = [NSString stringWithFormat:NSLocalizedString(@"COUNTDOWN_FINISHED_MESSAGE %@", nil), self.name];
						else messageString = NSLocalizedString(@"COUNTDOWN_FINISHED_DEFAULT_MESSAGE", nil);
					}
				}
				notification.alertBody = messageString;
				
				notification.repeatInterval = 0;
				notification.hasAction = YES;
				
				if ([self.songID isEqualToString:@"-1"]) { // Don't play any sound ("-1" means "none")
					
				} else if ([self.songID isEqualToString:@"default"]) { // Play default sound
					notification.soundName = UILocalNotificationDefaultSoundName;
					
				} else { // Play other sound from Songs folder
					NSString * songPath = [NSString stringWithFormat:@"Songs/%@", [[NSBundle mainBundle] filenameForSongWithID:self.songID]];
					notification.soundName = songPath;
				}
				
				/* localNotif.userInfo => don't change userInfo, it alrealdy contains identifier */
				
				NSDebugLog(@"Update local notification: (%@ %@)", notification.fireDate, notification.alertBody);
				
				[[UIApplication sharedApplication] scheduleLocalNotification:notification];
			} else {
				[self removeLocalNotification];
			}
			
			// Send a notification from the countdown/timer
			[[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidUpdateNotification
																object:self];
		});
	}
}

- (void)removeLocalNotification
{
	UILocalNotification * notification = [self localNotification];
	if (notification) {
		[[UIApplication sharedApplication] cancelLocalNotification:notification];
		NSDebugLog(@"Cancel local notification for countdown : %@ => %@", self.name, self.endDate.localizedDescription);
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

+ (void)buildingSpolightIndexWithCompletionHandler:(void (^)(NSError * error))completionHandler
{
	if (NSClassFromString(@"CSSearchableIndex")) {
		dispatch_async(dispatch_get_main_queue(), ^{
			NSMutableArray <CSSearchableItem *> * searchableItems = [[NSMutableArray alloc] initWithCapacity:self.allCountdowns.count];
			for (Countdown * countdown in self.allCountdowns) {
				if (countdown.type == CountdownTypeCountdown) {
					CSSearchableItemAttributeSet * attributeSet = [[CSSearchableItemAttributeSet alloc] initWithItemContentType:(NSString *)kUTTypeItem];
					attributeSet.title = countdown.name;
					if (countdown.endDate)
						attributeSet.contentDescription = [NSString stringWithFormat:@"%@ - %@", countdown.endDate.naturalDateString, countdown.message];
					else
						attributeSet.contentDescription = countdown.message;
					
					attributeSet.relatedUniqueIdentifier = countdown.identifier;
					
					attributeSet.keywords = @[ countdown.name, countdown.message ];
					CSSearchableItem * item = [[CSSearchableItem alloc] initWithUniqueIdentifier:countdown.identifier
																				domainIdentifier:@"countdown"
																					attributeSet:attributeSet];
					[searchableItems addObject:item];
					
					NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.lisacintosh.closer.show-countdown"];
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
	[Answers logCustomEventWithName:@"insert-countdown"
				   customAttributes:nil];
}

+ (void)tagChangeType:(CountdownType)type
{
	[Answers logCustomEventWithName:@"change-countdown-type"
				   customAttributes:@{ @"new type" : (type == CountdownTypeTimer) ? @"timer" : @"countdown" }];
}

+ (void)tagChangeName
{
	[Answers logCustomEventWithName:@"change-countdown-name"
				   customAttributes:nil];
}

+ (void)tagChangeMessage
{
	[Answers logCustomEventWithName:@"change-countdown-message"
				   customAttributes:nil];
}

+ (void)tagEndDate:(NSDate *)date
{
	NSDictionary * attrs = nil;
	if (date.localizedDescription) {
		attrs = @{ @"end date" : date.localizedDescription };
	}
	[Answers logCustomEventWithName:@"change-countdown-end-date"
				   customAttributes:attrs];
}

+ (void)tagChangeDuration
{
	[Answers logCustomEventWithName:@"change-countdown-duration"
				   customAttributes:@{ }];
}

+ (void)tagChangeTheme:(CountdownStyle)style
{
	[Answers logCustomEventWithName:@"change-countdown-theme"
				   customAttributes:@{ @"theme" : CountdownStyleDescription(style) }];
}

+ (void)tagDelete
{
	[Answers logCustomEventWithName:@"delete-countdown"
				   customAttributes:nil];
}

@end


@implementation Countdown (Thumbnail)

+ (UIImage *)thumbnailForStyle:(CountdownStyle)style
{
	if (CountdownStyleIsDynamic(style)) {
		return [self.class imageWithBackgroundColor:[UIColor backgroundColorForStyle:style]
									foregroundColor:[UIColor textColorForStyle:style]];
	} else {
		const CGFloat border = (style == CountdownStyleDay) ? 1 : 0;
		return [self.class imageWithBackgroundColor:[UIColor backgroundColorForStyle:style]
									foregroundColor:[UIColor textColorForStyle:style]
											 border:border];
	}
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

