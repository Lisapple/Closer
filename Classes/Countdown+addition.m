//
//  Countdown+Countdown_addition.m
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Countdown+addition.h"
#import "NSBundle+addition.h"

@implementation Countdown (LocalNotification)

+ (void)removeInvalidLocalNotifications
{
	NSArray * allLocalNotifications = [UIApplication sharedApplication].scheduledLocalNotifications;
	for (UILocalNotification * localNotif in allLocalNotifications) {
		NSString * anIdentifier = localNotif.userInfo[@"identifier"];
		Countdown * countdown = [Countdown countdownWithIdentifier:anIdentifier];
		if (!countdown || ![countdown.endDate isEqualToDate:localNotif.fireDate]) {
			[[UIApplication sharedApplication] cancelLocalNotification:localNotif];
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
    NSDebugLog(@"Create new local notification for countdown : %@ => %@", self.name, [endDate description]);
    UILocalNotification * localNotif = [[UILocalNotification alloc] init];
    
    localNotif.timeZone = [NSTimeZone localTimeZone];
    localNotif.userInfo = @{ @"identifier": self.identifier };
    
    return localNotif;
}

- (void)updateLocalNotification
{
    if (active) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (endDate && endDate.timeIntervalSinceNow > 0.) {
                
                UILocalNotification * localNotif = [self localNotification];
                if (localNotif) {
                    [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
                } else {
                    localNotif = [self createLocalNotification];
                }
                
                localNotif.fireDate = self.endDate;
                
                NSString * messageString = message;
                if (!message || [message isEqualToString:@""]) {// If no message, show the default message
                    if (self.type == CountdownTypeTimer) {
                        if (name)// If name was set, add it to default message
                            messageString = [NSString stringWithFormat:NSLocalizedString(@"TIMER_FINISHED_MESSAGE %@", nil), self.name];
                        else // Else if wasn't set, just show the default message
                            messageString = NSLocalizedString(@"TIMER_FINISHED_DEFAULT_MESSAGE", nil);
                    } else {
                        if (name) messageString = [NSString stringWithFormat:NSLocalizedString(@"COUNTDOWN_FINISHED_MESSAGE %@", nil), self.name];
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
                
                NSDebugLog(@"updateLocalNotification: (%@ %@)", localNotif.fireDate, localNotif.alertBody);
                
                [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
            } else {
                /* Remove the notification */
                UILocalNotification * localNotif = [self localNotification];
                if (localNotif) {
                    [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
                }
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
    if (localNotif)
        [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
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
