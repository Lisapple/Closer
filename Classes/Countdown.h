//
//  Countdown.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

@import NotificationCenter;
@import WatchConnectivity;

extern NSString * _Nonnull const CountdownDidSynchronizeNotification;
extern NSString * _Nonnull const CountdownDidUpdateNotification;

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

@interface Countdown : NSObject

@property (nonatomic, strong, nullable)NSString * name;
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

+ (nonnull NSArray <Countdown *> *)allCountdowns;

+ (nullable Countdown *)countdownWithIdentifier:(nonnull NSString *)identifier;

+ (nonnull Countdown *)countdownAtIndex:(NSInteger)index;
+ (NSInteger)indexOfCountdown:(nonnull Countdown *)countdown;

+ (void)insertCountdown:(nonnull Countdown *)countdown atIndex:(NSInteger)index;
+ (void)addCountdown:(nonnull Countdown *)countdown;
+ (void)addCountdowns:(nonnull NSArray <Countdown *> *)countdowns;

+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2; // UNUSED

+ (void)removeCountdown:(nonnull Countdown *)countdown;
+ (void)removeCountdownAtIndex:(NSInteger)index;

/// Returns all CountdownStyles as NSNumber.
+ (nonnull NSArray <NSNumber /* CountdownStyle */ *> *)styles;

/// Return localized name of all styles.
+ (nonnull NSArray <NSString *> *)styleNames;

- (nonnull instancetype)initWithIdentifier:(nullable NSString *)anIdentifier NS_DESIGNATED_INITIALIZER;

// Timer methods

- (nullable NSNumber *)currentDuration;
- (nonnull NSArray <NSNumber *> *)durations;

- (nullable NSString *)currentName;
- (nonnull NSArray <NSString *> *)names; // The number of items must be exactly the same that |durations|, with empty string by default

- (void)addDuration:(nonnull NSNumber *)duration withName:(nullable NSString *)name;
- (void)addDurations:(nonnull NSArray <NSNumber *> *)durations withNames:(nullable NSArray <NSString *> *)names;
- (void)setDuration:(nonnull NSNumber *)duration atIndex:(NSInteger)index;
- (void)setDurationName:(nonnull NSString *)name atIndex:(NSInteger)index;
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
- (void)activate; /* Make the countdown active to send local notification */
- (void)desactivate;

// Localized description methods

- (nonnull NSString *)descriptionOfDurationAtIndex:(NSInteger)index;
- (nonnull NSString *)shortDescriptionOfDurationAtIndex:(NSInteger)index;

@end


@interface Countdown (PrivateMethods)

+ (void)synchronize_async DEPRECATED_ATTRIBUTE;

- (nonnull NSMutableDictionary *)_countdownToDictionary;

@end
