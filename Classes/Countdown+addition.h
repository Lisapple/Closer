//
//  Countdown+Countdown_addition.h
//  Closer
//
//  Created by Max on 10/03/12.
//  Copyright (c) 2012 Lis@cintosh. All rights reserved.
//

@import EventKit;
@import CoreSpotlight;
@import MobileCoreServices;
@import Crashlytics;

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


@interface Countdown (Name)

@property (nonatomic, readonly, nonnull) NSAttributedString * attributedName;

+ (nonnull NSString *)proposedNameForType:(CountdownType)type;

@end


@interface Countdown (Answers)

+ (void)tagInsert;

+ (void)tagChangeType:(CountdownType)type;
+ (void)tagChangeName;
+ (void)tagChangeMessage;
+ (void)tagEndDate:(nullable NSDate *)date;
+ (void)tagChangeDuration;
+ (void)tagChangeTheme:(CountdownStyle)style;

+ (void)tagDelete;

@end
