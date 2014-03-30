//
//  Countdown.h
//  Closer
//
//  Created by Max on 2/13/11.
//  Copyright 2011 Lis@cintosh. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	CountdownTypeDefault = 0,
	CountdownTypeTimer
} CountdownType;

typedef enum {
	PromptStateNone = 0,
	PromptStateEveryTimers,
	PromptStateEnd
} PromptState;

@interface Countdown : NSObject
{
	NSString * name;
	NSDate * endDate;
	NSString * message;
	NSString * songID;
	NSInteger style;
	CountdownType type;
	PromptState promptState;
	NSInteger durationIndex;
	
	@private
	NSString * identifier;
	NSMutableArray * durations;
	BOOL active;
}

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) NSString * message;
@property (nonatomic, strong) NSString * songID;
@property (nonatomic, assign) NSInteger style;
@property (nonatomic, assign) CountdownType type;
@property (nonatomic, assign) PromptState promptState;
@property (nonatomic, assign) NSInteger durationIndex;

// Private
@property (nonatomic, readonly) NSString * identifier;

/* Save any change from propertyList to disk */
+ (void)synchronize;

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

- (id)initWithIdentifier:(NSString *)anIdentifier;

- (NSNumber *)currentDuration;
- (NSArray *)durations;
- (void)addDuration:(NSNumber *)duration;
- (void)addDurations:(NSArray *)durations;
- (void)setDuration:(NSNumber *)duration atIndex:(NSInteger)index;
- (void)moveDurationAtIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;
- (void)exchangeDurationAtIndex:(NSInteger)index1 withDurationAtIndex:(NSInteger)index2;
- (void)removeDurationAtIndex:(NSUInteger)index;

- (void)activate; /* Make the countdown active to send local notification */
- (void)desactivate;

- (NSString *)descriptionOfDurationAtIndex:(NSInteger)index;
- (NSString *)shortDescriptionOfDurationAtIndex:(NSInteger)index;

- (void)resetDurationIndex;

- (void)removeLocalNotification;

@end


@interface Countdown (PrivateMethods)

+ (void)synchronize_async;

- (NSMutableDictionary *)_countdownToDictionary;

- (UILocalNotification *)localNotification;
- (UILocalNotification *)createLocalNotification;
- (void)updateLocalNotification;
@end