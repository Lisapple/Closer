//
//  NSObject+additions.m
//  Closer
//
//  Created by Max on 23/11/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSObject+additions.h"

@implementation _AnimationBlock

@end

@interface _AnimationHelper ()
{
	CADisplayLink * _link;
	NSMutableArray * _animationBlocks;
}
@end

@implementation _AnimationHelper

+ (_AnimationHelper *)defaultHelper
{
	static _AnimationHelper * helper = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		helper = [[_AnimationHelper alloc] init];
	});
	return helper;
}

- (id)init
{
	if ((self = [super init])) {
		_link = [[UIScreen mainScreen] displayLinkWithTarget:self
													selector:@selector(updateScreen:)];
		[_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
		_link.frameInterval = 3.;
		_link.paused = YES;
		_animationBlocks = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return self;
}

- (void)addAnimationWithUpdateBlock:(_AnimationBlockUpdateHandler)updateHandler
						   duration:(NSTimeInterval)duration
						 completion:(_AnimationBlockCompletionHandler)completion
{
	_AnimationBlock * block = [[_AnimationBlock alloc] init];
	block.updateBlock = updateHandler;
	block.duration = duration;
	block.completionBlock = completion;
	block.startTimestamp = 0.;
	[_animationBlocks addObject:block];
	
	if (_animationBlocks.count > 0)
		[self startUpdating];
}

- (void)updateScreen:(CADisplayLink *)sender
{
	for (_AnimationBlock * block in _animationBlocks.mutableCopy) {
		if (block.startTimestamp == 0.)
			block.startTimestamp = _link.timestamp;
		float progression = (_link.timestamp - block.startTimestamp) / block.duration;
		block.updateBlock(MIN(progression, 1.));
		if (progression >= 1.) {
			if (block.completionBlock)
				block.completionBlock();
			[_animationBlocks removeObject:block];
		}
	}
	
	if (_animationBlocks.count == 0)
		[self stopUpdating];
}

- (void)startUpdating
{
	_link.paused = NO;
}

- (void)stopUpdating
{
	_link.paused = YES;
}

@end


@implementation NSObject (addition)

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration
{
	[self animationBlock:block duration:duration completion:NULL];
}

+ (void)animationBlock:(void(^)(float progression))block duration:(NSTimeInterval)duration completion:(void(^)(void))completion
{
	if (duration <= 0.)
		return ;
	[[_AnimationHelper defaultHelper] addAnimationWithUpdateBlock:block duration:duration completion:completion];
}

+ (void)performBlock:(void(^)(void))block afterDelay:(NSTimeInterval)delay
{
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end

