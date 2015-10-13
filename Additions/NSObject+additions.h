//
//  NSObject+addition.h
//  Elsas Gone
//
//  Created by Max on 7/23/14.
//  Copyright (c) 2014 Lisacintosh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

typedef void (^_AnimationBlockUpdateHandler)(float progression);
typedef void (^_AnimationBlockCompletionHandler)(void);

@interface _AnimationBlock /* Private class */ : NSObject

@property (nonatomic, strong) _AnimationBlockUpdateHandler updateBlock;
@property (nonatomic, strong) _AnimationBlockCompletionHandler completionBlock;
@property (nonatomic, assign) NSTimeInterval duration;//, startTimestamp;
@property (nonatomic, assign) float progression;
@property (nonatomic, readonly) BOOL isCancelled;
@property (nonatomic, readonly) NSUInteger identifier;
@property (nonatomic, assign) BOOL repeats;

- (instancetype)initWithIdentifier:(NSUInteger)identifier NS_DESIGNATED_INITIALIZER;
- (void)cancel;

@end


@interface _AnimationHelper /* Private class */ : NSObject

@property (nonatomic, assign) float slowdownFactor;

- (void)startUpdating;
- (void)stopUpdating;

- (BOOL)cancelAnimationBlockWithIdentifier:(NSUInteger)identifier;

@end


@interface NSObject (addition)

+ (float)setSlowdownFactor:(float)factor; // animation duration = factor * real duration; 1 for normal factor; return the last factor (or the current one if factor <= 0

+ (BOOL)cancelAnimationWithIdentifier:(NSUInteger)identifier; // Returns YES on success (block with this identifier existing)
+ (NSUInteger)animateWithDuration:(NSTimeInterval)duration animations:(void(^)(float progression))block;
+ (NSUInteger)animateWithDuration:(NSTimeInterval)duration animations:(void(^)(float progression))block completion:(void(^)(void))completion;

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration DEPRECATED_ATTRIBUTE;
+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration completion:(void(^)(void))completion DEPRECATED_ATTRIBUTE;

/*
 + (void)stopAnimationBlockWithIdentifier:(NSUInteger)identifier;
 + (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration withIdentifier:(NSUInteger)identifier;
 + (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration completion:(void(^)(void))completion withIdentifier:(NSUInteger)identifier;
 */

+ (BOOL)cancelPerformBlockWithIdentifier:(NSUInteger)identifier; // Returns YES on success (block with this identifier existing)
+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay;
+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay repeats:(BOOL)repeats;
// Returns a new identifier if the one given is already used
+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay identifier:(NSUInteger)identifier;
+ (NSUInteger)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay repeats:(BOOL)repeats identifier:(NSUInteger)identifier;

@end
