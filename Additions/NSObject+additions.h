//
//  NSObject+additions.h
//  Closer
//
//  Created by Max on 23/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#define CLAMP(A, B, T) ( A + (B - A) * T )

typedef void (^_AnimationBlockUpdateHandler)(float progression);
typedef void (^_AnimationBlockCompletionHandler)(void);

@interface _AnimationBlock /* Private class */ : NSObject

@property (nonatomic, strong) _AnimationBlockUpdateHandler updateBlock;
@property (nonatomic, strong) _AnimationBlockCompletionHandler completionBlock;
@property (nonatomic, assign) NSTimeInterval duration, startTimestamp;

@end


@interface _AnimationHelper /* Private class */ : NSObject

- (void)startUpdating;
- (void)stopUpdating;

@end


@interface NSObject (addition)

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration;
+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration completion:(void(^)(void))completion;
+ (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay;

@end
