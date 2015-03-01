//
//  Countdown+Countdown_addition.h
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

#import "Countdown.h"
#import <EventKit/EventKit.h>

@interface Countdown (LocalNotification)

- (UILocalNotification *)localNotification;
- (UILocalNotification *)createLocalNotification;
- (void)updateLocalNotification;
- (void)removeLocalNotification;

@end

@interface Countdown (Event)

+ (Countdown *)countdownWithEvent:(EKEvent *)event;

@end
