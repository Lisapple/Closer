//
//  Countdown.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NotificationCenter/NotificationCenter.h>
#import <WatchConnectivity/WatchConnectivity.h>

extern NSString * _Nonnull const CountdownDidSynchronizeNotification;
extern NSString * _Nonnull const CountdownDidUpdateNotification;

typedef NS_ENUM(NSUInteger, CountdownType) {
	CountdownTypeCountdown = 0,
	CountdownTypeTimer
};

typedef NS_ENUM(NSUInteger, CountdownStyle) {
	CountdownStyleNight = 0, // Default
	CountdownStyleDay,
	CountdownStyleDawn,
	CountdownStyleOasis,
	CountdownStyleSpring,
};

typedef NS_ENUM(NSUInteger, PromptState) {
	PromptStateNone = 0,
	PromptStateEveryTimers,
	PromptStateEnd
};

@interface Countdown : NSObject

@property (nonatomic, strong) NSString * _Nullable name;
@property (nonatomic, strong) NSDate * _Nullable endDate;
@property (nonatomic, strong) NSString * _Nullable message;
@property (nonatomic, strong) NSString * _Nullable songID;
@property (nonatomic, assign) CountdownStyle style;
@property (nonatomic, assign) CountdownType type;
@property (nonatomic, assign) PromptState promptState;
@property (nonatomic, assign) NSInteger durationIndex;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, assign) BOOL notificationCenter;

// Private
@property (nonatomic, readonly) NSString * _Nonnull identifier;

/* Save any change from propertyList to disk */
+ (void)synchronize; // Calls "synchronizeWithCompletion:" but shows an alert on error
+ (void)synchronizeWithCompletion:(void (^ _Nullable)(BOOL success, NSError * _Nullable error))completionHandler;

+ (NSInteger)numberOfCountdowns;

+ (NSArray <Countdown *> * _Nonnull)allCountdowns;

+ (Countdown * _Nullable)countdownWithIdentifier:(NSString * _Nonnull)identifier;

+ (Countdown * _Nonnull)countdownAtIndex:(NSInteger)index;
+ (NSInteger)indexOfCountdown:(Countdown * _Nonnull)countdown;

+ (void)insertCountdown:(Countdown * _Nonnull)countdown atIndex:(NSInteger)index;
+ (void)addCountdown:(Countdown * _Nonnull)countdown;
+ (void)addCountdowns:(NSArray <Countdown *> * _Nonnull)countdowns;

+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2;

+ (void)removeCountdown:(Countdown * _Nonnull)countdown;
+ (void)removeCountdownAtIndex:(NSInteger)index;

/**
 * Returns an array of NSString with all coundown's style names.
 *
 * @param none
 * @return an array of NSString with the localized name of all styles
 */
+ (NSArray <NSString *> * _Nonnull)styles;

- (instancetype _Nonnull)initWithIdentifier:(NSString * _Nullable)anIdentifier NS_DESIGNATED_INITIALIZER;

#pragma mark Timer methods

- (NSNumber * _Nullable)currentDuration;
- (NSArray <NSNumber *> * _Nonnull)durations;
- (NSArray <NSString *> * _Nonnull)names;
- (void)addDuration:(NSNumber * _Nonnull)duration withName:(NSString * _Nullable)name;
- (void)addDurations:(NSArray * _Nonnull)durations withNames:(NSArray <NSString *> * _Nullable)names;
- (void)setDuration:(NSNumber * _Nonnull)duration atIndex:(NSInteger)index;
- (void)setDurationName:(NSString * _Nonnull)name atIndex:(NSInteger)index;
- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2;
- (void)removeDurationAtIndex:(NSUInteger)index;
- (void)resetDurationIndex;

- (void)resume;
- (void)resumeWithOffset:(NSTimeInterval)offset; // End date = remaining + offset
- (void)pause;
- (void)reset;

#pragma mark Activation methods

- (BOOL)isActive;
- (void)activate; /* Make the countdown active to send local notification */
- (void)desactivate;

#pragma mark Localized description methods

- (NSString * _Nonnull)descriptionOfDurationAtIndex:(NSInteger)index;
- (NSString * _Nonnull)shortDescriptionOfDurationAtIndex:(NSInteger)index;

@end


@interface Countdown (PrivateMethods)

+ (void)synchronize_async DEPRECATED_ATTRIBUTE;

- (NSMutableDictionary * _Nonnull)_countdownToDictionary;

@end