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

#import <Crashlytics/Crashlytics.h>

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
    NSArray * allLocalNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
    for (UILocalNotification * localNotif in allLocalNotifications) {
        
        NSString * anIdentifier = localNotif.userInfo[@"identifier"];
        if ([anIdentifier isEqualToString:self.identifier]) {
            return localNotif; // Return the localNotification
        }
    }
    
    return nil;
}

- (UILocalNotification *)createLocalNotification
{
    NSDebugLog(@"Create new local notification for countdown : %@ => %@", self.name, [self.endDate description]);
    UILocalNotification * localNotif = [[UILocalNotification alloc] init];
    
    localNotif.timeZone = [NSTimeZone localTimeZone];
    localNotif.userInfo = @{ @"identifier": self.identifier };
    
    return localNotif;
}

- (void)updateLocalNotification
{
    if (self.isActive) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.endDate && self.endDate.timeIntervalSinceNow > 0.) {
                
                UILocalNotification * localNotif = [self localNotification];
                if (localNotif) {
					[self removeLocalNotification];
                } else {
                    localNotif = [self createLocalNotification];
                }
                
                localNotif.fireDate = self.endDate;
                
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
                localNotif.alertBody = messageString;
                
                localNotif.repeatInterval = 0;
                localNotif.hasAction = YES;
                
                if ([self.songID isEqualToString:@"-1"]) {// Don't play any sound ("-1" means "none")
                    
                } else if ([self.songID isEqualToString:@"default"]) {// Play default sound
                    localNotif.soundName = UILocalNotificationDefaultSoundName;
                    
                } else {// Play other sound from Songs folder
                    NSString * songPath = [NSString stringWithFormat:@"Songs/%@", [[NSBundle mainBundle] filenameForSongWithID:self.songID]];
                    localNotif.soundName = songPath;
                }
                
                /* localNotif.userInfo => don't change userInfo, it alrealdy contains identifier */
                
                NSDebugLog(@"Update local notification: (%@ %@)", localNotif.fireDate, localNotif.alertBody);
                
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
            } else {
				[self removeLocalNotification];
            }
            
            /* Send a notification from the countdown/timer */
            [[NSNotificationCenter defaultCenter] postNotificationName:CountdownDidUpdateNotification
                                                                object:self];
        });
    }
}

- (void)removeLocalNotification
{
    UILocalNotification * localNotif = [self localNotification];
	if (localNotif) {
        [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
		NSDebugLog(@"Cancel local notification for countdown : %@ => %@", self.name, [self.endDate description]);
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
					if (countdown.endDate) {
						attributeSet.contentDescription = [NSString stringWithFormat:@"%@ - %@", countdown.endDate.naturalDateString, countdown.message];
					} else {
						attributeSet.contentDescription = countdown.message;
					}
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


@implementation Countdown (Answers)

+ (void)tagInsert
{
	[Answers logCustomEventWithName:@"insert-countdown"
				   customAttributes:nil];
}

+ (void)tagDelete
{
	[Answers logCustomEventWithName:@"delete-countdown"
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
	if ([date description]) {
		attrs = @{ @"end date" : [date description] };
	}
	[Answers logCustomEventWithName:@"change-countdown-end-date"
				   customAttributes:attrs];
}

+ (void)tagChangeDuration
{
	[Answers logCustomEventWithName:@"change-countdown-duration"
				   customAttributes:@{}];
}

+ (void)tagChangeTheme:(CountdownStyle)style
{
	[Answers logCustomEventWithName:@"change-countdown-theme"
				   customAttributes:@{ @"theme" : [Countdown styles][style] }];
}

@end
