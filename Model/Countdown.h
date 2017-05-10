//
//  Countdown.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@import NotificationCenter;
@import WatchConnectivity;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CountdownDidSynchronizeNotification;
extern NSString * const CountdownDidUpdateNotification;

extern NSString * const CountdownDidCreateNotification; // object is Countdown
extern NSString * const CountdownDidMoveNotification; // object is Countdown, userInfo contains "oldIndex"
extern NSString * const CountdownDidDeleteNotification; // object is countdown identifier

typedef NS_ENUM(NSUInteger, CountdownType) {
	CountdownTypeCountdown = 0,
	CountdownTypeTimer
};

typedef NS_ENUM(NSUInteger, CountdownStyle) {
	//*** Do not change integer value (used as it when saving countdowns)
	
	CountdownStyleNight = 0, // Default
	CountdownStyleDay,
	CountdownStyleDawn,
	CountdownStyleOasis,
	CountdownStyleSpring,
};

extern NSString * _Nullable CountdownStyleDescription(CountdownStyle style);

extern BOOL CountdownStyleHasDarkContent(CountdownStyle style);

typedef NS_ENUM(NSUInteger, PromptState) {
	PromptStateNone = 0,
	PromptStateEveryTimers,
	PromptStateEnd
};

extern NSString * const CountdownDefaultSoundName;

@interface Countdown : NSObject

@property (nonatomic, strong, nullable) NSString * name; // @TODO: Should not be nullable
@property (nonatomic, strong, nullable) NSDate * endDate;
@property (nonatomic, strong, nullable) NSString * message;
@property (nonatomic, strong, nullable) NSString * songID;
@property (nonatomic, assign) CountdownStyle style;
@property (nonatomic, assign) CountdownType type;
@property (nonatomic, assign) PromptState promptState;
@property (nonatomic, assign) NSInteger durationIndex;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, assign) BOOL notificationCenter;

// Private
@property (nonatomic, readonly, nonnull) NSString * identifier;

/* Save any change from propertyList to disk */
+ (void)synchronize; // Calls "synchronizeWithCompletion:" but shows an alert on error
+ (void)synchronizeWithCompletion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completionHandler;

+ (NSInteger)numberOfCountdowns;

+ (NSArray <Countdown *> *)allCountdowns;

+ (nullable Countdown *)countdownWithIdentifier:(NSString *)identifier;

+ (Countdown *)countdownAtIndex:(NSInteger)index;
+ (NSInteger)indexOfCountdown:(Countdown *)countdown;

+ (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index;
+ (void)addCountdown:(Countdown *)countdown;
+ (void)addCountdowns:(NSArray <Countdown *> *)countdowns;

/// Move the countdown at `fromIndex` (throw an exception is out of bounds) to `toIndex` (clipped to bounds).
+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2 UNAVAILABLE_ATTRIBUTE;

+ (void)removeCountdown:(Countdown *)countdown;
+ (void)removeCountdownAtIndex:(NSInteger)index;

/// Returns all CountdownStyles as NSNumber.
+ (NSArray <NSNumber /* CountdownStyle */ *> *)styles;

/// Return localized name of all styles.
+ (NSArray <NSString *> *)styleNames;

- (instancetype)initWithIdentifier:(nullable NSString *)anIdentifier NS_DESIGNATED_INITIALIZER;

// Timer methods

- (nullable NSNumber *)currentDuration;
- (NSArray <NSNumber *> *)durations;

- (nullable NSString *)currentName;
- (NSArray <NSString *> *)names; // The number of items must be exactly the same that |durations|, with empty string by default

- (void)addDuration:(NSNumber *)duration withName:(nullable NSString *)name;
- (void)addDurations:(NSArray <NSNumber *> *)durations withNames:(nullable NSArray <NSString *> *)names;
- (void)setDuration:(NSNumber *)duration atIndex:(NSInteger)index;
- (void)setDurationName:(NSString *)name atIndex:(NSInteger)index;
- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2; // UNUSED
- (void)removeDurationAtIndex:(NSUInteger)index;
- (void)resetDurationIndex;

- (void)resume;
- (void)resumeWithOffset:(NSTimeInterval)offset; // End date = remaining + offset
- (void)pause;
- (void)reset;

// Activation methods

- (BOOL)isActive;
/// Make the countdown active to send local notification
- (void)activate;
- (void)desactivate;

// Localized description methods

- (NSString *)descriptionOfDurationAtIndex:(NSInteger)index;
- (NSString *)shortDescriptionOfDurationAtIndex:(NSInteger)index;

@end


@interface Countdown (PrivateMethods)

+ (void)synchronize_async DEPRECATED_ATTRIBUTE;

- (NSMutableDictionary *)_countdownToDictionary;

@end

NS_ASSUME_NONNULL_END
