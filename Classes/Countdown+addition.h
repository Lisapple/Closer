//
//  Countdown+Countdown_addition.h
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Countdown.h"
#import <EventKit/EventKit.h>
#import <CoreSpotlight/CoreSpotlight.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface Countdown (LocalNotification)

+ (void)removeInvalidLocalNotifications;

- (nullable UILocalNotification *)localNotification;
- (nonnull UILocalNotification *)createLocalNotification;
- (void)updateLocalNotification;
- (void)removeLocalNotification;

@end


@interface Countdown (Event)

+ (nonnull Countdown *)countdownWithEvent:(nonnull EKEvent *)event;

@end


@interface Countdown (Spotlight)

+ (void)buildingSpolightIndexWithCompletionHandler:(void (^ __nullable)(NSError * __nullable error))completionHandler;

@end