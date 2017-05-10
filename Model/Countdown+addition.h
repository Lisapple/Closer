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
@import UserNotifications;

NS_ASSUME_NONNULL_BEGIN

@interface Countdown (LocalNotification)

+ (void)removeInvalidLocalNotifications;

IGNORE_DEPRECATION_BEGIN
- (nullable UILocalNotification *)localNotification;
- (UILocalNotification *)createLocalNotification;
IGNORE_DEPRECATION_END
- (void)updateLocalNotification;
- (void)removeLocalNotification;

- (void)presentLocalNotification;

@end


@interface Countdown (Event)

+ (Countdown *)countdownWithEvent:(EKEvent *)event;

@end


@interface Countdown (Spotlight)

+ (void)updateSpotlightIndexWithCompletionHandler:(void (^ __nullable)(NSError * __nullable error))completionHandler;

@end


@interface Countdown (Name)

@property (nonatomic, readonly) NSAttributedString * attributedName;

+ (NSString *)proposedNameForType:(CountdownType)type;

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


@interface Countdown (Thumbnail)

+ (UIImage *)thumbnailForStyle:(CountdownStyle)style;

@end

NS_ASSUME_NONNULL_END
