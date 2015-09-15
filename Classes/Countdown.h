//
//  Countdown.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <NotificationCenter/NotificationCenter.h>

extern NSString * const CountdownDidSynchronizeNotification;
extern NSString * const CountdownDidUpdateNotification;

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
{
	NSString * name;
	NSDate * endDate;
	NSString * message;
	NSString * songID;
	
	@private
	NSString * identifier;
	NSMutableArray * durations;
	NSTimeInterval remaining;
	BOOL active;
}

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) NSString * message;
@property (nonatomic, strong) NSString * songID;
@property (nonatomic, assign) CountdownStyle style;
@property (nonatomic, assign) CountdownType type;
@property (nonatomic, assign) PromptState promptState;
@property (nonatomic, assign) NSInteger durationIndex;
@property (nonatomic, readonly, getter=isPaused) BOOL paused;
@property (nonatomic, assign) BOOL notificationCenter;

// Private
@property (nonatomic, readonly) NSString * identifier;

/* Save any change from propertyList to disk */
+ (void)synchronize; // Calls "synchronizeWithCompletion:" but shows an alert on error
+ (void)synchronizeWithCompletion:(void (^)(BOOL success, NSError * error))completionHandler;

+ (NSInteger)numberOfCountdowns;

+ (NSArray *)allCountdowns;

+ (Countdown *)countdownWithIdentifier:(NSString *)identifier;

+ (Countdown *)countdownAtIndex:(NSInteger)index;
+ (NSInteger)indexOfCountdown:(Countdown *)countdown;

+ (void)insertCountdown:(Countdown *)countdown atIndex:(NSInteger)index;
+ (void)addCountdown:(Countdown *)countdown;
+ (void)addCountdowns:(NSArray *)countdowns;

+ (void)moveCountdownAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
+ (void)exchangeCountdownAtIndex:(NSInteger)index1 withCountdownAtIndex:(NSInteger)index2;

+ (void)removeCountdown:(Countdown *)countdown;
+ (void)removeCountdownAtIndex:(NSInteger)index;

/**
 * Returns an array of NSString with all coundown's style names.
 *
 * @param none
 * @return an array of NSString with the localized name of all styles
 */
+ (NSArray *)styles;

- (instancetype)initWithIdentifier:(NSString *)anIdentifier NS_DESIGNATED_INITIALIZER;

#pragma mark Timer methods

- (NSNumber *)currentDuration;
- (NSArray *)durations;
- (void)addDuration:(NSNumber *)duration;
- (void)addDurations:(NSArray *)durations;
- (void)setDuration:(NSNumber *)duration atIndex:(NSInteger)index;
- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2;
- (void)removeDurationAtIndex:(NSUInteger)index;
- (void)resetDurationIndex;
- (void)resume;
- (void)pause;
- (void)reset;

#pragma mark Activation methods

- (void)activate; /* Make the countdown active to send local notification */
- (void)desactivate;

#pragma mark Localized description methods

- (NSString *)descriptionOfDurationAtIndex:(NSInteger)index;
- (NSString *)shortDescriptionOfDurationAtIndex:(NSInteger)index;

@end


@interface Countdown (PrivateMethods)

+ (void)synchronize_async DEPRECATED_ATTRIBUTE;

- (NSMutableDictionary *)_countdownToDictionary;

@end